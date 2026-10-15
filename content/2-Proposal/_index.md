---
title: "Proposal"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

# Gymini — AI Fitness Assistant on AWS
## A serverless microservices deployment with managed AI on Amazon Bedrock

### 1. Executive Summary {#summary}

Gymini (the open-source Fitness Assistant project) is a pnpm monorepo with a React/Vite frontend and seven Node.js/TypeScript services — Auth, User, Fitness, Gym, Payment, AI and Chat — that until now only ran on a developer machine with Docker Compose. This internship project designs and deploys it on AWS as a serverless-first DEV environment in the Asia Pacific (Singapore) region, documented step by step so it can be reviewed, repeated and later automated.

Each service runs on the AWS service that fits its runtime shape: six request/response services on AWS Lambda behind Amazon API Gateway, the real-time Chat service on Amazon ECS Fargate behind an Application Load Balancer, one Amazon Aurora PostgreSQL Serverless v2 cluster with a logical database per service, Amazon Bedrock (Nova Pro, Cohere Embed) and Amazon OpenSearch Serverless for the AI coach, and Amazon SQS plus EventBridge Scheduler for background work. The static frontend is served from Amazon S3; credentials live in AWS Secrets Manager; every function has its own least-privilege IAM role inside private subnets.

At the latest checkpoint every service is deployed, the 7 local databases have been restored into Aurora with all 23 audited foreign keys validated, and Auth and User pass end-to-end tests. Remaining work — end-to-end tests of the other services, CI/CD, alarms, HTTPS and an automated "sleep" mode for cost — is planned and tracked in the [Workshop](../5-Workshop/5.5-Test-Validation/5.5.5-Status-Open-Items/).

### 2. Problem Statement {#problem}

#### Current problems

- **Local-only operation.** The whole stack (PostgreSQL, Redis, Qdrant, a self-hosted Ollama model and seven services) runs in Docker Compose on one laptop: no public endpoint, no backups, no isolation between components.
- **Secrets in `.env` files.** Database passwords, JWT and service-to-service secrets and provider keys are plain text on disk.
- **Heavy self-hosted AI.** The AI coach needs a local LLM and vector database on an always-on machine; an earlier EC2 sizing exercise showed that a free-tier instance cannot run it.
- **Background work tied to processes.** Reminders, settlements and reconciliation ran as in-process timers, which do not exist on serverless compute.
- **Real-time chat.** Socket.IO needs long-lived connections that a request/response platform cannot hold.

#### Proposed solution

Re-platform each part onto the managed service that matches it, adapting the code where needed:

- Request/response services → AWS Lambda with HTTP API (payload 2.0) handlers, a separate jobs handler and a migration handler that reads `DATABASE_SECRET_ID`; internal calls become direct Lambda invokes instead of HTTP through an application gateway.
- Real-time chat → ECS Fargate behind an ALB, REST routed through API Gateway.
- PostgreSQL → Aurora Serverless v2, one logical database per service, data restored from the local dumps.
- AI → Amazon Bedrock for chat, vision and embeddings; OpenSearch Serverless for vectors; long generations queued on SQS and processed by a worker.
- Timers → EventBridge Scheduler schedules invoking jobs functions.
- Frontend → S3 static website (CloudFront and HTTPS as the next step).

#### Benefits

The DEV environment pays mostly for what it uses, there are no servers to patch for six of the seven services, the AI coach no longer needs a model host, networking is private and permissions are least-privilege by default, and the deployment is captured in a runbook that can be repeated by hand or turned into a pipeline.

### 3. Solution Architecture {#architecture}

The diagram shows the architecture this project is designed around. It is the target the deployment works toward; [Workshop 5.5.5](../5-Workshop/5.5-Test-Validation/5.5.5-Status-Open-Items/) tracks exactly which pieces are confirmed running in the DEV environment today, and [Workshop 5.2](../5-Workshop/5.2-Architecture-Description/) has the full description — request flows, service selection, security, scalability and cost.

