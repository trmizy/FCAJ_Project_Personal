---
title: "5.2.4 AWS Services and Selection Rationale"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.2.4. </b> "
---

| AWS Service | Used for | Why this, not an alternative |
|---|---|---|
| **AWS Lambda** | Auth, User, Fitness, Gym, Payment and AI — 12 long-lived functions (HTTP, jobs, AI Worker) plus migration functions | Six of seven services are short request/response or scheduled work with no need to hold a connection open. Lambda scales to zero between requests — important for a DEV environment that is idle most of the time — and removes the instance-sizing problem this project had already hit with a self-hosted model on EC2 (see [Week 8](../../../1-Worklog/1.8-Week8/)). |
| **Amazon ECS on AWS Fargate** | Chat Service (REST + Socket.IO), and the one-shot database migrator task | The one service that cannot be Lambda: Socket.IO holds a persistent connection per session. Fargate runs the container without any server to patch; dev sizing is 0.5 vCPU / 1 GB. The same cluster runs the data-migration task on demand. |
| **Amazon ECR** | Images for the Chat Service and the database migrator | Private registry in the same region, pulled by ECS through the task execution role — no Docker Hub credentials or rate limits. |
| **Amazon API Gateway (HTTP API)** | Single entry point for the six Lambda services and the Chat REST routes | One routing layer with explicit route prefixes instead of one public endpoint per service; HTTP API is cheaper than REST API and supports per-route throttling, used to protect Bedrock cost. |
| **Elastic Load Balancing (ALB)** | Front door for the Chat Fargate task | Handles Socket.IO/WebSocket upgrades, health checks on `/health`, stickiness and path rules that hide `/internal/*` and `/metrics`. |
| **Amazon Aurora PostgreSQL Serverless v2** | One cluster, seven logical databases | Managed PostgreSQL that matches the application's Prisma schemas, scales capacity (ACU) automatically and can drop to a low floor (0.5 ACU during deployment, 0 when idle). One cluster instead of seven keeps cost and operations down while each service keeps its own database and secret. |
| **Amazon Bedrock** | Chat and vision (Nova Pro via the APAC inference profile) and embeddings (Cohere Embed Multilingual v3) | Replaces the self-hosted Ollama model: no instance to size, no API key to manage (IAM only), billed per token, reached from the VPC like any AWS API. |
| **Amazon OpenSearch Serverless** | Vector search for RAG and knowledge retrieval (`fitness-assistant-dev-ai-vectors`) | Replaces the self-hosted Qdrant container: k-NN (FAISS/HNSW, 1024 dimensions) without servers, private through a VPC endpoint, IAM + data-access-policy authorization, and the NextGen collection group scales between 0 and 2 OCU. |
| **Amazon SQS** | AI task queue and its dead-letter queue | Decouples long AI generations from the 30-second HTTP path; the Worker processes one message at a time and failed messages land in the DLQ after two attempts. Replaces Redis/BullMQ, which would have needed a running cache cluster. |
| **Amazon EventBridge Scheduler** | 13 schedules for settlements, reminders, payouts, reconciliation and AI jobs | Managed cron per job with retries, without a long-running process or `setInterval` inside an HTTP function. |
| **Amazon S3** | Static frontend; private uploads (profile photos, PT documents, contracts); deployment artifacts; migration dumps | Four buckets with four different access models — public-read website, private with presigned URLs, private artifacts for Lambda, private versioned dumps — so data never shares a bucket with public assets. |
| **AWS Secrets Manager** | Every database credential, the database URL for Chat, the shared internal secret | No password in code, images or plain environment variables; each function holds only a secret ID and resolves it at runtime. |
| **AWS IAM** | One role per function or task, scoped to its own secret, queue, model and invoke targets | Least privilege per service instead of a broad shared role — see [5.2.5](../5.2.5-Security-IAM/). |
| **Amazon VPC, NAT Gateway, Internet Gateway, VPC endpoints** | Network isolation and controlled egress | Lambda, Fargate and Aurora sit in private subnets; one NAT Gateway gives outbound access (Bedrock); interface endpoints keep Secrets Manager and OpenSearch traffic inside the VPC; DB subnets have no internet route at all. |
| **Amazon CloudWatch Logs** | Logs for every Lambda, the Chat task and the migrator | Default destination for both compute types; used for troubleshooting during deployment. Alarms are an open item ([5.2.6](../5.2.6-Scalability-Operations/)). |

### Deliberately not used (yet)

- **Amazon CloudFront** — planned once the frontend moves off the plain S3 website endpoint, so the bucket can become private behind Origin Access Control and the site can use HTTPS. Not usable in this account yet.
- **AWS WAF** — there is no CloudFront distribution or HTTPS listener to attach a web ACL to at this stage.
- **Amazon ElastiCache** — not needed: queues moved to SQS and the Chat Service runs a single task. It becomes necessary only to share Socket.IO state across several Chat tasks.
- **CI/CD (CodePipeline/CodeBuild or GitHub Actions)** — every deployment so far was a manual, documented console/CLI step; this is the largest remaining gap.
