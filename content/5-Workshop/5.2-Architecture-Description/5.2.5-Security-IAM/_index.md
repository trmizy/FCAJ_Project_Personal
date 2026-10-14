---
title: "5.2.5 Security and IAM"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.2.5. </b> "
---

### Network isolation

- Lambda functions and the Chat Fargate task run only in the two private application subnets; the only resources in public subnets are the NAT Gateway and the internet-facing Chat ALB.
- Aurora sits in private DB subnets whose route table has **no** NAT or internet route, so the database tier can neither reach nor be reached from the internet.
- Security groups reference each other instead of IP ranges:

| Security group | Inbound |
|---|---|
| `fitness-assistant-dev-aurora-sg` | 5432 from `lambda-sg` and from `chat-sg` only |
| `fitness-assistant-dev-chat-sg` | 3005 from `chat-alb-sg` only |
| `fitness-assistant-dev-chat-alb-sg` | 80 from the internet (DEV, HTTP) |
| `fitness-assistant-dev-vpce-sg` | 443 from `lambda-sg` (Secrets Manager and OpenSearch endpoints) |
| `fitness-assistant-dev-lambda-sg` | none |

- OpenSearch Serverless is reachable only through its VPC endpoint (public access disabled).
- The Chat ALB answers `/internal/*` and `/metrics` with a fixed 404, and API Gateway has no `/internal/*`, `/metrics` or catch-all route, so service-to-service endpoints are not reachable from the internet at all.

### IAM — least privilege per function

Every function and task has its own role. Lambda roles start from `AWSLambdaBasicExecutionRole` (logs) and `AWSLambdaVPCAccessExecutionRole` (VPC networking) and add inline policies that name exact resources:

| Need | How it is scoped |
|---|---|
| Database credentials | `secretsmanager:GetSecretValue` on that service's own secret ARN only |
| Calling another service | `lambda:InvokeFunction` on the exact target function ARNs (e.g. Payment → Auth, User, Gym, AI), never `lambda:*` |
| Private uploads | `s3:PutObject/GetObject/DeleteObject` on three prefixes of the uploads bucket only (`profile-photos/`, `pt-applications/`, `contracts/`), no `s3:ListBucket` |
| AI queue | HTTP Lambda: `sqs:SendMessage`; Worker: `ReceiveMessage`, `DeleteMessage`, `GetQueueAttributes` — on the one queue |
| Bedrock | `bedrock:InvokeModel` on the APAC Nova Pro inference profile, on the Nova Pro foundation model **only when called through that profile** (IAM condition), and on Cohere Embed Multilingual v3 — no `AmazonBedrockFullAccess`, no streaming permission |
| OpenSearch | `aoss:APIAccessAll` on the one collection ARN, plus a data access policy that grants index read/write/create to the three AI roles but not `DeleteIndex` |
| Schedules | One scheduler role per service, trusted by `scheduler.amazonaws.com`, allowed to invoke only that service's jobs function |
| ECS | Execution role (pull image, write logs, inject the two Chat secrets) separated from the task role (invoke Auth/User only) |
| Migration task | Read only the dumps prefix of the migration bucket and the database credential |

The Cohere Marketplace subscription was accepted once by an administrator; runtime roles have no `aws-marketplace:*` permission.

### Secrets

- All database credentials are in AWS Secrets Manager, one secret per service database (`fitness-assistant/dev/<service>-database`); functions hold only `DATABASE_SECRET_ID`. The Chat task receives its database URL and the internal secret as ECS secrets (`valueFrom`), never as plain values.
- Service-to-service calls carry the shared `INTERNAL_SERVICE_SECRET`, separate from any user JWT. The Gym Service signs QR check-in codes with its own `CHECKIN_TOKEN_SECRET`, deliberately different from the internal secret.
- Payment provider keys are entered only once real sandbox credentials exist and are never copied into chat, documentation or source control.
- Bedrock needs no API key — every model call is authorized by the function's IAM role.

### Abuse and cost protection

- API Gateway route throttling on the AI routes (1 request/s with a burst of 3; 3/6 for the marketplace) caps how fast any client can trigger billable Bedrock calls; the frontend shows a "too many requests" message on HTTP 429.
- SQS dead-letter queue (2 attempts) prevents a failing AI job from being retried forever.

### Known gaps (open, not hidden)

- **Internal secrets in Lambda configuration** — `INTERNAL_SERVICE_SECRET` and `CHECKIN_TOKEN_SECRET` are Lambda environment variables (encrypted at rest, but readable by anyone allowed to view the function configuration). Chat already reads the internal secret from Secrets Manager; moving the Lambda copies there is a hardening follow-up.
- **HTTPS** — the S3 website endpoint and the Chat ALB are HTTP-only in DEV; HTTPS needs a domain and an ACM certificate, ideally with CloudFront in front of a private bucket (Origin Access Control).
- **Public-read frontend bucket** — temporary, objects only (`s3:GetObject`), until CloudFront is available.
- **No WAF yet** — nothing to attach a web ACL to until CloudFront or an HTTPS listener exists.
- **ADMIN credential rotation** and **12 remaining seed accounts** — postponed, required before any wider release.

### Screenshot evidence that contained secrets

A few console screenshots in the deployment runbook (Secrets Manager "Store a new secret" screens and Lambda "Environment variables" screens) originally showed real secret values. Each was redacted at pixel level — the value itself blacked out in the image data, not cropped or blurred — before being included in this report; the black boxes in [5.4](../../5.4-Deployment-Guide/) are intentional. All screenshots were reviewed again before publication.