{{< mermaid >}}
graph LR
    U1[Mobile App]
    U2[Web Browser]
    U3["Admin Portal"]

    subgraph Edge ["Edge and global"]
        R53["Route 53<br/>DNS"]
        WAF["AWS WAF<br/>optional"]
        CF["Amazon CloudFront<br/>CDN"]
        FE["Amazon S3<br/>frontend bucket"]
    end

    GW["Amazon API Gateway<br/>REST API"]

    subgraph Backend ["Serverless backend, AWS Lambda"]
        AU["Auth"]
        US["User"]
        FI["Fitness"]
        PA["Payment"]
        GY["Gym"]
        AIS["AI"]
    end

    subgraph VPC ["VPC 10.0.0.0/16, ap-southeast-1, multi-AZ"]
        ENI["Private app subnets<br/>Lambda ENI attachment"]
        PROXY["Amazon RDS Proxy<br/>optional"]
        DBA[("Aurora Serverless v2<br/>Primary")]
        DBB[("Aurora Serverless v2<br/>Replica")]
    end

    subgraph Shared ["Shared serverless services"]
        UP["Amazon S3<br/>uploads bucket"]
        SEC["AWS Secrets Manager"]
        CW["Amazon CloudWatch"]
    end

    EB["Amazon EventBridge<br/>schedules and events"]

    subgraph Async ["Async and AI processing"]
        SQS1[["Amazon SQS<br/>job queue"]]
        WRK["Lambda Worker"]
        BR[["Amazon Bedrock<br/>LLM provider"]]
        VEC[("OpenSearch Serverless<br/>vector store")]
    end

    U1 --> CF
    U2 --> CF
    U3 --> CF
    R53 -.-> CF
    R53 -.-> GW
    CF --> WAF
    WAF --> FE
    U1 --> GW
    U2 --> GW
    U3 --> GW

    GW --> AU
    GW --> US
    GW --> FI
    GW --> PA
    GW --> GY
    GW --> AIS

    AU --> ENI
    US --> ENI
    FI --> ENI
    PA --> ENI
    GY --> ENI
    AIS --> ENI
    ENI --> PROXY
    PROXY --> DBA
    DBA -. replication .-> DBB

    AU --> SEC
    US --> UP
    AIS -->|enqueue| SQS1
    SQS1 --> WRK
    WRK --> BR
    WRK --> VEC
    EB -.-> WRK
    ENI --> CW
{{< /mermaid >}}

- **Edge and frontend** — Route 53 for DNS, an optional AWS WAF, and Amazon CloudFront in front of an Amazon S3 frontend bucket.
- **API layer** — a single Amazon API Gateway REST API, with one route group per service (`/auth/*`, `/users/*`, `/fitness/*`, `/payments/*`, `/gyms/*`, `/ai/*`, `/health`).
- **Serverless backend** — six AWS Lambda services (Auth, User, Fitness, Payment, Gym, AI), deployed across multiple Availability Zones by default.
- **Data** — Aurora Serverless v2 (PostgreSQL) with a primary and a replica across two private DB subnets, Multi-AZ replication, and an optional Amazon RDS Proxy in front of it.
- **Shared services** — an S3 uploads bucket, Secrets Manager for credentials, and CloudWatch for logs and metrics.
- **Asynchronous and AI processing** — Amazon EventBridge for schedules and events, Amazon SQS feeding a Lambda worker, which calls Amazon Bedrock for generation and an OpenSearch Serverless vector store for retrieval.
- **DevOps** — GitHub source code, a GitHub Actions CI/CD pipeline authenticating through OIDC, and Terraform as infrastructure as code.
- **Monitoring** — CloudWatch logs, metrics, alarms and dashboards, Amazon SNS for alerts, AWS X-Ray for tracing, and AWS Budgets / Cost Explorer for cost control.
- **Network** — everything outside the Edge and DevOps groups runs in a VPC spread across multiple Availability Zones, with no EC2 instances or containers in this design.

