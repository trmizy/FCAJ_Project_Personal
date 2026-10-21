---
title: "5.4 Deployment Guide"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.4. </b> "
---

The services were deployed one at a time, in dependency order: each service only goes live after every service it calls is already running. The pages below follow that order and keep the screenshots captured during the real deployment.

1. [5.4.1 Shared network infrastructure](5.4.1-Shared-Network/) — Internet Gateway, public subnets, NAT Gateway and route tables.
2. [5.4.2 Auth Service and API Gateway](5.4.2-Auth-Service-API-Gateway/) — the first Lambda, the HTTP API and its explicit public routes.
3. [5.4.3 Frontend on Amazon S3](5.4.3-Frontend-S3/) — static website hosting and the redeploy procedure.
4. [5.4.4 User Service](5.4.4-User-Service/) — Lambda-to-Lambda calls, private S3 uploads and the first scheduled jobs.
5. [5.4.5 Fitness Service](5.4.5-Fitness-Service/) — migration from an S3 artifact and two reminder schedules.
6. [5.4.6 Gym Service](5.4.6-Gym-Service/) — QR check-in secret and payout/referral jobs.
7. [5.4.7 Payment Service](5.4.7-Payment-Service/) — VNPAY configuration, reconciliation and the Gym ↔ Payment wiring.
8. [5.4.8 AI Service — database, queue and Bedrock](5.4.8-AI-Service-Core/) — HTTP Lambda, SQS worker and jobs Lambda on Nova Pro / Cohere.
9. [5.4.9 AI Service — vector search, scheduling and API](5.4.9-AI-Service-Vector-Search/) — OpenSearch Serverless, knowledge ingestion, routes and rate limits.
10. [5.4.10 Chat Service on ECS Fargate](5.4.10-Chat-Service-ECS/) — container image, task definition, ALB and Socket.IO.
11. [5.4.11 Data migration to Aurora](5.4.11-Data-Migration/) — restoring 7 local databases with a one-shot Fargate task.
12. [5.4.12 CI/CD pipeline activation](5.4.12-CICD-Pipeline/) — GitHub Actions PR validation via OIDC, and real OIDC → STS federation evidence.
13. [5.4.13 CD pipeline activation](5.4.13-CD-Pipeline-Activation/) — gate-by-gate activation of the actual deploy-to-AWS workflows, starting with the GitHub Environment human-approval gates.

#### The pattern every Lambda-based service follows {#common-pattern}

Once the shared network exists, each service (Auth, User, Fitness, Gym, Payment, AI) is deployed with the same sequence. The service pages only call out what differs.

| # | Step | Detail |
|---|---|---|
| 1 | Database secret | Secrets Manager → *Other type of secret* with `username`, `password`, `host`, `port`, `database = fitness_assistant_<service>`, named `fitness-assistant/dev/<service>-database`. Rotation off for DEV. |
| 2 | Migration role | IAM role trusted by Lambda with `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole`, plus an inline policy allowing `secretsmanager:GetSecretValue` on **only** that service's secret ARN. |
| 3 | Migration Lambda | `fitness-assistant-dev-<service>-migrate`, Node.js 22.x, x86_64, 1024 MB, handler `dist/migrate-lambda.handler`, env `DATABASE_SECRET_ID`, attached to both private app subnets and `fitness-assistant-dev-lambda-sg`. Invoked once with `{}`: it creates the logical database if missing and runs `prisma migrate deploy`, refusing to run against any other database name. |
| 4 | Runtime role | Same two managed policies, plus inline policies for the service's own secret and `lambda:InvokeFunction` on the exact functions it calls. |
| 5 | HTTP Lambda | `fitness-assistant-dev-<service>`, 1024 MB, 30 s timeout, handler `dist/lambda.handler`, same VPC settings. |
| 6 | API Gateway | Lambda integration (payload format 2.0) and explicit route prefixes. `/internal/*` and `ANY /{proxy+}` are **never** created. |
| 7 | Jobs Lambda | `fitness-assistant-dev-<service>-jobs`, same ZIP, handler `dist/jobs-lambda.handler`, 1 minute timeout. |
| 8 | Scheduler | A dedicated role trusted by `scheduler.amazonaws.com` that can only invoke that jobs Lambda, and one EventBridge schedule per job with a `{"job": "<name>"}` payload. |

{{% notice info %}}
All screenshots on these pages come from the deployment runbook. Screens that originally showed a secret value (database master password, `INTERNAL_SERVICE_SECRET`, `CHECKIN_TOKEN_SECRET`) were redacted at pixel level before being included — the black boxes are intentional.
{{% /notice %}}
