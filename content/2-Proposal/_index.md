---
title: "Proposal"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

{{% notice warning %}}
This proposal describes a **planned** architecture. Nothing below should be read as "already deployed" unless the corresponding [Workshop](../5-Workshop/) section shows verified evidence. Region, cost figures and dates are placeholders until confirmed.
{{% /notice %}}

# Cloud-Native AI Fitness Assistant on AWS
## Deploying the open-source Fitness Assistant application on AWS infrastructure

### 1. Project Title

**Cloud-Native AI Fitness Assistant on AWS** — an internship project to design, containerize and deploy the open-source [Fitness Assistant](https://github.com/trmizy/fitness-assistant) application on AWS.

### 2. Executive Summary

Fitness Assistant is an existing, actively developed open-source application: a pnpm monorepo composed of a React/Vite frontend, an application-level API gateway, and several Node.js/TypeScript backend microservices (authentication, user profiles, fitness/workout data, and an AI coaching service backed by a self-hosted LLM). It currently runs entirely through Docker Compose on a developer's machine. This project's goal is **not** to build a new application, but to take this existing, verified codebase and design + deploy a minimum viable cloud deployment on AWS — covering containerization for production, networking, a managed database, image storage, compute, and observability — while being explicit about what is included in the MVP versus deferred to future work.

### 3. Background

Fitness Assistant already implements user registration/login, profile management, an exercise catalog, workout plans, workout logging, and an AI-assisted coaching feature that combines a self-hosted LLM (Ollama, default model `llama3.2:3b`) with a Retrieval-Augmented Generation (RAG) pipeline backed by a Qdrant vector database. A separate, distinct feature — InBody body-composition photo extraction — calls the Anthropic Claude API directly for image understanding. As delivered, the application is designed for local development, not for cloud operation: it has no existing AWS, Terraform, or Kubernetes configuration, no CI/CD deployment stage. Of its seven backend services, `chat-service` adds real-time (Socket.IO) infrastructure kept out of this MVP's scope (see [Section 9](#9-out-of-mvp-scope)); `gym-service` and `payment-service` initially shipped with a development-only Dockerfile but have since gained a production build and were moved into MVP scope (see [Section 8](#8-mvp-scope)).

### 4. Problem Statement

Running Fitness Assistant beyond a single developer's laptop requires solving problems the source code does not solve on its own: where the database lives and how it is backed up, how container images are built and distributed, how the application is reachable over the internet, how secrets are managed instead of living in a local `.env` file, and how the team would know if something breaks in production. Without this work, the application cannot be demonstrated, shared, or evaluated as a deployed system — only as source code.

### 5. Target Users

- End users of the Fitness Assistant application (people tracking workouts, goals and receiving AI-assisted coaching suggestions).
- The FCAJ mentor/evaluator reviewing this internship's technical execution.
- Future contributors who may extend the AWS deployment (e.g., adding Auto Scaling, CI/CD, or Amazon Bedrock).

### 6. Overall Objective

Deploy a working, minimum viable version of Fitness Assistant on AWS that reproduces its core, verified functionality (auth, user profiles, exercises/workouts, AI coaching) on managed and self-managed AWS infrastructure, with basic monitoring, alerting, and documented security practices — and document every step so it can be reproduced and reviewed.

### 7. Specific Objectives

1. Containerize the MVP services with production-oriented Dockerfiles (multi-stage builds, no dev watchers, no secrets baked into images).
2. Design and provision a VPC with public/private subnets and least-privilege Security Groups.
3. Migrate the PostgreSQL database from a Docker container to Amazon RDS for PostgreSQL, applying the application's own Prisma migrations per service.
4. Store and version container images in Amazon ECR.
5. Deploy the MVP stack on Amazon EC2 with Docker Compose, behind a reverse proxy.
6. Set up centralized logging and alerting with Amazon CloudWatch and Amazon SNS.
7. Apply IAM least privilege and AWS Secrets Manager for credentials instead of plaintext `.env` files on the host.
8. Document, test, and clean up the deployment in a reproducible, evidence-based way.

### 8. MVP Scope

{{% notice warning %}}
This section was revised after the source repository progressed during the internship: `gym-service` and `payment-service` did **not** have a production Dockerfile when this Proposal was first drafted, which was the original stated reason for excluding them (see [Section 9](#9-out-of-mvp-scope)). Both now do. This Proposal was updated to include them in MVP scope rather than leave a now-inaccurate exclusion reason in place.
{{% /notice %}}

The MVP includes the services that are both core to the application's primary user journeys and have a production-oriented Dockerfile in the source repository:

- **Frontend** (`frontend/web`, React + Vite, built and served via Nginx).
- **Application Gateway** (`backend/gateway`) — an Express/Node.js reverse-proxy-style service internal to the application. This is **not** the AWS-managed Amazon API Gateway service; see the note in [Section 12](#12-solution-architecture).
- **Auth Service** (`backend/services/auth-service`) — registration, login, JWT issuance/verification.
- **User Service** (`backend/services/user-service`) — profiles and InBody records (including the Anthropic Claude Vision extraction feature).
- **Fitness Service** (`backend/services/fitness-service`) — exercises, workout plans, workout logs.
- **AI Service** (`backend/services/ai-service`) — Ollama-backed chat/coaching and Qdrant-backed RAG retrieval.
- **Payment Service** (`backend/services/payment-service`) — wallet top-ups and PT-contract payments, `PAYMENT_PROVIDER=MOCK` for this MVP (no real payment gateway credentials are provisioned).
- **Gym Service** (`backend/services/gym-service`) — gym/PT listings, depends on Payment Service.
- **PostgreSQL** — migrated to Amazon RDS (database-per-service: `gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, `gymcoach_payment`, `gymcoach_gym`, matching the application's existing Prisma schema design).
- **Redis** — kept as a container on the EC2 host for the MVP (BullMQ queues, rate limiting); Amazon ElastiCache is listed as future work, not MVP.
- **Qdrant** and **Ollama** — kept as containers on the EC2 host for the MVP; both have real CPU/RAM requirements that must be sized honestly (see [Section 11](#11-non-functional-requirements)).

### 9. Out of MVP Scope

- **Chat Service** — present in the source repository, but adds real-time (Socket.IO) infrastructure complexity beyond this MVP's networking/monitoring scope. Deferred to Future Development.
- ~~Gym Service, Payment Service~~ — **moved into MVP scope** (see [Section 8](#8-mvp-scope)); both gained a production Dockerfile since this Proposal was first drafted.
- **Amazon S3 for uploads** — the application currently stores uploaded files (InBody photos, profile photos, PT application documents) on local disk via `multer`. No S3 client exists in the source code today. Wiring S3 in would require an actual code change to `user-service`, which is out of scope unless implemented and verified. Marked **Planned**, not **Implemented**.
- **Amazon ElastiCache for Redis** — Optional; Redis runs as a container for the MVP.
- **Amazon Bedrock** — Optional future replacement or complement to the self-hosted Ollama LLM.
- **Amazon CloudFront, Route 53, Application Load Balancer, Auto Scaling** — Optional/Future, once the single-EC2 MVP is validated.
- **CI/CD pipeline, Infrastructure as Code (Terraform/CDK)** — Future work; the MVP is built manually and documented step by step for learning purposes.

### 10. Functional Requirements

| ID | Requirement | Source |
| --- | --- | --- |
| FR-1 | Users can register and log in | `auth-service` |
| FR-2 | Users can view/update their profile | `user-service` |
| FR-3 | Users can upload an InBody photo and receive extracted body-composition metrics | `user-service` (via Anthropic Claude Vision) |
| FR-4 | Users can browse an exercise catalog and workout plans | `fitness-service` |
| FR-5 | Users can log completed workouts | `fitness-service` |
| FR-6 | Users can receive AI-assisted coaching suggestions grounded in retrieved knowledge (RAG) | `ai-service` (Ollama + Qdrant) |
| FR-7 | All API traffic is authenticated via JWT, verified centrally by the gateway | `backend/gateway` + `auth-service` |
| FR-8 | Users can browse gyms/PTs and view listings | `gym-service` |
| FR-9 | Users can top up their wallet and pay for a PT contract (mock provider for this MVP) | `payment-service` |

### 11. Non-Functional Requirements

- **Availability:** single-EC2 MVP has no built-in redundancy; documented as a known MVP limitation, not claimed as highly available.
- **Security:** least-privilege IAM, private RDS, no secrets committed to source or baked into images, restricted SSH access.
- **Performance/Sizing:** the AI service depends on Ollama (self-hosted LLM) and Qdrant, which realistically require more CPU/RAM than a Free Tier `t3.micro` instance. This must be sized and tested, not assumed.
- **Observability:** logs and key metrics must reach CloudWatch, with alarms routed through SNS to email.
- **Cost predictability:** resources must be right-sized and stoppable; no resource should run unmonitored for cost.
- **Data safety:** database backups enabled; migrations run through the application's own Prisma tooling, not hand-written SQL.

### 12. Solution Architecture

{{% notice warning %}}
`backend/gateway` is an **application-level** Node.js/Express service (its own internal HTTP router and reverse proxy) that ships as part of the Fitness Assistant source code. It is **not** the AWS-managed **Amazon API Gateway** service. This MVP does not use Amazon API Gateway; `backend/gateway` runs as a container on EC2, and any use of Amazon API Gateway is listed only under Future Development.
{{% /notice %}}

![Fitness Assistant AWS architecture diagram — TODO: this PNG is still a placeholder; export it from the .drawio source below before submission](/images/workshop/architecture/fitness-assistant-aws-architecture.png)

Downloadable source: [fitness-assistant-aws-architecture.drawio](/files/architecture/fitness-assistant-aws-architecture.drawio) — this is now a real diagram (AWS4 icon set: EC2, RDS, Internet Gateway, ECR, IAM Role, Secrets Manager, CloudWatch, SNS), matching the MVP topology in this section. **TODO remaining:** open it in draw.io, verify every icon rendered, fill in the real AWS Region, and export the PNG above (see `static/files/architecture/README.md`).

**Current MVP architecture (planned):**

```
Internet
   │
   ▼
EC2 (public subnet) — Nginx reverse proxy
   ├── Frontend container (React build, served by Nginx)
   └── Application Gateway container (backend/gateway, Node.js/Express)
             │  (JWT verification via HTTP call to auth-service)
             ▼
   ┌─────────┴──────┬───────────┬───────────┬─────────────┬─────────────┐
   ▼                 ▼           ▼           ▼             ▼             ▼
Auth Service    User Service  Fitness    AI Service   Payment       Gym Service
(container)     (container)  Service    (Ollama +     Service       (container)
                              (container) Qdrant,      (container)
                                          containers)
   │                 │           │           │             │             │
   └─────────────────┴───────────┴───────────┴─────────────┴─────────────┘
                                  │
                                  ▼
                   Amazon RDS for PostgreSQL (private subnet)
                                  │
                          Amazon CloudWatch  ──►  Amazon SNS ──► Email
```

Redis, Qdrant and Ollama run as containers alongside the application containers on the same EC2 host for the MVP. Amazon ECR stores all container images; AWS Secrets Manager stores database credentials, JWT secrets and the `ANTHROPIC_API_KEY`; an IAM Role attached to the EC2 instance grants least-privilege access to ECR, CloudWatch and Secrets Manager.

### 13. Data Flow Description

1. A browser request reaches the EC2 host's Nginx reverse proxy.
2. Static frontend assets are served directly; API calls are forwarded to the `backend/gateway` container.
3. The gateway extracts the `Authorization: Bearer <token>` header and calls `auth-service`'s `/auth/verify` endpoint to validate it, then forwards the request downstream with `x-user-id`/`x-user-email`/`x-user-role` headers.
4. The downstream service (user/fitness/ai) processes the request, reading/writing its own logical database on the shared Amazon RDS PostgreSQL instance via Prisma.
5. `ai-service` additionally queries Qdrant for relevant context and calls the Ollama container's `/api/chat` endpoint to generate a response; `user-service` calls the external Anthropic API for InBody photo extraction when that feature is used.
6. Application and container logs are shipped to Amazon CloudWatch Logs via the CloudWatch Agent; key metrics trigger CloudWatch Alarms that publish to an Amazon SNS topic, which emails the on-call/reviewer.

### 14. AWS Services

| Service | Role | Reason for Choosing | Status |
|---------|------|----------------------|--------|
| Amazon EC2 | Hosts the Docker Compose stack for the MVP | Simplest compute model to learn container deployment fundamentals before adopting ECS/EKS | Planned |
| Amazon ECR | Stores versioned container images per service | Native integration with EC2 IAM roles; avoids Docker Hub rate limits | Planned |
| Amazon RDS for PostgreSQL | Managed database, replacing the Docker `postgres` container | Automated backups, private networking, matches the app's existing PostgreSQL/Prisma design | Planned |
| Amazon VPC | Network isolation, public/private subnets | Required foundation for least-privilege network design | Planned |
| AWS IAM | Roles/policies for EC2 access to ECR, CloudWatch, Secrets Manager | Avoids embedding long-lived AWS credentials on the host | Planned |
| AWS Secrets Manager | Stores DB credentials, JWT secrets, `ANTHROPIC_API_KEY` | Avoids plaintext `.env` files on the EC2 host | Planned |
| Amazon CloudWatch | Logs, metrics, dashboards, alarms | Centralized observability without adding a third-party tool | Planned |
| Amazon SNS | Email alerting from CloudWatch Alarms | Simple, native notification path for an MVP | Planned |
| Amazon S3 | Future storage for user-uploaded photos/documents | Not yet integrated in the application source; requires a code change | Planned |
| Amazon ElastiCache for Redis | Future managed replacement for the Redis container | Not required for MVP; Redis container is sufficient at this scale | Optional |
| Amazon Bedrock | Future managed alternative/complement to self-hosted Ollama | Would remove the need to size EC2 for an embedded LLM | Optional |
| Amazon CloudFront | Future CDN/edge caching for the frontend | Not required until there is real external traffic | Optional |
| Amazon Route 53 | Future custom domain / DNS management | No domain registered yet for this project | Optional |
| Elastic Load Balancing | Future load balancing once more than one EC2 host exists | Single-host MVP does not need it yet | Optional |
| AWS CDK / Terraform | Future Infrastructure as Code | MVP is built manually for learning purposes first | Optional |

### 15. Reasoning Per Service (Summary)

Each "Planned" service above was chosen because it directly replaces a concrete gap in the current Docker Compose setup (a container-only Postgres, a `.env` file for secrets, no logging pipeline) rather than because it is a "default AWS stack." Each "Optional" service was deliberately excluded from MVP scope because the current application does not yet require it — for example, S3 is optional only because no S3 client exists in the source code, not because file storage is unimportant.

### 16. Security

- IAM least privilege: EC2's instance role is scoped to only the ECR/CloudWatch/Secrets Manager actions it actually needs.
- RDS is not publicly accessible; only the application Security Group may reach port 5432.
- SSH access (port 22) is restricted to a specific IP/CIDR, never `0.0.0.0/0`, in the recommended design.
- Secrets (`JWT_SECRET`, `DATABASE_URL` credentials, `ANTHROPIC_API_KEY`) are stored in AWS Secrets Manager, not committed to source or baked into Docker images.
- Existing application-level protections are preserved and not weakened: JWT-based auth, gateway-side rate limiting (`express-rate-limit`), bcrypt password hashing.

### 17. Scalability

The MVP intentionally runs on a single EC2 host to keep the learning scope manageable. The architecture is designed so that, if traffic grows, the application (gateway) and stateless services could move to Amazon ECS/Fargate behind an Application Load Balancer with Auto Scaling, without changing the RDS/Secrets Manager/ECR foundations already built.

### 18. Monitoring

CloudWatch Logs (via CloudWatch Agent) for container/application logs, CloudWatch Metrics/Alarms for EC2 CPU, EC2 status checks, and RDS CPU/connections/storage, with SNS email notification. Full detail in [Workshop 5.12](../5-Workshop/5.12-Monitoring-Alerting/).

### 19. Backup and Recovery

Amazon RDS automated backups with a defined retention window; manual snapshot before any risky schema change. EBS volume on EC2 is not treated as a durable data store (application state lives in RDS, not on the host).

### 20. 12-Week Timeline

| Week | Focus |
|------|-------|
| 1 | Research, requirements analysis, run the app locally |
| 2 | Codebase and microservices analysis |
| 3 | Production Dockerfiles and image optimization |
| 4 | AWS architecture design |
| 5 | Networking (VPC, subnets, routing, Security Groups) |
| 6 | Amazon RDS for PostgreSQL |
| 7 | Amazon ECR and IAM roles |
| 8 | Amazon EC2 deployment |
| 9 | Reverse proxy, service wiring, file storage decision |
| 10 | CloudWatch and SNS monitoring |
| 11 | Testing, security and cost review |
| 12 | Clean-up and final report |

See the full [Worklog](../1-Worklog/) for weekly detail.

### 21. Cost Estimate

{{% notice warning %}}
AWS pricing changes by Region and over time. Verify all figures with the [AWS Pricing Calculator](https://calculator.aws/) before any real deployment. The figures below are placeholders for planning only, not a quote.
{{% /notice %}}

- **AWS Region (planned):** `[TODO_AWS_REGION]`
- **Estimated components:** one EC2 instance sized for the AI stack (see [Workshop 5.9](../5-Workshop/5.9-EC2-Deployment/) for sizing notes), one small Amazon RDS PostgreSQL instance, ECR storage for a handful of images, CloudWatch Logs/Alarms, SNS email notifications.
- **TODO:** Insert the actual AWS Pricing Calculator estimate link and monthly figure once the final instance types are chosen.
- Free Tier does **not** necessarily cover this workload in full — the AI stack (Ollama + Qdrant) is unlikely to run acceptably on a Free Tier-eligible instance type; this must be verified, not assumed.

### 22. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| EC2 instance under-sized for Ollama/Qdrant | High | High | Right-size the instance based on measured load; document actual CPU/RAM usage (Week 8/11) |
| Secrets accidentally committed to git | Medium | High | `.gitignore` for `.env`/keys, pre-commit review, Secrets Manager for runtime secrets |
| ~~`gym-service`/`payment-service` lacked production Dockerfiles~~ | ~~High~~ Resolved | ~~Low~~ | **Resolved during the internship**: both services gained a production Dockerfile in the source repo and were moved from Out of MVP Scope into MVP Scope (see [Section 8](#8-mvp-scope)); this row is kept, not deleted, as a record of the actual scope change |
| Cost overrun from forgotten running resources | Medium | Medium | Stop/terminate resources when not in use; AWS Budgets alert (recommended, optional) |
| RDS migration inconsistency (`user-service` does not auto-run `prisma migrate deploy`) | Medium (found) | Medium | **Found and fixed during the internship**: `user-service`'s production Dockerfile was the only one of the six MVP backend services that did not run `prisma migrate deploy` on container start — verified against the other five, then corrected to match. See [Week 3 Worklog](../1-Worklog/1.3-Week3/) for the discovery/fix evidence. |
| Single EC2 host = single point of failure | High (by MVP design) | Medium | Documented as a known MVP limitation; Auto Scaling/ALB listed as future work |

### 23. Success Criteria

- The MVP services listed in [Section 8](#8-mvp-scope) are reachable end to end from a browser, backed by Amazon RDS.
- CloudWatch Alarms trigger and notify via SNS email at least once during testing (verified, not assumed).
- No secrets are present in the Git repository or in container images.
- All AWS services claimed as "Implemented" in this report are backed by evidence in the [Workshop](../5-Workshop/) section.

### 24. Deliverables

- This bilingual report (Worklog, Proposal, Blogs, Events, Workshop, Self-evaluation, Feedback).
- Production Dockerfile examples for the MVP services.
- A `docker-compose.aws.example.yml` describing the EC2 deployment topology.
- Architecture diagram (draw.io source + exported image) — TODO, pending final implementation.
- IAM policy and Security Group examples with placeholder ARNs/account IDs.

### 25. Future Development

- Amazon ECS/Fargate with an Application Load Balancer and Auto Scaling.
- Amazon CloudFront + Route 53 for a custom domain and edge caching.
- Amazon Bedrock as a managed alternative/complement to self-hosted Ollama.
- Amazon S3 (with a real code change in `user-service`) replacing local-disk uploads.
- Amazon ElastiCache for Redis, replacing the Redis container.
- CI/CD pipeline (GitHub Actions) building and deploying on every merge.
- Infrastructure as Code (Terraform or AWS CDK) instead of manual console steps.
- Deployment of `chat-service` (real-time Socket.IO infrastructure, real payment gateway credentials for `payment-service` in place of `PAYMENT_PROVIDER=MOCK`).

### 26. References

- FCAJ project rules: https://hcm-rules.awsfcaj.com/3-project/
- Report template: https://github.com/thienluhoan/fcj-workshop-template
- Application source code: https://github.com/trmizy/fitness-assistant