### 4. AWS Services Used {#services}

| Service | Role in the system |
|---|---|
| Amazon S3 | Static frontend hosting; private uploads (presigned URLs); Lambda deployment artifacts; database migration dumps |
| Amazon API Gateway (HTTP API) | Public REST entry point with explicit routes, CORS, AI route throttling and an HTTP proxy to the Chat ALB |
| AWS Lambda | Auth, User, Fitness, Gym, Payment and AI services (HTTP, jobs and worker functions) and per-service schema migrations |
| Amazon ECS on AWS Fargate | Chat service (REST + Socket.IO) and the one-shot database migrator task |
| Amazon ECR | Private container images for Chat and the migrator |
| Elastic Load Balancing (ALB) | Socket.IO/WebSocket entry for Chat, `/health` checks, stickiness, rules hiding internal paths |
| Amazon Aurora PostgreSQL Serverless v2 | Relational data for all services, one logical database each |
| Amazon Bedrock | Nova Pro for chat and vision; Cohere Embed Multilingual v3 for embeddings |
| Amazon OpenSearch Serverless | Vector search for RAG and knowledge retrieval |
| Amazon SQS | AI task queue and dead-letter queue |
| Amazon EventBridge Scheduler | Schedules for settlements, reminders, payouts, reconciliation and AI jobs |
| AWS Secrets Manager | Database credentials, the Chat database URL and the shared internal secret |
| AWS IAM | Per-function execution roles, ECS task/execution roles, scheduler roles |
| Amazon VPC | Network isolation: subnets, route tables, security groups |
| NAT Gateway and Internet Gateway | Outbound internet access for the private subnets |
| VPC interface endpoints | Private access to Secrets Manager and OpenSearch Serverless |
| Amazon CloudWatch Logs | Logs for every function, the Chat task and the migrator |
| AWS Marketplace | One-time subscription to the Cohere model on Bedrock |

### 5. Component Design {#components}

- **Frontend (React/Vite)** — S3 website; REST calls to API Gateway with a Bearer token; Socket.IO to the Chat ALB; user-facing handling of 429/408/504 from the AI routes.
- **Auth service** — registration, verification, login, refresh, logout, user administration; database `fitness_assistant`.
- **User service** — profile, onboarding, InBody records, PT applications, contracts, sessions, availability, notifications; uploads to private S3 prefixes; jobs: session settlement, auto-confirm, reschedule expiry; database `fitness_assistant_user`.
- **Fitness service** — exercises, workouts, nutrition, food, training cycles, coach data, equipment, imports/exports, templates, statistics; jobs: upcoming and unfinished workout reminders; database `fitness_assistant_fitness`.
- **Gym service** — gyms, PT listings, owner and admin tools, collaborations, signed QR check-in; jobs: membership payouts, referral settlement; database `fitness_assistant_gym`.
- **Payment service** — payments, wallet, PT wallet, withdrawals, admin payments, provider callbacks (VNPAY by default; MoMo, PayOS, ZaloPay supported); job: reconciliation every 5 minutes; database `fitness_assistant_payment`.
- **AI service** — HTTP function (`/ai`, `/plans`, `/marketplace`, `/admin/ai`), SQS worker for long generations, jobs function for auto-accept and nightly knowledge ingestion; Bedrock and OpenSearch; database `fitness_assistant_ai`.
- **Chat service** — conversations and real-time messaging on Fargate; database `fitness_assistant_chat`.
- **Migration** — one migration function per service (Prisma `migrate deploy`) and a Fargate task that restored the local data.
- **Aurora cluster** — `fitness-assistant-dev-aurora`, seven logical databases.
- **Vector collection** — `fitness-assistant-dev-ai-vectors` with the `exercises`, `fitness_knowledge`, `fitness_faq` and `fitness_evidence` indexes (1024 dimensions, FAISS/HNSW, cosine similarity).

### 6. Technical Implementation {#implementation}

