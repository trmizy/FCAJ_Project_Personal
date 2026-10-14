---
title: "5.2.3 Main Request Flows"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.2.3. </b> "
---

### Core API Path

Covers Auth, User, Fitness, Gym, Payment, and the AI HTTP Lambda.

1. Browser loads the static frontend from the Amazon S3 website endpoint (`fitness-assistant-frontend-dev-191798898985`).
2. The frontend calls Amazon API Gateway (`fitness-assistant-dev-api`, `https://id1iz7upbl.execute-api.ap-southeast-1.amazonaws.com`).
3. API Gateway routes the request to the matching service Lambda (Auth, User, Fitness, Gym, Payment, or AI) based on the path.
4. For routes that require a logged-in user, the target Lambda verifies the caller's JWT itself (no separate internal "auth check" hop through API Gateway) and, where a request needs data from another service, invokes that service's Lambda directly (e.g. Payment invoking Auth/User to resolve who it's billing), authenticated with a shared internal service secret rather than a second JWT round-trip.
5. The Lambda reads/writes its own logical database on the shared Aurora PostgreSQL Serverless cluster, reached over the private app subnets.
6. The response returns back through API Gateway to the frontend.

### Chat Path

1. Browser connects to the Chat ALB's public DNS name, either over plain HTTP REST endpoints or a Socket.IO WebSocket upgrade.
2. The ALB forwards the connection to the Chat Service task running on ECS Fargate (`fitness-assistant-dev-cluster` / `fitness-assistant-dev-chat-service`), on container port 3005.
3. The security group chain only allows the ALB to reach the Fargate task on that port — the task is never reachable directly from the internet.
4. The Chat Service reads/writes the Chat logical database on the same Aurora cluster.
5. Where Chat needs to call another service (e.g. to confirm a user's identity), it invokes that service's Lambda the same way the Core API path services call each other.

{{% notice note %}}
DEV currently runs the ALB over HTTP (port 80) only — the frontend itself is also HTTP-only at this stage (see [5.2.7](../5.2.7-Cost-Optimization-Cleanup/)), so there is no mixed-content issue yet. Moving the ALB to HTTPS is tracked as a known follow-up once a domain and an ACM certificate are in place.
{{% /notice %}}

### Background Processing Path

1. Scheduled actions (e.g. Payment's reconciliation schedule, Gym and Fitness reminder schedules) are triggered by Amazon EventBridge Scheduler rules, one per service, rather than a single shared cron Lambda.
2. Asynchronous AI work (chat completions that take longer than the HTTP Lambda's timeout allows, or jobs explicitly queued by another service) goes through Amazon SQS to the AI Worker Lambda.
3. The AI Worker and the per-service Jobs Lambdas read/write the same Aurora cluster as the request-path Lambdas — there is no separate "jobs" database.
4. The AI path additionally calls out to Amazon Bedrock (model `apac.amazon.nova-pro-v1:0` for chat/vision completions, `cohere.embed-multilingual-v3` for embeddings) over the NAT Gateway, since Bedrock is reached as a regular AWS API endpoint from inside the VPC.

### Why Three Separate Paths Instead of One

The Core API path is a textbook fit for Lambda: short-lived, stateless, scales to zero. The Chat path cannot use that same model because Socket.IO needs a connection that survives across many request/response cycles — hence ECS Fargate and an ALB instead of API Gateway and Lambda for that one service. The Background Processing path exists so that scheduled and slow AI work doesn't block a user-facing HTTP request's timeout window, and so that a spike in AI requests queues up in SQS instead of throttling the synchronous API path.
