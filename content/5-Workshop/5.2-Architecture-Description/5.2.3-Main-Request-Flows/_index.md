---
title: "5.2.3 Main Request Flows"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.2.3. </b> "
---

### Core API path

Covers Auth, User, Fitness, Gym, Payment and the AI HTTP Lambda.

1. The browser loads the static frontend from the Amazon S3 website endpoint.
2. The frontend calls Amazon API Gateway (`fitness-assistant-dev-api`) with `Authorization: Bearer <JWT>`.
3. API Gateway matches the route (explicit routes for Auth, one root + greedy route pair per prefix for the other services) and invokes the service's Lambda with payload format 2.0. `/internal/*`, `/metrics` and a catch-all `/{proxy+}` are never published.
4. The Lambda verifies the JWT itself — the AI Lambda, for example, invokes the Auth Lambda to validate the token and rejects spoofed `x-user-id` / `x-user-role` headers — so there is no separate API Gateway authorizer.
5. When a request needs another service, the Lambda invokes that service's Lambda directly (`lambda:InvokeFunction`), authenticated with the shared `INTERNAL_SERVICE_SECRET`. Examples: User → Auth, Payment → Auth/User/Gym, Gym → Payment, Payment → AI to activate a paid personalized service.
6. The Lambda reads/writes its own logical database on Aurora through the private app subnets, using credentials it resolves from Secrets Manager at runtime.
7. The response returns through API Gateway to the browser.

### Chat path

1. **REST** (conversation lists, history): the frontend calls API Gateway `ANY /chat/{proxy+}`, an HTTP proxy integration that forwards to `http://<chat-alb>/chat/{proxy}`.
2. **Real-time**: the frontend opens Socket.IO directly to the Chat ALB (`/socket.io/`), HTTP on port 80 in DEV.
3. The ALB forwards to the Fargate task on container port 3005; its listener answers `/internal/*` and `/metrics` with a fixed 404 so they never reach the container. Target-group stickiness keeps a client on the same task.
4. The task runs in the private app subnets with no public IP; its security group only accepts port 3005 from the ALB's security group.
5. The Chat Service reads/writes `fitness_assistant_chat` on Aurora and invokes the Auth/User Lambdas through its ECS task role.

{{% notice note %}}
DEV runs the ALB on HTTP only, like the S3 website endpoint, so there is no mixed-content problem yet. Moving both to HTTPS needs a domain and an ACM certificate (see [5.2.5](../5.2.5-Security-IAM/)).
{{% /notice %}}

### Background path

1. **Scheduled jobs** — 13 EventBridge Scheduler schedules (session settlement, auto-confirm, reschedule expiry, workout reminders, membership payouts, referral settlement, payment reconciliation, AI auto-accept and four nightly knowledge refreshes) invoke each service's jobs Lambda with a `{"job": "<name>"}` payload. Each service has its own scheduler role that can invoke only its own jobs function.
2. **Long AI work** — the AI HTTP Lambda queues plan generations on Amazon SQS (`fitness-assistant-dev-ai-tasks`); the AI Worker Lambda consumes them one at a time (batch size 1, up to 300 s each, 2 attempts before the dead-letter queue) and the frontend polls the job status.
3. **Knowledge ingestion** — the AI Jobs Lambda fetches PubMed, RSS, web and local evidence nightly, embeds it with Cohere Embed Multilingual v3 (1024 dimensions) and writes it to OpenSearch Serverless.
4. All AI functions call Amazon Bedrock through the NAT Gateway and reach OpenSearch Serverless privately through its VPC endpoint, signing requests with their IAM role (SigV4).

### Why three separate paths instead of one

The Core API path is a textbook fit for Lambda: short-lived, stateless, scales to zero. The Chat path cannot use that model because Socket.IO needs a connection that survives many request/response cycles — hence ECS Fargate and an ALB for that one service. The Background path keeps slow or periodic work out of a user's HTTP request: API Gateway gives an integration about 30 seconds, while a plan generation can take minutes and a knowledge crawl up to ten.