#### Implementation phases

1. **Analysis and code adaptation** — audit every service; add Lambda HTTP, jobs and migration handlers; read credentials through `DATABASE_SECRET_ID`; replace internal HTTP calls with direct Lambda invokes; add SQS, Bedrock and OpenSearch providers; build artifacts that bundle the Prisma Linux engine.
2. **Shared foundation** — VPC, subnets, security groups, NAT and Internet Gateway, Aurora Serverless v2, Secrets Manager endpoint.
3. **First service and entry points** — Auth Lambda, API Gateway with explicit routes, S3 website, CORS.
4. **Core services** — User, Fitness, Gym and Payment with their jobs functions and schedules, then the Gym ↔ Payment wiring.
5. **AI** — Bedrock models, SQS worker, jobs function, OpenSearch Serverless, knowledge schedules, AI routes with throttling, Payment → AI activation.
6. **Real time and data** — Chat on ECS Fargate behind an ALB; restore of the 7 local databases with a Fargate migrator.
7. **Validation and hardening** — end-to-end tests, alarms, CI/CD, HTTPS with CloudFront, cost "sleep" automation.

The exact console steps for phases 2–6, with screenshots and IAM policies, are in the [Deployment Guide](../5-Workshop/5.4-Deployment-Guide/).

#### Technical requirements

- **Compute** — Lambda Node.js 22.x on x86_64 with 1024 MB; timeouts of 30 s for HTTP, 1 minute for jobs, 300 s for the AI worker, 600 s for AI jobs and up to 15 minutes for migrations; Fargate task of 0.5 vCPU / 1 GB.
- **API** — HTTP API with payload format 2.0; no `/internal/*`, `/metrics` or catch-all routes; throttling of 1 request/s (burst 3) on the AI routes.
- **Data** — Prisma migrations applied per service; one logical database per service; SQS visibility timeout 600 s with a DLQ after 2 receives.
- **AI** — Bedrock in `ap-southeast-1` through the APAC inference profile; 1024-dimension embeddings; OpenSearch FAISS/HNSW with cosine similarity.
- **Security** — least-privilege IAM per function; credentials in Secrets Manager; private subnets and security-group-to-security-group rules; no secrets in artifacts, images or documentation.
- **Operations** — CloudWatch Logs; every manual step documented, to be replaced by a CI/CD pipeline.

### 7. Timeline & Milestones {#timeline}

The internship runs from 3 August to 19 October 2026. Dates below are taken from the resources' creation dates in the deployment runbook.

| Phase | Period | Main activities |
|---|---|---|
| 1. Learning and analysis | August 2026 (weeks 1–3) | AWS fundamentals (FCJ modules), application audit, local run, deployment design |
| 2. Foundation and first service | 26–27 August 2026 (week 4) | VPC and NAT, Aurora, Auth Lambda, API Gateway, S3 frontend; User database and role |
| 3. Core services | 2–8 September 2026 (weeks 5–6) | Fitness (2 Sep), Gym and Payment (8 Sep) with their jobs and schedules |
| 4. AI | 15 September 2026 (week 7) | Bedrock, SQS worker, jobs, OpenSearch Serverless, knowledge schedules, AI routes |
| 5. Chat and data | 22–23 September 2026 (week 8) | Chat on ECS Fargate behind an ALB; migrator image and restore of the 7 databases |
| 6. Validation and report | October 2026 (weeks 10–12) | End-to-end tests and fixes, CI/CD, alarms, cost controls, report and clean-up |

### 8. Budget Estimation {#budget}

