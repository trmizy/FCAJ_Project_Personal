---
title: "5.2.4 AWS Services and Selection Rationale"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.2.4. </b> "
---

| AWS Service | Used For | Why This, Not an Alternative |
|---|---|---|
| **AWS Lambda** | Auth, User, Fitness, Gym, Payment, AI (HTTP + Worker + Jobs) — 10 functions total | Six of eight services are short-lived request/response or scheduled work with no need to hold a connection open. Lambda scales to zero between requests, which matters for a DEV environment that is mostly idle, and removes the instance-sizing problem this project had already hit once with a self-hosted Ollama container on EC2 (see [Week 8](../../../1-Worklog/1.8-Week8/)). |
| **Amazon ECS on Fargate** | Chat Service (REST + Socket.IO) | The one service that genuinely cannot be Lambda: Socket.IO holds a persistent connection per session, which does not fit Lambda's per-invocation billing/execution model. Fargate was chosen over self-managed EC2+ECS so there is still no server to patch or size beyond the task's own CPU/RAM (dev sizing: 0.5 vCPU / 1 GB). |
| **Amazon API Gateway (HTTP API)** | Single entry point for the six Lambda-based services | One routing layer in front of all request-path Lambdas, instead of each service needing its own public endpoint. HTTP API (not REST API) was enough for this project's routing needs at lower cost. |
| **Application Load Balancer** | Front door for the Chat Fargate task | API Gateway does not proxy WebSocket upgrades the way this project needed; an ALB does, and it is the standard pairing for an ECS/Fargate service. |
| **Amazon Aurora PostgreSQL (Serverless v2)** | One shared cluster, one logical database per service | A managed, auto-scaling Postgres cluster removes the operational work of a self-managed RDS instance's capacity planning. Serverless v2's ability to scale down to a low ACU floor (currently 0.5 ACU, see [5.2.7](../5.2.7-Cost-Optimization-Cleanup/)) matters specifically because this is a DEV environment that sits idle most of the time. One cluster with seven logical databases (rather than seven clusters) keeps cost and operational surface down while still giving each service its own schema and its own `DATABASE_SECRET_ID`. |
| **Amazon Bedrock** | AI coaching chat/vision (Nova Pro) and retrieval embeddings (Cohere multilingual) | Replaces an earlier self-hosted Ollama + Qdrant pair (see [Week 8](../../../1-Worklog/1.8-Week8/)) once the operational cost of sizing and running an LLM on EC2 outweighed the self-hosting savings. Bedrock is reached as a plain AWS API call from inside the VPC via the NAT Gateway, with no separate model-hosting infrastructure to manage. |
| **Amazon S3** | Static frontend hosting; a separate bucket for database migration artifacts | The frontend is a static build with no server-side rendering requirement, so S3 website hosting is the simplest possible host for it. The migration bucket is deliberately separate from the frontend bucket and from any user-upload bucket, so a migration dump is never reachable through a path meant for public frontend assets. |
| **Amazon EventBridge + Amazon SQS** | Scheduled jobs (reconciliation, reminders) and async AI work queueing | Decouples slow or scheduled work from the synchronous request path, so a user-facing API call never waits on a reconciliation job or a long AI completion. EventBridge Scheduler handles the "run this periodically" case per service; SQS handles the "queue this for a worker" case for AI jobs. |
| **AWS Secrets Manager** | Every database credential, plus the shared internal-service secret and the Gym QR check-in signing secret | Centralizes credential storage so no service's Lambda environment variables ever hold a raw password — each Lambda holds a secret *ID* (`DATABASE_SECRET_ID`) and resolves the value at runtime. |
| **AWS IAM** | One execution role per Lambda, scoped to only the secrets and cross-service invokes that Lambda actually needs | Least-privilege by service, not a single shared "can do anything" execution role — see [5.2.5](../5.2.5-Security-IAM/). |
| **Amazon VPC, NAT Gateway, Internet Gateway** | Network isolation for Lambda and Aurora; outbound-only internet path for Lambda | Lambda and Aurora sit in private subnets with no inbound internet route; the NAT Gateway exists purely so Lambda can reach outbound AWS APIs (Bedrock, Secrets Manager) and API Gateway. DB subnets have no NAT/internet route at all. |
| **Amazon CloudWatch** | Logs for every Lambda and the Fargate task | Default, zero-setup logging target for both compute types used in this project; used for troubleshooting during deployment rather than alerting yet (no alarms configured so far — see [5.2.6](../5.2.6-Scalability-Operations/)). |

### Deliberately Not Used (Yet)

- **Amazon CloudFront** — planned once the frontend moves off a plain S3 website endpoint, so the bucket can go private behind an Origin Access Control instead of being publicly readable. Not usable in this environment yet.
- **AWS WAF** — no public-facing component currently sits behind a CloudFront distribution or an internet-facing ALB on HTTPS, so there is nothing for a WAF web ACL to attach to yet.
- **CI/CD (CodePipeline/CodeBuild, or any third-party equivalent)** — every deployment so far has been a manual console/CLI step, captured as it happened. Tracked as the single largest remaining gap in [5.1 Overview](../../5.1-Overview/).
