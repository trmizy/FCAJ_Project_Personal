---
title: "5.2 Architecture"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2. </b> "
---

{{% notice warning %}}
`backend/gateway` is an **application-level** Node.js/Express container that ships with the Fitness Assistant source code — it is its own internal reverse proxy / router, **not** the AWS-managed **Amazon API Gateway** service. This MVP does not use Amazon API Gateway. See [Proposal Section 12](../../2-Proposal/#12-solution-architecture) for the same clarification.
{{% /notice %}}

### Architecture Diagram

![Fitness Assistant AWS architecture — TODO: this PNG is still a placeholder; export it from the .drawio source below](/images/workshop/architecture/fitness-assistant-aws-architecture.png)

Downloadable source: [fitness-assistant-aws-architecture.drawio](/files/architecture/fitness-assistant-aws-architecture.drawio)

{{% notice note %}}
The `.drawio` file is a real diagram (AWS4 icon set — EC2, RDS, Internet Gateway, ECR, IAM Role, Secrets Manager, CloudWatch, SNS — laid out across a custom VPC with public/private subnets, matching this section's Request/Data/Log flows). **Only the PNG export above is still a placeholder** — open the `.drawio` in draw.io, verify the icons rendered correctly, fill in the real AWS Region, and export it as PNG before this report is submitted. See `static/files/architecture/README.md` and `static/images/workshop/architecture/README.md`.
{{% /notice %}}

### AWS Services Used (MVP)

Amazon EC2, Amazon ECR, Amazon RDS for PostgreSQL, Amazon VPC, AWS IAM, AWS Secrets Manager, Amazon CloudWatch, Amazon SNS. See the full table with reasoning in [Proposal Section 14](../../2-Proposal/#14-aws-services).

### Request Flow

1. Browser → Nginx reverse proxy on the EC2 host.
2. Static frontend assets served directly (built React/Vite app); API calls proxied to the `backend/gateway` container (port 3000).
3. Gateway calls `auth-service`'s `/auth/verify` endpoint with the caller's JWT, then forwards the request downstream with `x-user-id` / `x-user-email` / `x-user-role` headers.
4. The relevant downstream service (`user-service`, `fitness-service`, `ai-service`, `payment-service`, `gym-service`) handles the request.

### Data Flow

- Each backend service reads/writes its own logical database (`gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, `gymcoach_payment`, `gymcoach_gym`) on the single shared Amazon RDS PostgreSQL instance, via Prisma.
- `ai-service` additionally queries the Qdrant container for RAG context and calls the Ollama container's `/api/chat` / `/api/embeddings` endpoints.
- `gym-service` calls `payment-service` for wallet/contract operations; `payment-service` runs with `PAYMENT_PROVIDER=MOCK` for this MVP (no real payment gateway credentials).
- `user-service` calls the external Anthropic Claude API for InBody photo extraction (requires outbound internet access and the `ANTHROPIC_API_KEY` secret).
- Uploaded files (InBody photos, profile photos, PT documents) are currently written to local disk on the EC2 host via `multer` — there is no S3 integration in the application source today.

### Deployment Flow

1. Build production Docker images locally (or in CI in the future) from the existing multi-stage Dockerfiles.
2. Push images to per-service Amazon ECR repositories.
3. On the EC2 host, pull the latest images and restart the Docker Compose stack.
4. Run `prisma migrate deploy` per service against the RDS endpoint when the schema changes.

### Log and Alert Flow

Container/application logs → CloudWatch Agent → CloudWatch Logs → CloudWatch Alarms (EC2 CPU, EC2 status check, RDS CPU/connections/storage) → Amazon SNS topic → email subscriber. Full detail in [5.12 Monitoring and Alerting](../5.12-Monitoring-Alerting/).

### Network Boundary

- **Public subnet:** the single EC2 host (frontend, gateway, and all application containers), reachable from the internet only on ports 80/443 (and SSH, restricted to a specific IP).
- **Private subnets:** Amazon RDS for PostgreSQL, spread across two Availability Zones for the DB subnet group; not reachable from the internet.

### Public vs. Private Resources

| Resource | Placement | Internet-reachable? |
|---|---|---|
| EC2 (frontend, gateway, all services, Redis, Qdrant, Ollama containers) | Public subnet | Yes, ports 80/443 only (SSH restricted) |
| Amazon RDS for PostgreSQL | Private subnets (DB subnet group) | No |

### Security Group Flow (Summary)

Full matrix in [5.6 Network Infrastructure](../5.6-Network-Infrastructure/). In summary: the internet may reach the EC2 Security Group only on 80/443 (and a restricted SSH IP); the RDS Security Group accepts port 5432 only from the EC2 Security Group; no other inbound paths exist.

### Current Architecture vs. Future Architecture

**Current (MVP):** single EC2 host running Docker Compose for all application containers, one Amazon RDS instance, ECR for images, CloudWatch/SNS for observability.

**Future:** Amazon ECS/Fargate services behind an Application Load Balancer with Auto Scaling; Amazon CloudFront + Route 53 for the frontend; Amazon Bedrock as an alternative to self-hosted Ollama; Amazon S3 (with an application code change) for uploads; Amazon ElastiCache for Redis; CI/CD and Infrastructure as Code. Full list in [Proposal Section 25](../../2-Proposal/#25-future-development).