Monthly estimate for the DEV environment in `ap-southeast-1` running 24×7 with light test traffic. Figures are approximate on-demand list prices and change over time — confirm them with the [AWS Pricing Calculator](https://calculator.aws/); the account's real bill in Cost Explorer is the reference.

| Cost group | Estimated configuration | Monthly cost (USD) |
|---|---|---|
| NAT Gateway | 1 gateway × 730 h, plus data processed | ~43 + data |
| Aurora PostgreSQL Serverless v2 | 0.5 ACU floor × 730 h (≈365 ACU-hours), small storage | ~45–60 |
| ECS Fargate (Chat) | 0.5 vCPU + 1 GB × 730 h | ~22 |
| Application Load Balancer | 1 ALB × 730 h, low LCU usage | ~20 |
| Public IPv4 addresses | NAT Elastic IP + 2 ALB addresses × 730 h | ~11 |
| Interface VPC endpoints | Secrets Manager and OpenSearch, 2 AZs each | ~30–40 |
| OpenSearch Serverless (NextGen) | 0–2 OCU, scales to 0 when idle | depends on active hours |
| Amazon Bedrock | Nova Pro and Cohere Embed, per token, test volume | ~1–10 |
| AWS Lambda | ~40,000 scheduled invocations + test traffic, 1 GB | ~0 (free tier) |
| API Gateway (HTTP API) | < 1 million requests | ~0–1 |
| Secrets Manager | 9 secrets | ~4 |
| S3, ECR, CloudWatch Logs, SQS, EventBridge | small volumes | ~2–5 |

**Estimated total:** about **USD 190–230 per month** if everything runs 24×7. With the planned sleep mode — Aurora at 0 ACU, the Chat service at 0 tasks and the NAT Gateway removed outside test sessions — about **USD 60–90 per month**. The fixed hourly items (NAT, ALB, Fargate, Aurora floor, endpoints, IPv4) dominate; the usage-based services cost almost nothing at DEV volume.

### 9. Risk Assessment {#risks}

| Risk | Impact | Probability | Mitigation strategy |
|---|---|---|---|
| Idle DEV resources keep billing (NAT, Aurora floor, Fargate, ALB, endpoints) | Medium | High | Sleep mode, AWS Budgets alert, dependency-ordered [clean-up](../5-Workshop/5.7-Cleanup/) |
| Runaway Bedrock usage from a client or frontend bug | Medium | Medium | Route throttling on the AI routes, 429 handling in the frontend, SQS dead-letter queue |
| A secret leaks through screenshots, documents or function configuration | High | Low–Medium | Secrets Manager for credentials, pixel-level redaction of evidence, moving internal secrets from Lambda configuration to Secrets Manager |
| Manual deployments drift or cannot be repeated | Medium | High | Step-by-step runbook with screenshots; CI/CD planned |
| Data migration overwrites or corrupts data | High | Low | Read-only preflight, dumps kept in a private versioned bucket, migration history preserved, foreign-key and row-count verification |
| Single Chat task and HTTP-only endpoints | Medium | Medium | Acceptable for DEV; shared Socket.IO adapter before scaling; domain, ACM certificate and CloudFront for HTTPS |

Costs and errors are reviewed in Cost Explorer and CloudWatch Logs after each test session until alarms are in place.

If something goes wrong, the frontend can be rolled back from its S3 backup, a Lambda can be re-uploaded with its previous artifact, a Fargate service can be pointed back to an earlier task definition revision, and the databases can be rebuilt from the migration dumps.

### 10. Expected Outcomes {#outcomes}

**Immediate results:** a working DEV environment on AWS for the whole application — frontend, six Lambda services, real-time chat, managed AI and the restored data — with a reproducible deployment guide and recorded verification results ([Workshop 5.5](../5-Workshop/5.5-Test-Validation/)).

**Technical learning:** practical experience with serverless design on Lambda, API Gateway and EventBridge; containers on ECS Fargate and ECR; Aurora Serverless and data migration; managed AI with Bedrock and OpenSearch Serverless; and the network and IAM boundaries that keep all of it private and least-privilege.

**Longer term:** the same design can grow into a production environment by adding a CI/CD pipeline and infrastructure as code, HTTPS with CloudFront and WAF, CloudWatch alarms, auto scaling for Chat with a shared Socket.IO adapter, and separate DEV/production accounts.
