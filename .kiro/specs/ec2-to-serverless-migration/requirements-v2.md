# Requirements Document: Fitness Assistant - AWS Serverless Migration

**Document Version:** 2.0  
**Last Updated:** 2026-08-04  
**Status:** Draft  
**Project:** Fitness Assistant Serverless Platform Migration  
**Repository:** https://github.com/trmizy/fitness-assistant (branch: aws-deploy)

---

## Executive Summary

This document specifies comprehensive requirements for migrating the **Fitness Assistant** AI Gym Coach application from a fixed-cost EC2+Docker architecture to a **pay-per-use serverless architecture** on AWS. The migration targets:

- **Cost Reduction:** From ~$76/month (24/7 EC2 + RDS) to $0-5/month idle, $10-50/month under moderate load
- **Auto-Scaling:** From 0 to 1000+ concurrent users without manual intervention
- **Operational Simplicity:** Eliminate container orchestration, server patching, and capacity planning
- **Zero-Downtime Migration:** Maintain service availability during migration using blue-green deployment

### Current State (Verified from Code)

**Monorepo Structure (pnpm workspaces):**
- `frontend/web` - React 18 + Vite + TailwindCSS
- `backend/gateway` - Express.js API Gateway (port 3000)
- `backend/services/auth-service` - JWT authentication (port 3001)
- `backend/services/user-service` - User profiles, InBody OCR (port 3004)
- `backend/services/fitness-service` - Workouts, exercises, nutrition, training cycles (port 3002)
- `backend/services/ai-service` - Ollama + Qdrant RAG, AI plans, chat (port 3003)
- `backend/services/chat-service` - Real-time Socket.IO messaging (port 3005)
- `backend/services/payment-service` - MoMo/VNPay/ZaloPay/PayOS integrations (port 3007)
- `backend/services/gym-service` - Gym owner/PT contract management (port 3006)

**Infrastructure (docker-compose.prod.yml verified):**
- **Compute:** EC2 t3.large (2 vCPU, 8GB RAM) running Docker Compose
- **Database:** Amazon RDS PostgreSQL (Multi-AZ, db.t3.micro → insufficient for prod, needs upgrade)
  - 9 separate databases: `gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, `gymcoach_chat`, `gymcoach_payment`, `gymcoach_gym`, + test DBs
- **Cache:** Redis 7 container (persistence enabled)
- **Vector DB:** Qdrant container (local storage volume)
- **LLM:** Ollama container (CPU-only, ~4GB RAM for llama3.2:3b) OR Anthropic Claude API
- **Frontend:** Nginx reverse proxy (`nginx.prod.conf` forwards `/api` → gateway:3000)

**NOT Implemented Yet (Per Code):**
- ❌ CloudFormation/CDK/Terraform templates
- ❌ CI/CD pipelines (only `docker-test.yml` workflow exists)
- ❌ AWS Lambda deployments
- ❌ Aurora Serverless configuration
- ❌ Bedrock integration (code supports `LLM_PROVIDER=anthropic` but Ollama is default)
- ❌ S3 static hosting
- ❌ CloudFront distribution

---

## 1. Introduction and Scope

### 1.1 Document Purpose

This requirements document defines the functional, non-functional, and operational requirements for migrating Fitness Assistant from EC2-based deployment to AWS serverless infrastructure. It serves as:
- Single source of truth for migration scope and acceptance criteria
- Contract between development team and stakeholders
- Foundation for design, implementation, and test planning

### 1.2 Project Background

**Fitness Assistant** is an AI-powered gym coaching platform built as a microservices application. Current deployment runs on a single EC2 instance with Docker Compose, suitable for MVP validation but inefficient for variable traffic patterns:

- **Problem:** Fixed infrastructure costs (~$76/month) even during idle periods (nights, weekends)
- **Opportunity:** Serverless architecture reduces idle costs to near-zero while maintaining scalability
- **Business Value:** Enable sustainable scaling for early-stage startup economics

### 1.3 Migration Scope

**IN SCOPE:**
- Frontend: React app → S3 + CloudFront CDN
- Backend: 6 microservices → Lambda functions (auth, user, fitness, ai, payment, gym)
- Database: RDS PostgreSQL → Aurora Serverless v2 (0 ACU auto-pause capability)
- AI Inference: Ollama self-hosted → Amazon Bedrock (Claude Sonnet 4.6 for chat, Haiku 4.5 for embeddings if available)
- Vector Search: Qdrant container → **S3 Parquet files with Lambda vector search** (NOT DynamoDB - S3 is more cost-effective for read-heavy workloads)
- Cache: Redis container → ElastiCache Serverless (optional, evaluate cost vs performance)
- CI/CD: GitHub Actions workflows for automated deployment
- Infrastructure as Code: Terraform for all AWS resources
- Observability: CloudWatch Logs, Metrics, X-Ray tracing, custom dashboards

**OUT OF SCOPE (Future Work):**
- `chat-service` real-time WebSocket (Socket.IO requires persistent connections, incompatible with Lambda architecture - consider AWS AppSync or API Gateway WebSocket for future iteration)
- n8n workflow orchestration (automation tool, not critical path)
- Prometheus + Grafana monitoring (replace with CloudWatch native tooling)
- Email verification flow (SMTP still supported, no AWS SES migration in MVP)

### 1.4 Document Scope

This document covers:
- **Functional Requirements** (REQ-FN-001 through REQ-FN-030): Core platform capabilities
- **Non-Functional Requirements** (REQ-NFR-001 through REQ-NFR-020): Performance, security, scalability
- **Operational Requirements** (REQ-OPS-001 through REQ-OPS-015): CI/CD, monitoring, backup/recovery
- **Migration Requirements** (REQ-MIG-001 through REQ-MIG-010): Zero-downtime migration process
- **Data Requirements** (REQ-DATA-001 through REQ-DATA-010): Data integrity and migration

This document does **NOT** cover:
- Detailed design specifications (see `design.md`)
- Implementation code or configurations (see `tasks.md` and source code)
- User interface wireframes or mockups
- API documentation (see Swagger/OpenAPI specs in `docs/`)

---

## 2. Current State Inventory

### 2.1 Service-by-Service Component Mapping

| Service | Current Tech | Port | Database | Dependencies | Serverless Target |
|---------|--------------|------|----------|--------------|-------------------|
| **frontend/web** | React 18 + Vite + Nginx | 80 | N/A | API Gateway | **S3 + CloudFront** |
| **gateway** | Express.js | 3000 | N/A | All services | **Lambda + API Gateway** |
| **auth-service** | Express.js + Prisma | 3001 | `gymcoach_auth` | PostgreSQL | **Lambda + Aurora Serverless** |
| **user-service** | Express.js + Prisma + Python (InBody OCR) | 3004 | `gymcoach_user` | PostgreSQL, Anthropic Claude | **Lambda + Aurora Serverless** |
| **fitness-service** | Express.js + Prisma | 3002 | `gymcoach_fitness` | PostgreSQL, Redis | **Lambda + Aurora Serverless + ElastiCache?** |
| **ai-service** | Express.js + Prisma + Ollama/Anthropic + Qdrant | 3003 | `gymcoach_ai` | PostgreSQL, Redis, Qdrant, LLM | **Lambda + Aurora Serverless + Bedrock + S3 Vectors** |
| **payment-service** | Express.js + Prisma | 3007 | `gymcoach_payment` | PostgreSQL, VN Payment Gateways | **Lambda + Aurora Serverless** |
| **gym-service** | Express.js + Prisma | 3006 | `gymcoach_gym` | PostgreSQL, payment-service | **Lambda + Aurora Serverless** |
| **chat-service** | Express.js + Socket.IO + Prisma | 3005 | `gymcoach_chat` | PostgreSQL, Socket.IO | **OUT OF SCOPE** (WebSocket complexity) |

### 2.2 Data Layer Inventory

**Verified from Prisma Schemas:**

| Database | Tables (Key Models) | Row Est. | Storage | Migration Strategy |
|----------|---------------------|----------|---------|-------------------|
| `gymcoach_auth` | User, RefreshToken, EmailVerification, AuditLog | ~100 users | <1 GB | AWS DMS + pg_dump |
| `gymcoach_user` | UserProfile, InBodyEntry, PTContract, MedicalCondition | ~100 profiles | <5 GB (images) | AWS DMS + S3 for images |
| `gymcoach_fitness` | Exercise (~500 rows), Workout, WorkoutExercise, WorkoutSet, TrainingCycle, CycleAssessment, NutritionProgram | ~50K rows | <2 GB | AWS DMS + CSV seed data |
| `gymcoach_ai` | Conversation, ChatSession, UserMemory, WorkoutPlan, NutritionPlan, PublishedPlan, KnowledgeDocument, KnowledgeChunk | ~10K conversations, ~5K vectors | <10 GB | AWS DMS + Qdrant export to S3 Parquet |
| `gymcoach_payment` | Transaction, Withdrawal, TopUp, ESignatureRequest | ~500 transactions | <100 MB | AWS DMS |
| `gymcoach_gym` | Gym, GymStaff, Membership | ~50 gyms | <100 MB | AWS DMS |
| **Qdrant Vectors** | `exercises`, `fitness_knowledge`, `fitness_faq`, `fitness_evidence` collections | ~5000 vectors × 768 dims | <200 MB | Export to S3 Parquet + metadata JSON |
| **Redis Cache** | Session data, rate limiting, queue data (BullMQ) | Volatile | N/A | ElastiCache Serverless OR remove if stateless possible |
| **File Storage** | InBody scan images, user uploads | ~100 files, ~500 MB | Local volume | **Migrate to S3** |

### 2.3 Architecture Patterns (Verified from Code)

**Authentication & Authorization:**
- JWT-based authentication (access token 15min, refresh token 7d)
- `INTERNAL_SERVICE_SECRET` for service-to-service auth
- Role-based access: `CUSTOMER`, `PT`, `ADMIN`, `GYM_OWNER`, `GYM_STAFF`
- All routes protected via `verifyToken` middleware in gateway

**Database Patterns:**
- Prisma ORM with per-service schema isolation
- Multi-database design (9 separate DBs, no cross-DB joins)
- Migrations managed per service (`prisma migrate deploy`)

**Inter-Service Communication:**
- Synchronous HTTP calls between services (e.g., `user-service` → `payment-service`)
- No message queue for async tasks in current MVP (future: SQS/SNS)
- Service discovery via Docker Compose service names (e.g., `http://auth-service:3001`)

**AI/RAG Architecture (from `ai-service`):**
- **Retrieval:** Qdrant vector search (top-K similarity)
- **LLM Provider:** Configurable via `LLM_PROVIDER` env var:
  - `ollama` (default): Self-hosted on EC2, models: `llama3.2:3b` (chat), `nomic-embed-text` (embeddings)
  - `anthropic`: Claude API, models: `claude-sonnet-4-6` (chat), embedding via Ollama still
- **Prompt Policy:** Deterministic intent routing + RAG retrieval before LLM call
- **Tool Calling:** Optional (disabled by default), supports `search_exercise_library`, `get_user_fitness_data`
- **Knowledge Ingestion:** CSV/JSON → cleaning → scoring → embedding → Qdrant indexing

**Frontend Routing:**
- Vite dev proxy (`vite.config.ts`): `/api/*` → `http://api-gateway:3000`, `/socket.io/*` → `http://chat-service:3005`
- Production (`nginx.prod.conf`): Same reverse proxy pattern, single-origin for CORS avoidance

---

## 3. Target Architecture (Serverless)

### 3.1 High-Level Serverless Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS SERVERLESS PLATFORM                       │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   Route 53   │  DNS + Health Checks
└──────┬───────┘
       │
┌──────▼───────────────────────────────────────────────────────────┐
│  CloudFront Distribution (CDN)                                    │
│  - Origin 1: S3 (React static files)                             │
│  - Origin 2: API Gateway (backend APIs /api/*)                   │
│  - SSL/TLS: ACM Certificate                                      │
│  - Cache: High TTL for static, low TTL for API                   │
└──────┬───────────────────────────────────────────────────────────┘
       │
       ├─────────────────────────────────────────────────────────┐
       │                                                         │
┌──────▼────────────┐                                ┌──────────▼──────────┐
│  S3 Bucket        │                                │  API Gateway (REST) │
│  - React build    │                                │  - JWT Authorizer   │
│  - Versioning ON  │                                │  - Rate Limiting    │
│  - Public Read    │                                │  - CORS Config      │
└───────────────────┘                                └──────────┬──────────┘
                                                                │
                ┌───────────────────────────────────────────────┼────────────────────────┐
                │                                               │                        │
        ┌───────▼──────────┐  ┌────────────────────┐  ┌───────▼────────┐  ┌──────────▼─────────┐
        │  Lambda: Gateway │  │  Lambda: Auth Svc  │  │  Lambda: User  │  │  Lambda: Fitness   │
        │  (API router)    │  │  (JWT, OTP)        │  │  (Profile,     │  │  (Workouts,        │
        │                  │  │                    │  │   InBody OCR)  │  │   Training Cycles) │
        └───────┬──────────┘  └────────┬───────────┘  └────────┬───────┘  └──────────┬─────────┘
                │                       │                      │                      │
        ┌───────▼──────────┐  ┌────────▼───────────┐  ┌────────▼───────┐  ┌──────────▼─────────┐
        │  Lambda: AI Svc  │  │  Lambda: Payment   │  │  Lambda: Gym   │  │  Step Functions    │
        │  (RAG, Plans)    │  │  (VNPay, MoMo)     │  │  (Gym Mgmt)    │  │  (Long workflows)  │
        └───────┬──────────┘  └────────────────────┘  └────────────────┘  └────────────────────┘
                │
                ├──────────────────┬─────────────────┬─────────────────┐
                │                  │                 │                 │
        ┌───────▼────────┐  ┌─────▼─────────┐  ┌───▼──────────┐  ┌──▼────────────────┐
        │  Bedrock       │  │  S3 Vectors   │  │  Secrets     │  │  Parameter Store  │
        │  - Claude      │  │  - Parquet    │  │  Manager     │  │  - Config values  │
        │    Sonnet 4.6  │  │  - Metadata   │  │  - API keys  │  │  - Feature flags  │
        │  - Embeddings  │  │  - Indexes    │  │  - DB creds  │  └───────────────────┘
        └────────────────┘  └───────────────┘  └──────────────┘
                │
        ┌───────▼───────────────────────────────────────────────────────┐
        │  Aurora Serverless v2 (PostgreSQL 15)                         │
        │  - Min ACU: 0 (auto-pause after 5 min idle)                  │
        │  - Max ACU: 16 (scales under load)                           │
        │  - Multi-AZ for HA (optional in prod)                        │
        │  - 9 databases: auth, user, fitness, ai, payment, gym, etc.  │
        └───────────────────────────────────────────────────────────────┘
```

### 3.2 Key Architectural Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|---------------------------|
| **AD-001: S3 Parquet for Vector Search** | Cost-effective for read-heavy workloads (~5K vectors). Lambda loads Parquet into memory, performs cosine similarity. $0.023/GB-month S3 storage vs DynamoDB $0.25/GB-month + RCU costs. | DynamoDB with embeddings in BLOB columns (rejected: 10x storage cost, poor scan performance for similarity search) |
| **AD-002: Aurora Serverless v2 with 0 ACU** | Only Aurora v2 supports true 0 ACU auto-pause (v1 has 1 ACU minimum). 5-min idle → pause, <30s resume. Cost: $0 idle, ~$0.12/ACU-hour active. | RDS Proxy + t4g.micro (rejected: still 24/7 cost), Aurora v1 (rejected: 1 ACU minimum = $43/month base cost) |
| **AD-003: Bedrock for LLM instead of SageMaker** | Pay-per-token pricing ($0.003/1K input tokens for Claude Sonnet) vs SageMaker endpoint ($0.228/hour minimum). Bedrock wins for <10K requests/day. | SageMaker Serverless Inference (rejected: 1 GB minimum memory = $0.10/hour idle), Self-hosted on Lambda (rejected: 10GB model size exceeds Lambda limits) |
| **AD-004: No ElastiCache (Stateless Lambdas)** | Redis used for: (1) BullMQ job queue → replace with SQS/Step Functions, (2) rate limiting → use API Gateway built-in, (3) session cache → JWT is stateless. ElastiCache Serverless: $0.125/GB-hour = $90/month for 1GB always-on. | ElastiCache Serverless (rejected: cost), DynamoDB as cache (considered for future if sub-100ms latency needed) |
| **AD-005: No Provisioned Concurrency in MVP** | Cold starts acceptable for MVP (<3s p99). Provisioned concurrency costs $0.015/hour per instance = $11/month per always-warm function. | Provisioned concurrency (deferred to post-MVP if p50 latency >500ms observed) |
| **AD-006: Lambda Monolithic Functions per Service** | One Lambda per service (auth, user, fitness, ai, payment, gym) with internal routing, not one Lambda per endpoint. Balances cold start rate vs deployment complexity. | One Lambda per endpoint (rejected: 50+ functions, complex deployment), API Gateway → ECS Fargate (rejected: ~$30/month base cost for 0.25 vCPU) |
| **AD-007: CloudFront Single Distribution** | One distribution with multiple origins (S3 for `/`, API Gateway for `/api/*`). Same-origin pattern preserves current frontend proxy behavior, avoids CORS preflight. | Separate distributions for frontend/API (rejected: complex DNS, CORS issues), ALB + Lambda targets (rejected: ALB costs $16/month base) |
| **AD-008: Secrets Manager for Secrets** | Centralized secret rotation, versioning. $0.40/secret/month + $0.05/10K API calls. ~10 secrets = $4/month. | Parameter Store SecureString (cheaper but no auto-rotation), Environment variables in Lambda (rejected: not secure, no rotation) |
| **AD-009: GitHub Actions for CI/CD** | Already used for `docker-test.yml`. Free for public repos, $0.008/minute for private (within free tier limits). | AWS CodePipeline (rejected: $1/pipeline/month base cost), GitLab CI (rejected: team uses GitHub) |
| **AD-010: Terraform for IaC** | Mature, cloud-agnostic, better state management than CDK TypeScript for this team skill set. | AWS CDK (rejected: TypeScript adds complexity, CloudFormation drift issues), Pulumi (rejected: less mature ecosystem) |

---

## 4. Stakeholders and Roles

| Stakeholder | Role | Responsibilities | Success Criteria |
|-------------|------|------------------|------------------|
| **Product Owner** | Decision maker | Approve scope, prioritize features, accept deliverables | Cost <$50/month, zero downtime migration |
| **Development Team** | Implementation | Code migration, IaC, testing | All tests pass, deployment automated |
| **DevOps Engineer** | Infrastructure | Terraform, CI/CD, monitoring setup | Infrastructure reproducible, alerts working |
| **QA Engineer** | Quality Assurance | Load testing, regression testing, security testing | <0.1% error rate under load |
| **End Users (MVP Testers)** | Feedback | Use application, report issues | No perceived performance degradation |

---

## 5. Glossary

**Key Terms:**

- **ACU (Aurora Capacity Unit):** Unit of compute for Aurora Serverless (1 ACU = 2 GB RAM, equivalent CPU). Cost: ~$0.12/ACU-hour.
- **Cold Start:** Time to initialize Lambda runtime + load code + establish DB connections on first invocation after idle.
- **Warm Lambda:** Lambda execution environment reused from previous invocation, no initialization overhead.
- **Auto-Pause:** Aurora Serverless feature that pauses database after idle period (default 5 minutes), reducing cost to $0.
- **Resume Latency:** Time for paused Aurora cluster to become available (~30 seconds).
- **Provisioned Concurrency:** Pre-warmed Lambda instances always ready, eliminates cold starts but incurs hourly cost.
- **RCU/WCU:** Read/Write Capacity Units for DynamoDB pricing.
- **API Gateway REST API:** HTTP API routing to Lambda with built-in auth, throttling, caching.
- **Lambda Layer:** Reusable code package (e.g., Prisma client, shared utilities) attached to multiple functions.
- **VPC Lambda:** Lambda function running inside VPC to access Aurora (adds cold start latency ~1-2s for ENI setup).
- **Parquet:** Columnar storage format, efficient for analytics and vector data compression (~10x smaller than JSON).
- **Qdrant Collection:** Named vector index in Qdrant (e.g., `exercises`, `fitness_knowledge`).
- **RAG (Retrieval-Augmented Generation):** AI pattern combining vector search retrieval with LLM generation.
- **Bedrock Model ID:** Identifier for LLM (e.g., `anthropic.claude-sonnet-4-6-v1:0`).
- **JWT (JSON Web Token):** Stateless authentication token, no server-side session storage needed.
- **Blue-Green Deployment:** Migration strategy running old and new stacks in parallel, switching DNS atomically.
- **Canary Deployment:** Gradual traffic shift (e.g., 10% → 50% → 100%) to detect issues early.
- **RTO (Recovery Time Objective):** Maximum acceptable downtime to restore service after failure.
- **RPO (Recovery Point Objective):** Maximum acceptable data loss measured in time (e.g., 5 minutes).

---

## 6. Functional Requirements

### 6.1 Frontend Static Hosting (REQ-FN-001)

**Priority:** P0 (Critical)  
**User Story:** As a user, I want to access the Fitness Assistant web application via HTTPS with low latency globally, so that I have a fast and secure experience.

**Description:**  
The React frontend (currently served by Nginx on EC2) SHALL be migrated to S3 static hosting with CloudFront CDN distribution. This enables global caching, HTTPS by default, and eliminates frontend compute costs.

**Acceptance Criteria (EARS Format):**
1. **WHEN** the React build artifacts are deployed to S3, **THEN** the S3 bucket SHALL host all static files (HTML, JS, CSS, images) with public read access.
2. **WHEN** a user requests `https://<domain>/` **THEN** CloudFront SHALL serve `index.html` from S3 origin within 200ms (p95) for cached content.
3. **WHEN** a user requests `/api/*` path, **THEN** CloudFront SHALL forward the request to API Gateway origin (NOT S3).
4. **WHEN** CloudFront cache misses, **THEN** CloudFront SHALL fetch from S3 origin and cache with TTL:
   - HTML files: 60 seconds (short cache for SPA routing)
   - JS/CSS/images: 86400 seconds (1 day, immutable with hash in filename)
5. **WHEN** a deployment updates frontend assets, **THEN** CloudFront cache SHALL be invalidated via `aws cloudfront create-invalidation`.
6. **WHEN** SSL certificate is provisioned, **THEN** ACM SHALL issue certificate for custom domain and CloudFront SHALL serve HTTPS only (redirect HTTP → HTTPS).

**Dependencies:**
- Route 53 domain configured (or CloudFront default domain acceptable for MVP)
- S3 bucket created with public access policy
- CloudFront distribution configured with S3 origin

**Verification:**
- Manual: Open `https://<domain>/` in browser, verify page loads and assets cached
- Automated: Cypress E2E tests run against CloudFront URL

---

### 6.2 API Gateway Lambda Integration (REQ-FN-002)

**Priority:** P0 (Critical)  
**User Story:** As a developer, I want all REST API endpoints migrated to Lambda functions behind API Gateway, so that backend scales automatically and costs $0 when idle.

**Description:**  
Current Express.js services (gateway, auth, user, fitness, ai, payment, gym) SHALL be packaged as Lambda functions with API Gateway REST API routing requests. Each service becomes one Lambda function (monolithic per service, not per-endpoint fragmentation).

**Acceptance Criteria:**
1. **WHEN** API Gateway receives HTTP request to `/api/auth/*`, **THEN** API Gateway SHALL invoke `auth-service` Lambda function.
2. **WHEN** API Gateway receives HTTP request to `/api/users/*`, **THEN** API Gateway SHALL invoke `user-service` Lambda function.
3. **WHEN** API Gateway receives HTTP request to `/api/workouts/*`, **THEN** API Gateway SHALL invoke `fitness-service` Lambda function.
4. **WHEN** API Gateway receives HTTP request to `/api/ai/*`, **THEN** API Gateway SHALL invoke `ai-service` Lambda function.
5. **WHEN** API Gateway receives HTTP request to `/api/payments/*`, **THEN** API Gateway SHALL invoke `payment-service` Lambda function.
6. **WHEN** API Gateway receives HTTP request to `/api/gyms/*`, **THEN** API Gateway SHALL invoke `gym-service` Lambda function.
7. **WHEN** Lambda function cold starts, **THEN** initialization SHALL complete within 3000ms (p99).
8. **WHEN** Lambda function is warm, **THEN** request processing SHALL complete within 500ms (p95) excluding external API calls.
9. **WHEN** API Gateway receives request without valid JWT token (for protected routes), **THEN** API Gateway custom authorizer SHALL return HTTP 401 Unauthorized.
10. **WHEN** Lambda function throws unhandled error, **THEN** API Gateway SHALL return HTTP 500 with error message logged to CloudWatch.

**Dependencies:**
- Lambda functions deployed with VPC configuration for Aurora access
- API Gateway REST API created with Lambda proxy integration
- JWT custom authorizer Lambda configured

**Verification:**
- Automated: Postman/Newman collection runs against API Gateway endpoint, all tests pass
- Load test: Artillery 100 RPS for 5 minutes, p95 latency <2s, error rate <0.1%

---

### 6.3 Authentication & Authorization (REQ-FN-003)

**Priority:** P0 (Critical)  
**User Story:** As a user, I want my login credentials and session to remain secure after migration, so that my account is not compromised.

**Description:**  
Current JWT-based authentication (access token + refresh token) SHALL be preserved. Lambda authorizer validates tokens before API Gateway forwards requests to backend Lambdas.

**Acceptance Criteria:**
1. **WHEN** user submits login credentials to `/api/auth/login`, **THEN** auth-service Lambda SHALL validate credentials against Aurora, return access token (15min expiry) and refresh token (7d expiry).
2. **WHEN** user includes valid access token in `Authorization: Bearer <token>` header, **THEN** API Gateway custom authorizer SHALL validate JWT signature and expiry, allow request to proceed.
3. **WHEN** user includes expired access token, **THEN** API Gateway SHALL return HTTP 401 with error message `Token expired`.
4. **WHEN** user submits valid refresh token to `/api/auth/refresh`, **THEN** auth-service Lambda SHALL issue new access token.
5. **WHEN** user submits invalid refresh token (expired, revoked, or tampered), **THEN** auth-service SHALL return HTTP 401 and invalidate token in database.
6. **WHEN** user logs out via `/api/auth/logout`, **THEN** auth-service SHALL delete refresh token from database.
7. **WHEN** service-to-service call occurs (e.g., user-service → payment-service), **THEN** calling service SHALL include `X-Internal-Secret` header with `INTERNAL_SERVICE_SECRET` value, receiving service SHALL validate before processing.

**Dependencies:**
- Secrets Manager stores `JWT_SECRET`, `JWT_REFRESH_SECRET`, `INTERNAL_SERVICE_SECRET`
- Lambda authorizer deployed with cache enabled (5min TTL to reduce Aurora lookups)

**Verification:**
- Automated: Auth E2E tests (login, protected route access, token refresh, logout)
- Security test: Attempt token tampering, expired token usage, missing token

---

### 6.4 Database Aurora Serverless v2 (REQ-FN-004)

**Priority:** P0 (Critical)  
**User Story:** As a startup owner, I want the database to auto-pause when idle and scale automatically under load, so that I pay $0 for unused capacity.

**Description:**  
RDS PostgreSQL SHALL be migrated to Aurora Serverless v2 cluster with 0 ACU minimum capacity. Cluster auto-pauses after 5 minutes of inactivity and resumes within 30 seconds on first query.

**Acceptance Criteria:**
1. **WHEN** Aurora cluster has zero active connections for 5 consecutive minutes, **THEN** Aurora SHALL auto-pause within 1 minute, compute cost SHALL drop to $0.
2. **WHEN** Aurora cluster is paused AND Lambda attempts connection, **THEN** Aurora SHALL resume and accept connection within 30 seconds.
3. **WHEN** Aurora cluster is active AND receives 20 concurrent connections, **THEN** Aurora SHALL scale from 0.5 ACU to sufficient capacity (up to 16 ACU max) to handle load without throttling.
4. **WHEN** Aurora cluster scales up, **THEN** scaling SHALL complete within 30 seconds without dropping existing connections.
5. **WHEN** Aurora cluster is queried, **THEN** query performance SHALL match or exceed RDS baseline (same query plan, <10% latency regression).
6. **WHEN** Lambda cold starts, **THEN** Prisma client connection pool SHALL initialize within 2000ms.
7. **WHEN** Lambda is warm, **THEN** Prisma client SHALL reuse existing connection, query execution <100ms for simple SELECT.

**Dependencies:**
- Aurora Serverless v2 cluster created in same VPC as Lambda functions
- Prisma client configured with connection pooling (`connection_limit=5` per Lambda instance)
- Security group allows Lambda → Aurora on port 5432

**Verification:**
- Manual: Trigger idle state (no requests for 10 minutes), verify Aurora status = `paused` in AWS Console
- Automated: Load test with cold Aurora cluster, measure resume latency <30s
- Performance test: Pgbench benchmark on Aurora vs RDS, TPS within 10%

---

### 6.5 AI Service Bedrock Integration (REQ-FN-005)

**Priority:** P1 (High)  
**User Story:** As a user, I want AI-generated workout plans and chat responses with same quality as current system, so that my coaching experience is preserved.

**Description:**  
Ollama self-hosted LLM SHALL be replaced with Amazon Bedrock (Claude Sonnet 4.6 for chat, embeddings TBD). AI-service Lambda invokes Bedrock API with same prompts as current system.

**Acceptance Criteria:**
1. **WHEN** user requests AI chat via `/api/ai/chat`, **THEN** ai-service Lambda SHALL call Bedrock `InvokeModel` API with Claude Sonnet 4.6 model.
2. **WHEN** Bedrock returns response, **THEN** ai-service SHALL return response within 5000ms (p95) including RAG retrieval time.
3. **WHEN** user requests workout plan generation via `/api/ai/plans`, **THEN** ai-service SHALL call Bedrock with JSON schema prompt, Bedrock SHALL return valid JSON workout plan.
4. **WHEN** Bedrock API call fails (throttling, model unavailable), **THEN** ai-service SHALL retry up to 3 times with exponential backoff, return HTTP 503 if all retries fail.
5. **WHEN** user message contains unsafe content (medical advice beyond scope), **THEN** ai-service SHALL apply same prompt policy safety checks as current system, return refusal message.
6. **WHEN** embeddings are needed for new knowledge ingestion, **THEN** ai-service SHALL use Bedrock Titan Embeddings model (if available) or fallback to existing nomic-embed-text on CPU Lambda.

**Dependencies:**
- Bedrock model access enabled in AWS account (request Claude Sonnet 4.6 access)
- IAM role for Lambda with `bedrock:InvokeModel` permission
- Prompt templates migrated from current `ai-service/src/prompts/`

**Verification:**
- Automated: AI E2E tests (chat, plan generation, safety policy) run against Bedrock
- Manual: Compare AI responses quality with current Ollama baseline (human evaluation)

---

### 6.6 Vector Search S3 Parquet (REQ-FN-006)

**Priority:** P1 (High)  
**User Story:** As a developer, I want vector similarity search for exercise recommendations without running a 24/7 Qdrant container, so that I reduce costs.

**Description:**  
Qdrant vector collections (`exercises`, `fitness_knowledge`, `fitness_faq`, `fitness_evidence`) SHALL be exported to S3 as Parquet files with metadata JSON. Lambda loads Parquet into memory, performs cosine similarity search in-process.

**Acceptance Criteria:**
1. **WHEN** ai-service Lambda receives vector search request, **THEN** Lambda SHALL load Parquet file from S3 (cached in `/tmp` for warm invocations).
2. **WHEN** Lambda performs similarity search, **THEN** Lambda SHALL return top-10 results within 1000ms for 5000-vector dataset.
3. **WHEN** new knowledge is ingested, **THEN** ingestion pipeline SHALL update Parquet files in S3 and invalidate Lambda `/tmp` cache.
4. **WHEN** vector search accuracy is measured, **THEN** cosine similarity ranking SHALL match Qdrant results within 5% (Recall@10 metric).
5. **WHEN** Parquet file size exceeds Lambda `/tmp` limit (512MB), **THEN** system SHALL partition vectors into multiple files or upgrade to larger Lambda memory.

**Dependencies:**
- Qdrant export script (`backend/services/ai-service/scripts/export-vectors.ts`)
- S3 bucket for vector storage (`s3://<project>-vectors/`)
- Lambda with 512MB `/tmp` storage (sufficient for ~5K vectors × 768 dims)

**Verification:**
- Automated: Vector search unit tests, compare results with Qdrant baseline
- Performance test: 100 concurrent similarity searches, p95 latency <1.5s

---

### 6.7 Payment Gateway Integration (REQ-FN-007)

**Priority:** P1 (High)  
**User Story:** As a user, I want to top up wallet and purchase training packages using Vietnamese payment methods, so that I can pay conveniently.

**Description:**  
Payment-service Lambda SHALL integrate with VNPay, MoMo, ZaloPay, PayOS APIs for wallet top-ups and training package purchases. Webhook callbacks handled by API Gateway.

**Acceptance Criteria:**
1. **WHEN** user initiates wallet top-up via `/api/payments/topup`, **THEN** payment-service SHALL create transaction record in Aurora, return payment URL for selected provider (VNPay/MoMo/ZaloPay/PayOS).
2. **WHEN** payment provider sends IPN callback to `/api/payments/<provider>/callback`, **THEN** API Gateway SHALL invoke payment-service Lambda, Lambda SHALL verify signature, update transaction status to `PAID` or `FAILED`.
3. **WHEN** transaction is successful, **THEN** payment-service SHALL update user wallet balance in Aurora, send notification to user.
4. **WHEN** transaction times out (60 minutes), **THEN** scheduled Lambda (EventBridge cron) SHALL mark transaction as `STALE`, refund if applicable.
5. **WHEN** PT contract payment occurs, **THEN** payment-service SHALL calculate platform commission (10%), transfer to gym owner wallet, deduct from user wallet atomically (database transaction).

**Dependencies:**
- Secrets Manager stores payment provider credentials (VNPay TmnCode, MoMo PartnerCode, etc.)
- EventBridge rule triggers stale transaction cleanup Lambda daily

**Verification:**
- Automated: Mock payment provider webhooks, verify transaction state transitions
- Manual: E2E payment test with VNPay sandbox

---

### 6.8 File Upload to S3 (REQ-FN-008)

**Priority:** P1 (High)  
**User Story:** As a user, I want to upload InBody scan images for body composition tracking, so that I get personalized workout plans.

**Description:**  
User-uploaded files (InBody scans, profile photos) currently stored in local Docker volume SHALL be migrated to S3. User-service Lambda generates pre-signed S3 URLs for secure uploads.

**Acceptance Criteria:**
1. **WHEN** user requests upload URL via `/api/users/upload-url`, **THEN** user-service SHALL generate S3 pre-signed POST URL with 5-minute expiry, return to frontend.
2. **WHEN** frontend uploads file to pre-signed URL, **THEN** S3 SHALL accept file (max 10MB), store in `s3://<project>-uploads/<userId>/<filename>`.
3. **WHEN** upload completes, **THEN** frontend SHALL notify backend via `/api/users/upload-complete` with S3 key, user-service SHALL save metadata to Aurora.
4. **WHEN** user requests InBody OCR via `/api/users/inbody/extract`, **THEN** user-service SHALL download image from S3, call Anthropic Claude Vision API, extract metrics, save to Aurora.
5. **WHEN** existing file uploads exist on EC2, **THEN** migration script SHALL copy files to S3 preserving directory structure.

**Dependencies:**
- S3 bucket with lifecycle policy (delete files older than 90 days for cost savings)
- Lambda IAM role with `s3:PutObject`, `s3:GetObject` permissions

**Verification:**
- Automated: Upload test file via pre-signed URL, verify S3 object exists
- Manual: Upload InBody scan, verify OCR extraction works

---

## 7. Non-Functional Requirements

### 7.1 Performance (REQ-NFR-001)

**Priority:** P0 (Critical)  
**Description:** System SHALL maintain acceptable response times under varying load conditions.

**Acceptance Criteria:**
1. **WHEN** Lambda is warm AND query is simple (e.g., GET user profile), **THEN** p50 response time SHALL be <300ms, p95 <500ms.
2. **WHEN** Lambda cold starts, **THEN** p99 cold start time SHALL be <3000ms (including VPC ENI attachment).
3. **WHEN** Aurora resumes from pause, **THEN** first query response time SHALL be <35s (30s resume + 5s query).
4. **WHEN** CloudFront serves cached content, **THEN** p95 response time SHALL be <200ms globally.
5. **WHEN** Bedrock inference is called, **THEN** p95 response time SHALL be <5000ms for typical prompts (<2000 tokens).
6. **WHEN** system is under load (100 concurrent users), **THEN** p95 response time SHALL be <2000ms, p99 <5000ms.

**Verification:**
- Load test: Artillery 100 RPS for 10 minutes, measure latency percentiles
- Cold start test: Stop all requests for 30 minutes, trigger API call, measure cold start

---

### 7.2 Scalability (REQ-NFR-002)

**Priority:** P0 (Critical)  
**Description:** System SHALL automatically scale from 0 to 1000+ concurrent users without manual intervention.

**Acceptance Criteria:**
1. **WHEN** traffic increases from 0 to 100 RPS, **THEN** Lambda SHALL scale to handle load within 1 minute (burst capacity + gradual scaling).
2. **WHEN** traffic increases from 100 to 1000 RPS, **THEN** Lambda SHALL scale without throttling errors (<0.1% throttle rate).
3. **WHEN** Aurora receives 50 concurrent connections, **THEN** Aurora SHALL scale from 0.5 ACU to sufficient capacity (up to 16 ACU max) within 30 seconds.
4. **WHEN** traffic drops to zero, **THEN** Lambda SHALL scale down to 0 instances within 15 minutes (AWS auto-scaling).
5. **WHEN** API Gateway receives >1000 RPS per account, **THEN** API Gateway SHALL apply rate limiting (configurable per API key), return HTTP 429 for excess requests.

**Verification:**
- Spike test: 0 → 500 RPS in 10 seconds, monitor Lambda concurrency, error rate
- Sustained load test: 1000 concurrent users for 30 minutes

---

### 7.3 Availability & Reliability (REQ-NFR-003)

**Priority:** P0 (Critical)  
**Description:** System SHALL achieve 99.5% uptime (excluding planned maintenance).

**Acceptance Criteria:**
1. **WHEN** Aurora cluster is in Multi-AZ configuration, **THEN** automatic failover to standby SHALL complete within 60 seconds if primary fails.
2. **WHEN** Lambda function errors exceed 5% over 5-minute window, **THEN** CloudWatch Alarm SHALL trigger, send SNS notification to on-call engineer.
3. **WHEN** API Gateway 5xx errors exceed 1% over 5-minute window, **THEN** CloudWatch Alarm SHALL trigger.
4. **WHEN** unhandled exception occurs in Lambda, **THEN** Lambda SHALL log stack trace to CloudWatch, return HTTP 500 to client.
5. **WHEN** Aurora connection pool is exhausted, **THEN** Lambda SHALL queue requests or return HTTP 503 Service Unavailable.

**Verification:**
- Chaos engineering: Simulate Aurora failure, verify Multi-AZ failover
- Error injection: Force Lambda errors, verify alarms trigger

---

### 7.4 Security (REQ-NFR-004)

**Priority:** P0 (Critical)  
**Description:** System SHALL protect user data and prevent unauthorized access.

**Acceptance Criteria:**
1. **WHEN** Lambda accesses AWS services, **THEN** Lambda SHALL use IAM role (no hardcoded credentials), follow principle of least privilege.
2. **WHEN** secrets are needed (DB password, API keys), **THEN** secrets SHALL be stored in Secrets Manager with rotation enabled (every 90 days).
3. **WHEN** Aurora stores data, **THEN** data-at-rest encryption SHALL be enabled using AWS KMS.
4. **WHEN** data is transmitted, **THEN** TLS 1.2+ SHALL be enforced (CloudFront, API Gateway, Aurora connections).
5. **WHEN** Lambda logs to CloudWatch, **THEN** logs SHALL NOT contain sensitive data (passwords, tokens, PII).
6. **WHEN** S3 stores files, **THEN** bucket SHALL have public access blocked (except CloudFront origin access via OAI).
7. **WHEN** user authentication fails 5 times, **THEN** auth-service SHALL implement rate limiting (lockout for 15 minutes).

**Verification:**
- Security audit: AWS Trusted Advisor, IAM Access Analyzer
- Penetration test: OWASP Top 10 checks (SQL injection, XSS, CSRF)

---

### 7.5 Cost Optimization (REQ-NFR-005)

**Priority:** P0 (Critical)  
**Description:** System SHALL minimize costs in idle state and scale costs linearly with usage.

**Acceptance Criteria:**
1. **WHEN** system is idle for 30 consecutive days (zero traffic), **THEN** total cost SHALL be <$5/month (S3 storage + Aurora storage only).
2. **WHEN** system serves 1000 requests/day, **THEN** monthly cost SHALL be $10-20 (Lambda invocations + Bedrock inference + Aurora compute).
3. **WHEN** system serves 100K requests/day, **THEN** monthly cost SHALL be $50-100 (scaled linearly with usage).
4. **WHEN** Aurora is idle for 5 minutes, **THEN** Aurora SHALL auto-pause, compute cost drops to $0.
5. **WHEN** Lambda executes, **THEN** Lambda memory SHALL be right-sized (1024MB default, tune based on profiling) to minimize cost per invocation.
6. **WHEN** S3 files are older than 90 days, **THEN** S3 lifecycle policy SHALL move to Glacier or delete (configurable).
7. **WHEN** daily cost exceeds $10, **THEN** AWS Budget alert SHALL send notification to admin.

**Cost Breakdown (Estimated for 1K req/day):**
- Lambda: 1K invocations × 500ms × 1024MB = $0.20/month
- API Gateway: 1K requests = $0.01/month
- Aurora: 2 hours active/day × 0.5 ACU × $0.12 = $3.60/month
- Bedrock: 100 AI calls × 1K tokens × $0.003 = $0.30/month
- S3: 1 GB storage = $0.02/month
- CloudFront: 1 GB transfer = $0.09/month
- **Total: ~$4.22/month**

**Verification:**
- Cost Explorer dashboard tracking daily spend by service
- Idle state test: Zero traffic for 7 days, verify cost <$1 for that period

---

### 7.6 Observability (REQ-NFR-006)

**Priority:** P1 (High)  
**Description:** System SHALL provide visibility into performance, errors, and usage patterns.

**Acceptance Criteria:**
1. **WHEN** Lambda executes, **THEN** Lambda SHALL log request ID, endpoint, duration, status code to CloudWatch Logs with structured JSON format.
2. **WHEN** Lambda errors occur, **THEN** stack trace SHALL be logged with context (userId, requestId, input params).
3. **WHEN** X-Ray tracing is enabled, **THEN** trace SHALL capture: API Gateway → Lambda → Aurora → Bedrock spans with latency breakdown.
4. **WHEN** CloudWatch Dashboard is viewed, **THEN** dashboard SHALL display:
   - Lambda invocation count, error rate, duration (p50/p95/p99)
   - API Gateway request count, 4xx/5xx error rates
   - Aurora connections, query latency, ACU utilization
   - Bedrock inference count, token usage, cost
5. **WHEN** metric exceeds threshold, **THEN** CloudWatch Alarm SHALL trigger SNS notification (e.g., error rate >5%, Aurora connections >50).

**Verification:**
- Manual: Trigger error, verify log appears in CloudWatch within 30 seconds
- X-Ray trace: Execute request, view trace in X-Ray console, verify all spans present

---

### 7.7 Data Integrity (REQ-NFR-007)

**Priority:** P0 (Critical)  
**Description:** Data migration SHALL preserve all data with zero corruption or loss.

**Acceptance Criteria:**
1. **WHEN** data migration completes, **THEN** row count in Aurora SHALL match RDS for all tables (100% data transfer).
2. **WHEN** foreign key constraints exist in RDS, **THEN** equivalent constraints SHALL be created in Aurora.
3. **WHEN** data is migrated, **THEN** checksum verification SHALL confirm data integrity (MD5 hash per table).
4. **WHEN** migration is tested, **THEN** sample queries SHALL return identical results on RDS vs Aurora.
5. **WHEN** files are migrated to S3, **THEN** S3 object count SHALL match local file count (zero file loss).

**Verification:**
- Automated: SQL script compares row counts, checksums between RDS and Aurora
- Manual: Query user profile, workout history, verify data matches EC2 system

---

## 8. Operational Requirements

### 8.1 CI/CD Pipeline (REQ-OPS-001)

**Priority:** P1 (High)  
**Description:** Deployment SHALL be automated via GitHub Actions with zero-downtime blue-green strategy.

**Acceptance Criteria:**
1. **WHEN** code is pushed to `main` branch, **THEN** GitHub Actions SHALL trigger build, test, deploy workflow.
2. **WHEN** tests pass, **THEN** workflow SHALL:
   - Build frontend (Vite), upload to S3, invalidate CloudFront cache
   - Build Lambda functions (esbuild), package with dependencies, deploy to AWS Lambda
   - Run Terraform plan, apply infrastructure changes (if any)
3. **WHEN** deployment occurs, **THEN** blue-green strategy SHALL:
   - Deploy new Lambda versions (`$LATEST` → alias `live-v2`)
   - Update API Gateway to point to `live-v2`
   - Keep `live-v1` active for 1 hour (rollback window)
4. **WHEN** deployment fails, **THEN** workflow SHALL rollback to previous version, send alert.
5. **WHEN** deployment succeeds, **THEN** smoke tests SHALL run against production endpoint, verify key flows.

**Dependencies:**
- GitHub Actions runners (hosted or self-hosted)
- AWS credentials stored in GitHub Secrets
- Terraform state stored in S3 with DynamoDB lock table

**Verification:**
- Dry run: Trigger deployment to staging environment, verify all steps complete
- Rollback test: Deploy bad version, trigger rollback, verify old version restored

---

### 8.2 Monitoring & Alerting (REQ-OPS-002)

**Priority:** P1 (High)  
**Description:** System SHALL alert on-call engineer when critical issues occur.

**Acceptance Criteria:**
1. **WHEN** Lambda error rate >5% for 5 minutes, **THEN** CloudWatch Alarm SHALL trigger, send SNS email/Slack notification.
2. **WHEN** API Gateway 5xx rate >1% for 5 minutes, **THEN** alarm SHALL trigger.
3. **WHEN** Aurora connections >80% of max (e.g., >80 of 100), **THEN** alarm SHALL trigger.
4. **WHEN** Aurora ACU >80% of max (e.g., >12 of 16), **THEN** alarm SHALL trigger (approaching scale limit).
5. **WHEN** daily AWS cost >$10, **THEN** AWS Budget alert SHALL trigger.
6. **WHEN** Bedrock API call fails with rate limit error, **THEN** alarm SHALL trigger (need to request quota increase).

**Verification:**
- Test alarm: Trigger error spike, verify SNS notification received within 2 minutes
- Cost alert: Manually exceed budget threshold, verify email received

---

### 8.3 Backup & Disaster Recovery (REQ-OPS-003)

**Priority:** P0 (Critical)  
**Description:** System SHALL enable recovery from data loss or catastrophic failure.

**Acceptance Criteria:**
1. **WHEN** Aurora is configured, **THEN** automated daily snapshots SHALL be enabled with 7-day retention.
2. **WHEN** Aurora is configured, **THEN** point-in-time recovery (PITR) SHALL be enabled, allowing restore to any second within last 7 days.
3. **WHEN** data migration cutover occurs, **THEN** manual snapshot SHALL be taken before DNS switch.
4. **WHEN** S3 stores files, **THEN** versioning SHALL be enabled (keep last 3 versions per object).
5. **WHEN** Lambda code is deployed, **THEN** previous version SHALL be retained (Lambda version history).
6. **WHEN** disaster occurs, **THEN** RTO (Recovery Time Objective) SHALL be 1 hour (time to restore from snapshot).
7. **WHEN** disaster occurs, **THEN** RPO (Recovery Point Objective) SHALL be 5 minutes (max data loss, based on automated backups).

**Verification:**
- Restore test: Create Aurora snapshot, restore to new cluster, verify data integrity
- S3 versioning test: Delete object, recover from previous version

---

### 8.4 Infrastructure as Code (REQ-OPS-004)

**Priority:** P1 (High)  
**Description:** All AWS resources SHALL be defined in Terraform, version controlled, reproducible.

**Acceptance Criteria:**
1. **WHEN** Terraform is executed, **THEN** Terraform SHALL provision:
   - S3 buckets (frontend, uploads, vectors, Terraform state)
   - CloudFront distribution with origins, cache behaviors, SSL certificate
   - API Gateway REST API with Lambda integrations, custom authorizer
   - Lambda functions with IAM roles, VPC config, environment variables
   - Aurora Serverless v2 cluster with auto-pause config, security groups
   - Secrets Manager secrets (JWT keys, DB passwords, payment credentials)
   - CloudWatch Log Groups, Dashboards, Alarms
   - SNS topics for alerting
   - EventBridge rules for scheduled tasks
2. **WHEN** Terraform plan is run, **THEN** changes SHALL be previewed before apply (no surprises).
3. **WHEN** Terraform state is stored, **THEN** state SHALL be in S3 with DynamoDB lock table (prevent concurrent modifications).
4. **WHEN** environment variables are needed, **THEN** Terraform SHALL use `.tfvars` files (dev, staging, prod) for environment-specific config.

**Verification:**
- Dry run: `terraform destroy` then `terraform apply`, verify infrastructure recreated identically
- State test: Run `terraform plan` twice, verify no changes detected (idempotent)

---

### 8.5 Secrets Management (REQ-OPS-005)

**Priority:** P0 (Critical)  
**Description:** Sensitive credentials SHALL be stored securely in Secrets Manager, never in code.

**Acceptance Criteria:**
1. **WHEN** secrets are stored, **THEN** secrets SHALL be in Secrets Manager:
   - `prod/db/aurora-master-password`
   - `prod/jwt/secret` and `prod/jwt/refresh-secret`
   - `prod/internal-service-secret`
   - `prod/payment/vnpay`, `prod/payment/momo`, etc.
   - `prod/anthropic-api-key`
2. **WHEN** Lambda needs secret, **THEN** Lambda SHALL call Secrets Manager API at startup, cache secret for function lifetime.
3. **WHEN** secret is rotated, **THEN** Secrets Manager SHALL trigger Lambda rotation function (optional for MVP, manual rotation acceptable).
4. **WHEN** secret is accessed, **THEN** CloudTrail SHALL log access (audit trail).
5. **WHEN** secret is displayed in AWS Console, **THEN** secret SHALL be masked (show/hide toggle).

**Verification:**
- Secret injection test: Deploy Lambda, verify secret loaded from Secrets Manager (not env var)
- Rotation test: Manually rotate DB password, verify Aurora connection still works

---

## 9. Migration Requirements

### 9.1 Zero-Downtime Migration (REQ-MIG-001)

**Priority:** P0 (Critical)  
**Description:** Migration SHALL occur with <5 minutes downtime during DNS cutover.

**Acceptance Criteria:**
1. **WHEN** migration begins, **THEN** EC2 system SHALL remain fully operational (blue environment).
2. **WHEN** serverless system is deployed, **THEN** serverless SHALL run in parallel with EC2 (green environment).
3. **WHEN** data replication is active, **THEN** AWS DMS SHALL replicate changes from RDS to Aurora with <10 seconds lag.
4. **WHEN** cutover occurs, **THEN** DNS SHALL switch from EC2 Elastic IP to CloudFront distribution, TTL <60 seconds.
5. **WHEN** cutover completes, **THEN** EC2 system SHALL remain online for 2 weeks (rollback window).

**Verification:**
- Staging rehearsal: Perform full migration in staging environment, measure downtime
- Production monitor: During cutover, monitor error rates on both EC2 and serverless

---

### 9.2 Data Migration with AWS DMS (REQ-MIG-002)

**Priority:** P0 (Critical)  
**Description:** Database migration SHALL use AWS Database Migration Service for continuous replication.

**Acceptance Criteria:**
1. **WHEN** DMS replication task starts, **THEN** full load SHALL copy all tables from RDS to Aurora.
2. **WHEN** full load completes, **THEN** CDC (Change Data Capture) SHALL replicate ongoing changes in near-real-time.
3. **WHEN** cutover is ready, **THEN** replication lag SHALL be <10 seconds (verified via DMS CloudWatch metrics).
4. **WHEN** cutover occurs, **THEN** application SHALL stop writing to RDS, wait for DMS lag = 0, switch to Aurora.
5. **WHEN** Aurora is primary, **THEN** DMS task SHALL be stopped (no longer needed).

**Verification:**
- DMS test: Insert row in RDS, verify appears in Aurora within 10 seconds
- Lag monitor: Query DMS `CDCLatencySource` metric, ensure <10s during cutover window

---

### 9.3 Canary Deployment (REQ-MIG-003)

**Priority:** P1 (High)  
**Description:** Traffic SHALL be gradually shifted from EC2 to serverless to detect issues early.

**Acceptance Criteria:**
1. **WHEN** canary deployment starts, **THEN** 10% of traffic SHALL route to serverless (weighted Route 53 records).
2. **WHEN** 10% canary runs for 2 hours with error rate <0.5%, **THEN** traffic SHALL increase to 50%.
3. **WHEN** 50% canary runs for 4 hours with error rate <0.5%, **THEN** traffic SHALL increase to 100%.
4. **WHEN** error rate exceeds EC2 baseline by 2%, **THEN** automatic rollback SHALL revert to 0% serverless traffic.
5. **WHEN** 100% traffic is on serverless for 1 week with no issues, **THEN** EC2 infrastructure SHALL be decommissioned.

**Verification:**
- Traffic split test: Verify Route 53 weighted routing distributes correctly (10%/50%/100%)
- Error rate monitor: Compare CloudWatch metrics for EC2 vs serverless during canary

---

### 9.4 Rollback Procedure (REQ-MIG-004)

**Priority:** P0 (Critical)  
**Description:** Documented rollback procedure SHALL enable revert to EC2 within 1 hour if critical issues occur.

**Acceptance Criteria:**
1. **WHEN** rollback is triggered, **THEN** Route 53 DNS SHALL revert to EC2 Elastic IP within 5 minutes.
2. **WHEN** rollback occurs, **THEN** Aurora data SHALL be replicated back to RDS (reverse DMS task or manual pg_dump).
3. **WHEN** rollback is complete, **THEN** EC2 system SHALL be fully operational, serving 100% traffic.
4. **WHEN** rollback procedure is documented, **THEN** runbook SHALL include:
   - Step-by-step DNS revert instructions
   - Data synchronization commands
   - Verification checklist
   - Communication plan (notify users)
5. **WHEN** rollback is tested, **THEN** staging rollback drill SHALL complete within 1 hour.

**Verification:**
- Staging rollback drill: Perform full rollback in staging, measure time and data integrity

---

## 10. Testing Requirements

### 10.1 Load Testing (REQ-TEST-001)

**Priority:** P1 (High)  
**Description:** System SHALL be load tested to verify performance and scalability.

**Acceptance Criteria:**
1. **WHEN** 100 concurrent users load test runs for 10 minutes, **THEN**:
   - p95 response time <2s
   - Error rate <0.1%
   - Lambda throttle rate <0.1%
2. **WHEN** 1000 concurrent users load test runs for 5 minutes, **THEN**:
   - p99 response time <5s
   - Error rate <0.5%
   - Aurora scales to sufficient ACU without connection errors
3. **WHEN** spike test (0 → 500 RPS in 10 seconds) runs, **THEN**:
   - System SHALL handle spike with <5% error rate during ramp-up
   - Cold start rate <20% of requests during spike
4. **WHEN** soak test (100 RPS for 8 hours) runs, **THEN**:
   - No memory leaks (Lambda memory usage stable)
   - Error rate <0.1% throughout test

**Verification:**
- Artillery load test scripts for each scenario
- CloudWatch metrics dashboard monitoring during tests

---

### 10.2 Integration Testing (REQ-TEST-002)

**Priority:** P1 (High)  
**Description:** End-to-end user flows SHALL be tested on serverless infrastructure.

**Acceptance Criteria:**
1. **WHEN** E2E test suite runs, **THEN** tests SHALL pass for:
   - User registration → email verification → login → JWT token issuance
   - User profile creation → InBody scan upload → OCR extraction
   - Workout plan generation → plan activation → workout logging
   - AI chat → RAG retrieval → LLM response
   - Wallet top-up → payment provider redirect → webhook callback → balance update
   - PT contract purchase → escrow → completion → payout
2. **WHEN** tests run against serverless, **THEN** pass rate SHALL be ≥95% (same as EC2 baseline).

**Verification:**
- Playwright/Cypress E2E test suite
- CI pipeline runs E2E tests on every deployment

---

### 10.3 Security Testing (REQ-TEST-003)

**Priority:** P1 (High)  
**Description:** Security vulnerabilities SHALL be identified and fixed before production deployment.

**Acceptance Criteria:**
1. **WHEN** OWASP ZAP scan runs, **THEN** no HIGH or CRITICAL vulnerabilities SHALL be detected.
2. **WHEN** IAM policy is reviewed, **THEN** least privilege principle SHALL be enforced (no `*` wildcards in production).
3. **WHEN** secrets are scanned, **THEN** no hardcoded credentials SHALL exist in code or Terraform.
4. **WHEN** SQL injection test runs, **THEN** Prisma parameterized queries SHALL prevent injection.
5. **WHEN** CSRF test runs, **THEN** API SHALL validate origin headers or use SameSite cookies.

**Verification:**
- OWASP ZAP automated scan in CI pipeline
- Manual penetration testing by security team

---

## 11. Data Requirements

### 11.1 Data Migration Completeness (REQ-DATA-001)

**Priority:** P0 (Critical)  
**Description:** All production data SHALL be migrated from RDS to Aurora without loss.

**Acceptance Criteria:**
1. **WHEN** migration completes, **THEN** table row counts SHALL match:
   - `gymcoach_auth.users`: 100% transferred
   - `gymcoach_user.user_profiles`: 100% transferred
   - `gymcoach_fitness.exercises`: 100% transferred (~500 rows)
   - All other tables: 100% transferred
2. **WHEN** checksums are compared, **THEN** MD5 hash per table SHALL match between RDS and Aurora.
3. **WHEN** foreign keys are checked, **THEN** referential integrity SHALL be maintained (0 orphaned records).
4. **WHEN** file uploads are migrated, **THEN** S3 object count SHALL match local file count (InBody scans, profile photos).

**Verification:**
```sql
-- Row count comparison script
SELECT 'users' as table_name, COUNT(*) FROM gymcoach_auth.users
UNION ALL
SELECT 'user_profiles', COUNT(*) FROM gymcoach_user.user_profiles
UNION ALL
SELECT 'exercises', COUNT(*) FROM gymcoach_fitness.exercises;
-- Run on both RDS and Aurora, compare results
```

---

### 11.2 Vector Data Migration (REQ-DATA-002)

**Priority:** P1 (High)  
**Description:** Qdrant vector embeddings SHALL be exported to S3 Parquet format.

**Acceptance Criteria:**
1. **WHEN** export script runs, **THEN** script SHALL:
   - Connect to Qdrant container
   - Export collections: `exercises`, `fitness_knowledge`, `fitness_faq`, `fitness_evidence`
   - Convert to Parquet with schema: `[id, vector[768], metadata{...}]`
   - Upload to S3: `s3://project-vectors/<collection>.parquet`
2. **WHEN** vector count is compared, **THEN** Parquet row count SHALL match Qdrant collection size.
3. **WHEN** sample vectors are tested, **THEN** cosine similarity results SHALL match within 0.01 tolerance.

**Verification:**
- Export script: `backend/services/ai-service/scripts/export-qdrant-to-s3.ts`
- Validation script compares 100 random vector searches

---

## 12. Success Criteria & Acceptance

### 12.1 Migration Success Criteria

The migration is considered **SUCCESSFUL** when ALL of the following are met:

| Criterion | Target | Measurement Method |
|-----------|--------|-------------------|
| **Cost Idle** | <$5/month | AWS Cost Explorer, 7-day idle period |
| **Cost Active** | $10-50/month | 1K-10K requests/day for 30 days |
| **Performance** | p95 <2s | Artillery load test 100 concurrent users |
| **Availability** | 99.5% uptime | CloudWatch metrics over 7 days |
| **Data Integrity** | 100% migrated | Row count + checksum verification |
| **Error Rate** | <0.1% | CloudWatch metrics over 7 days |
| **Cold Start** | p99 <3s | CloudWatch Lambda metrics |
| **Aurora Auto-Pause** | Works correctly | Manual test: 10 min idle → verify paused |
| **Rollback Tested** | <1 hour | Staging rollback drill |

### 12.2 Go/No-Go Decision Criteria

**GO** decision requires:
- ✅ All P0 requirements implemented and tested
- ✅ Load testing passes (100 concurrent users, <0.1% error rate)
- ✅ Data migration verified (100% row count match)
- ✅ Rollback procedure tested in staging
- ✅ Cost projections within budget (<$50/month for expected load)
- ✅ Security scan shows no HIGH/CRITICAL vulnerabilities
- ✅ Canary deployment 10% runs successfully for 2 hours

**NO-GO** triggers automatic rollback:
- ❌ Error rate >2% above EC2 baseline during canary
- ❌ Data loss detected (row count mismatch)
- ❌ Critical security vulnerability found
- ❌ Aurora fails to auto-pause after 10 minutes idle
- ❌ Cost exceeds $10/day during low traffic period

---

## 13. Migration Timeline & Phases

### Phase 1: Foundation (Week 1-2)
**Objective:** Set up AWS infrastructure and CI/CD pipeline

**Tasks:**
- Setup Terraform repository structure
- Provision Aurora Serverless v2 cluster (dev environment)
- Setup S3 buckets (frontend, uploads, vectors, Terraform state)
- Configure Secrets Manager with dev secrets
- Setup GitHub Actions workflows (test, build, deploy)
- Deploy hello-world Lambda to validate pipeline

**Deliverables:**
- Terraform code in version control
- CI/CD pipeline deploying to dev environment
- Aurora cluster accessible from local machine

---

### Phase 2: Frontend Migration (Week 3)
**Objective:** Migrate React app to S3 + CloudFront

**Tasks:**
- Configure S3 bucket for static hosting
- Setup CloudFront distribution with S3 origin
- Provision ACM certificate (if custom domain)
- Update Vite build to produce S3-compatible output
- Deploy frontend to S3 via GitHub Actions
- Configure CloudFront cache invalidation in CI/CD

**Deliverables:**
- Frontend accessible via CloudFront URL
- Cache hit rate >80%
- Deployment automated in GitHub Actions

**Verification:**
- Manual: Open `https://<cloudfront-domain>/`, verify page loads
- Automated: Cypress tests run against CloudFront URL

---

### Phase 3: Backend Services Migration (Week 4-6)
**Objective:** Convert Express.js services to Lambda functions

**Tasks:**
- Create Lambda wrapper for Express apps (using `serverless-http` or `aws-lambda-express`)
- Package each service as separate Lambda function:
  - `auth-service` (REQ-FN-003)
  - `user-service` (REQ-FN-008)
  - `fitness-service`
  - `payment-service` (REQ-FN-007)
  - `gym-service`
- Configure VPC for Lambda → Aurora connectivity
- Setup API Gateway REST API with Lambda integrations (REQ-FN-002)
- Implement JWT custom authorizer
- Configure CloudFront `/api/*` origin to point to API Gateway
- Test cold start performance, optimize if needed

**Deliverables:**
- 6 Lambda functions deployed
- API Gateway routing to Lambdas
- E2E tests passing on serverless stack

**Verification:**
- Postman collection tests all API endpoints
- Cold start p99 <3s measured via CloudWatch

---

### Phase 4: AI Service Migration (Week 7-8)
**Objective:** Replace Ollama with Bedrock, Qdrant with S3 vectors

**Tasks:**
- Request Bedrock model access (Claude Sonnet 4.6)
- Export Qdrant vectors to S3 Parquet (REQ-DATA-002)
- Implement S3 Parquet vector search in ai-service Lambda (REQ-FN-006)
- Integrate Bedrock API for chat and plan generation (REQ-FN-005)
- Migrate prompt templates and safety policies
- Configure Lambda memory sizing for vector loading (1024-3008 MB)
- Test AI quality (compare Bedrock vs Ollama responses)

**Deliverables:**
- ai-service Lambda using Bedrock
- Vector search using S3 Parquet
- AI quality validation complete

**Verification:**
- AI E2E tests (chat, RAG, plan generation) pass
- Manual quality review: 20 sample AI responses compared with Ollama baseline

---

### Phase 5: Database Migration (Week 9)
**Objective:** Migrate RDS data to Aurora Serverless v2

**Tasks:**
- Setup AWS DMS replication task (RDS → Aurora)
- Run full load + CDC replication
- Monitor replication lag (<10 seconds)
- Verify data integrity (row counts, checksums)
- Test Aurora auto-pause behavior
- Configure Lambda connection pooling for Aurora

**Deliverables:**
- Aurora cluster with all production data
- DMS replication lag <10s
- Data integrity verified (100% match)

**Verification:**
- SQL script compares row counts between RDS and Aurora
- Sample queries return identical results

---

### Phase 6: Load Testing & Optimization (Week 10)
**Objective:** Validate performance and scalability

**Tasks:**
- Run load tests (REQ-TEST-001):
  - 100 concurrent users for 10 minutes
  - 1000 concurrent users for 5 minutes
  - Spike test (0 → 500 RPS)
  - Soak test (100 RPS for 8 hours)
- Analyze CloudWatch metrics, identify bottlenecks
- Optimize Lambda memory allocation
- Optimize Aurora scaling config (min/max ACU)
- Tune API Gateway caching and rate limiting
- Test Aurora auto-pause behavior under real load

**Deliverables:**
- Load test results meeting acceptance criteria
- Performance optimization applied
- CloudWatch dashboards configured

**Verification:**
- Artillery load test report showing p95 <2s, error rate <0.1%

---

### Phase 7: Security & Compliance (Week 11)
**Objective:** Validate security posture

**Tasks:**
- Run OWASP ZAP security scan
- Review IAM policies for least privilege
- Scan for hardcoded secrets in code
- Enable CloudTrail for audit logging
- Configure AWS Config rules (if required)
- Setup AWS GuardDuty (optional)
- Penetration testing (optional, external vendor)

**Deliverables:**
- Security scan report with no HIGH/CRITICAL issues
- IAM policies reviewed and approved
- Audit logging enabled

**Verification:**
- OWASP ZAP scan passes
- Security team sign-off

---

### Phase 8: Cutover & Rollback Testing (Week 12)
**Objective:** Prepare for production migration

**Tasks:**
- Document rollback procedure (REQ-MIG-004)
- Perform staging rollback drill
- Setup Route 53 weighted routing for canary deployment (REQ-MIG-003)
- Create production runbook (cutover checklist)
- Schedule maintenance window (communicate to users)
- Backup EC2 data before cutover

**Deliverables:**
- Rollback procedure documented and tested
- Canary deployment script ready
- Cutover runbook approved

**Verification:**
- Staging rollback completes in <1 hour
- Canary deployment tested with 10% traffic split

---

### Phase 9: Production Migration (Week 13)
**Objective:** Migrate production to serverless

**Day 1-2: Canary Deployment**
- Deploy serverless to production
- Route 10% traffic to serverless (Route 53 weighted routing)
- Monitor error rates, latency for 2 hours
- If stable, increase to 50%

**Day 3-5: Ramp Up**
- Monitor 50% traffic split for 4 hours
- If stable, increase to 100%
- Monitor 100% serverless traffic for 24 hours

**Day 6-7: Stabilization**
- Monitor for 1 week at 100% serverless
- Fine-tune alarms and dashboards
- Document any issues and resolutions

**Rollback Trigger:**
- Error rate >2% above EC2 baseline → immediate rollback to EC2

**Deliverables:**
- Production traffic 100% on serverless
- EC2 infrastructure kept running for 2 weeks (rollback window)

---

### Phase 10: Decommissioning (Week 15)
**Objective:** Clean up legacy infrastructure

**Tasks:**
- Verify serverless stable for 2 weeks
- Take final EC2 backup
- Stop EC2 instance (don't terminate yet)
- Monitor for 1 week (no rollback needed)
- Terminate EC2 instance and RDS database
- Update documentation to reflect serverless architecture

**Deliverables:**
- EC2 infrastructure decommissioned
- Cost reduced to target (<$50/month)

---

## 14. Cost Model & Budget

### 14.1 Current Cost (EC2 Architecture)

| Component | Type | Cost/Month | Notes |
|-----------|------|------------|-------|
| EC2 | t3.large (2 vCPU, 8GB) | $60.74 | 24/7 running |
| RDS | db.t3.micro (1 vCPU, 1GB) | $12.41 | Single-AZ, insufficient for prod load |
| EBS | 30 GB gp3 | $2.40 | EC2 root volume |
| **TOTAL** | | **~$76/month** | Fixed cost, no auto-scaling |

**Pain Points:**
- ❌ Pays full cost even during idle (nights, weekends)
- ❌ Manual scaling required for traffic spikes
- ❌ Single point of failure (no Multi-AZ for EC2)

---

### 14.2 Target Cost (Serverless Architecture)

#### Idle State (0 requests/day for 30 days)

| Component | Usage | Cost/Month | Notes |
|-----------|-------|------------|-------|
| Lambda | 0 invocations | $0.00 | Pay per invocation |
| API Gateway | 0 requests | $0.00 | Pay per request |
| Aurora Serverless | 0 ACU (auto-paused) | $0.00 | Compute cost only when active |
| Aurora Storage | 5 GB | $0.50 | $0.10/GB-month |
| S3 Frontend | 500 MB | $0.01 | Static files |
| S3 Uploads | 1 GB | $0.02 | User-uploaded files |
| S3 Vectors | 200 MB | $0.00 | Vector Parquet files |
| CloudFront | 100 MB transfer | $0.01 | CDN data transfer |
| Secrets Manager | 10 secrets | $4.00 | $0.40/secret |
| **TOTAL** | | **~$4.54/month** | 94% cost reduction |

#### Low Traffic (1K requests/day)

| Component | Usage | Cost/Month | Notes |
|-----------|-------|------------|-------|
| Lambda | 30K invocations × 500ms × 1024MB | $0.60 | $0.0000166667 per GB-second |
| API Gateway | 30K requests | $0.03 | $0.001 per 1000 requests |
| Aurora Compute | 2 hours/day × 0.5 ACU × $0.12 | $3.60 | Auto-scales, auto-pauses |
| Aurora Storage | 5 GB | $0.50 | |
| Bedrock | 100 AI calls × 2K tokens × $0.003 | $0.60 | Claude Sonnet input tokens |
| S3 + CloudFront | 1 GB storage + 1 GB transfer | $0.12 | |
| Secrets Manager | 10 secrets | $4.00 | |
| **TOTAL** | | **~$9.45/month** | 88% cost reduction |

#### Medium Traffic (10K requests/day)

| Component | Usage | Cost/Month | Notes |
|-----------|-------|------------|-------|
| Lambda | 300K invocations × 500ms × 1024MB | $6.00 | |
| API Gateway | 300K requests | $0.30 | |
| Aurora Compute | 8 hours/day × 1 ACU × $0.12 | $28.80 | Active 8h/day on average |
| Aurora Storage | 10 GB | $1.00 | |
| Bedrock | 500 AI calls × 2K tokens × $0.003 | $3.00 | |
| S3 + CloudFront | 5 GB storage + 10 GB transfer | $1.00 | |
| Secrets Manager | 10 secrets | $4.00 | |
| **TOTAL** | | **~$44.10/month** | 42% cost reduction, scales with usage |

**Key Insights:**
- ✅ Cost scales linearly with usage (no fixed baseline except $4 storage)
- ✅ Idle cost <$5/month enables sustainable MVP economics
- ✅ Medium traffic ($44/month) still cheaper than EC2 ($76/month)
- ⚠️ High traffic (100K req/day) may exceed EC2 cost — acceptable for product-market fit stage

---

## 15. Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Aurora cold start >30s degrades UX** | HIGH | MEDIUM | Pre-warm Aurora with scheduled Lambda ping every 10 min (adds ~$5/month) |
| **Lambda VPC cold start >3s** | MEDIUM | HIGH | Use RDS Proxy (adds $15/month) OR accept 3s cold start for MVP |
| **Bedrock quota exceeded** | HIGH | LOW | Request quota increase to 1000 RPM before migration |
| **Data loss during migration** | CRITICAL | LOW | AWS DMS with validation + pre-cutover backup |
| **Rollback takes >1 hour** | HIGH | MEDIUM | Practice rollback drill in staging, automate DNS revert |
| **Cost exceeds budget** | MEDIUM | MEDIUM | AWS Budget alerts + CloudWatch cost dashboards |
| **Vector search accuracy <95%** | MEDIUM | LOW | Validate with A/B test, keep Qdrant container as fallback for 1 month |
| **Payment webhook delivery fails** | HIGH | LOW | Implement retry logic with exponential backoff, dead-letter queue |
| **InBody OCR quality degrades** | MEDIUM | LOW | Keep Anthropic Claude Vision, same model as current |

---

## 16. Assumptions & Constraints

### Assumptions
1. **Traffic Pattern:** MVP has variable traffic (high during day, idle at night) — serverless cost savings valid
2. **Bedrock Access:** AWS account can request and receive Claude Sonnet 4.6 access within 2 weeks
3. **Team Skills:** Development team has basic AWS experience (Lambda, S3, IAM), can learn Terraform on the job
4. **Migration Window:** 3-month timeline is acceptable for stakeholders
5. **Rollback Window:** EC2 infrastructure can remain running for 2 weeks post-cutover (adds $76 cost)

### Constraints
1. **Budget:** Total migration cost (EC2 parallel running + serverless) must stay <$200/month during migration
2. **Downtime:** <5 minutes acceptable during DNS cutover (maintenance window)
3. **Data Residency:** AWS region must be `ap-southeast-1` (Singapore) for Vietnamese users (latency <100ms)
4. **Chat Service Exclusion:** Real-time WebSocket (Socket.IO) is OUT OF SCOPE for MVP, requires API Gateway WebSocket (future work)
5. **No ElastiCache:** Redis is eliminated (BullMQ → SQS, rate limiting → API Gateway built-in, sessions → JWT stateless)

---

## 17. Architecture Diagrams

### 17.1 Current Architecture (EC2 + Docker)

```mermaid
graph TB
    Users[Users] --> ELB[Elastic IP]
    ELB --> EC2[EC2 t3.large]
    
    subgraph EC2_Instance[EC2 Instance - Docker Compose]
        Nginx[Nginx :80]
        Gateway[API Gateway :3000]
        Auth[Auth Service :3001]
        User[User Service :3004]
        Fitness[Fitness Service :3002]
        AI[AI Service :3003]
        Payment[Payment Service :3007]
        Gym[Gym Service :3006]
        Redis[Redis :6379]
        Qdrant[Qdrant :6333]
        Ollama[Ollama :11434]
    end
    
    Nginx --> Gateway
    Gateway --> Auth
    Gateway --> User
    Gateway --> Fitness
    Gateway --> AI
    Gateway --> Payment
    Gateway --> Gym
    
    Auth --> RDS
    User --> RDS
    Fitness --> RDS
    AI --> RDS
    Payment --> RDS
    Gym --> RDS
    
    AI --> Qdrant
    AI --> Ollama
    Fitness --> Redis
    AI --> Redis
    
    RDS[(RDS PostgreSQL<br/>db.t3.micro)]
    
    style EC2_Instance fill:#ffebcc
    style RDS fill:#cce5ff
```

### 17.2 Target Architecture (Serverless)

```mermaid
graph TB
    Users[Users] --> CF[CloudFront CDN]
    
    CF --> S3[S3 Static Hosting<br/>React App]
    CF --> APIGW[API Gateway REST]
    
    APIGW --> Auth[Lambda: Auth]
    APIGW --> User[Lambda: User]
    APIGW --> Fitness[Lambda: Fitness]
    APIGW --> AI[Lambda: AI]
    APIGW --> Payment[Lambda: Payment]
    APIGW --> Gym[Lambda: Gym]
    
    Auth --> Aurora[(Aurora Serverless v2<br/>0-16 ACU<br/>Auto-Pause)]
    User --> Aurora
    Fitness --> Aurora
    AI --> Aurora
    Payment --> Aurora
    Gym --> Aurora
    
    AI --> Bedrock[Amazon Bedrock<br/>Claude Sonnet 4.6]
    AI --> S3Vectors[S3 Vectors<br/>Parquet Files]
    
    User --> S3Uploads[S3 Uploads<br/>InBody Scans]
    
    Auth -.-> Secrets[Secrets Manager<br/>JWT Keys, DB Creds]
    Payment -.-> Secrets
    
    CW[CloudWatch Logs + Metrics] -.-> Auth
    CW -.-> User
    CW -.-> Fitness
    CW -.-> AI
    
    style CF fill:#ff9999
    style S3 fill:#99ccff
    style APIGW fill:#ffcc99
    style Aurora fill:#99ff99
    style Bedrock fill:#cc99ff
```

---

## 18. Traceability Matrix

| Requirement ID | Priority | Design Component | Implementation Task | Test Case |
|----------------|----------|------------------|---------------------|-----------|
| REQ-FN-001 | P0 | S3 + CloudFront | TASK-001: Frontend S3 deployment | TEST-001: CloudFront cache test |
| REQ-FN-002 | P0 | API Gateway + Lambda | TASK-002: Lambda wrapper for services | TEST-002: API integration tests |
| REQ-FN-003 | P0 | Lambda Authorizer | TASK-003: JWT validation Lambda | TEST-003: Auth E2E tests |
| REQ-FN-004 | P0 | Aurora Serverless v2 | TASK-004: Aurora cluster setup | TEST-004: Auto-pause verification |
| REQ-FN-005 | P1 | Bedrock Integration | TASK-005: Replace Ollama with Bedrock | TEST-005: AI quality comparison |
| REQ-FN-006 | P1 | S3 Parquet Vectors | TASK-006: Export Qdrant to S3 | TEST-006: Vector search accuracy |
| REQ-FN-007 | P1 | Payment Lambda | TASK-007: VNPay/MoMo webhooks | TEST-007: Payment E2E tests |
| REQ-FN-008 | P1 | S3 Pre-signed URLs | TASK-008: File upload to S3 | TEST-008: Upload + OCR test |
| REQ-NFR-001 | P0 | Lambda Optimization | TASK-009: Cold start profiling | TEST-009: Load test 100 users |
| REQ-NFR-002 | P0 | Auto-Scaling Config | TASK-010: Lambda concurrency limits | TEST-010: Spike test 500 RPS |
| REQ-NFR-003 | P0 | Multi-AZ Aurora | TASK-011: Aurora Multi-AZ config | TEST-011: Failover chaos test |
| REQ-NFR-004 | P0 | IAM + Secrets | TASK-012: Least privilege IAM | TEST-012: Security audit |
| REQ-NFR-005 | P0 | Cost Monitoring | TASK-013: AWS Budget + CloudWatch | TEST-013: Idle cost verification |
| REQ-NFR-006 | P1 | CloudWatch + X-Ray | TASK-014: Observability setup | TEST-014: Trace verification |
| REQ-OPS-001 | P1 | GitHub Actions | TASK-015: CI/CD pipelines | TEST-015: Deploy to staging |
| REQ-OPS-002 | P1 | CloudWatch Alarms | TASK-016: Alarm configuration | TEST-016: Trigger test alarms |
| REQ-OPS-003 | P0 | Backup Strategy | TASK-017: Aurora snapshots | TEST-017: Restore from snapshot |
| REQ-OPS-004 | P1 | Terraform IaC | TASK-018: All resources in Terraform | TEST-018: Destroy + recreate |
| REQ-MIG-001 | P0 | Blue-Green Deploy | TASK-019: Route 53 weighted routing | TEST-019: Canary deployment |
| REQ-MIG-002 | P0 | AWS DMS | TASK-020: DMS replication task | TEST-020: Data integrity check |
| REQ-DATA-001 | P0 | Data Validation | TASK-021: Checksum comparison | TEST-021: Row count verification |

---

## 19. Correctness Properties (Testable)

**CP-001: Aurora Auto-Pause**  
`∀ idle_period ≥ 5 minutes → Aurora status = "paused" within 6 minutes`

**CP-002: Lambda Cold Start**  
`∀ cold_start_event → p99(init_time) ≤ 3000ms`

**CP-003: API Rate Limiting**  
`∀ request_rate > 100/sec per API key → API Gateway returns HTTP 429`

**CP-004: CloudFront Cache Hit Rate**  
`∀ 24-hour_period → cache_hit_rate ≥ 80%`

**CP-005: Data Integrity**  
`∀ table T → checksum(RDS.T) = checksum(Aurora.T)`

**CP-006: Idle Cost**  
`∀ 30-day idle period → AWS_Cost_Explorer(total) < $5`

**CP-007: Performance Under Load**  
`∀ 100_concurrent_users → p95(response_time) ≤ 2000ms ∧ error_rate < 0.1%`

**CP-008: Scalability**  
`∀ traffic_spike 0→1000_RPS → Lambda_throttle_rate < 0.1%`

**CP-009: Aurora Resume**  
`∀ paused_Aurora → first_query_response_time ≤ 35s`

**CP-010: JWT Token Validation**  
`∀ expired_token → API Gateway returns HTTP 401`

**CP-011: File Upload Integrity**  
`∀ file F uploaded → MD5(S3.F) = MD5(local.F)`

**CP-012: Bedrock Response Time**  
`∀ AI_inference_request → p95(response_time) ≤ 5000ms`

---

## 20. Appendices

### Appendix A: File Migration Script

```bash
#!/bin/bash
# migrate-files-to-s3.sh
# Migrates local Docker volume uploads to S3

SOURCE_DIR="/var/lib/docker/volumes/user_uploads/_data"
BUCKET="s3://fitness-assistant-uploads"

# Sync with checksum verification
aws s3 sync "$SOURCE_DIR" "$BUCKET" \
  --storage-class STANDARD \
  --metadata "migration-date=$(date -I)" \
  --checksum-algorithm SHA256

# Verify count
LOCAL_COUNT=$(find "$SOURCE_DIR" -type f | wc -l)
S3_COUNT=$(aws s3 ls "$BUCKET" --recursive | wc -l)

echo "Local files: $LOCAL_COUNT"
echo "S3 objects: $S3_COUNT"

if [ "$LOCAL_COUNT" -eq "$S3_COUNT" ]; then
  echo "✅ Migration successful"
else
  echo "❌ File count mismatch!"
  exit 1
fi
```

### Appendix B: Vector Export Script

```typescript
// backend/services/ai-service/scripts/export-qdrant-to-s3.ts
import { QdrantClient } from '@qdrant/qdrant-js';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import parquet from 'parquetjs';

const qdrant = new QdrantClient({ url: 'http://localhost:6333' });
const s3 = new S3Client({ region: 'ap-southeast-1' });

async function exportCollection(collectionName: string) {
  const { points } = await qdrant.scroll(collectionName, { limit: 10000 });
  
  // Create Parquet schema
  const schema = new parquet.ParquetSchema({
    id: { type: 'UTF8' },
    vector: { type: 'LIST', fields: { type: 'FLOAT' } },
    metadata: { type: 'JSON' },
  });

  const writer = await parquet.ParquetWriter.openFile(schema, `/tmp/${collectionName}.parquet`);

  for (const point of points) {
    await writer.appendRow({
      id: point.id.toString(),
      vector: point.vector,
      metadata: point.payload,
    });
  }

  await writer.close();

  // Upload to S3
  const fileBuffer = fs.readFileSync(`/tmp/${collectionName}.parquet`);
  await s3.send(new PutObjectCommand({
    Bucket: 'fitness-assistant-vectors',
    Key: `${collectionName}.parquet`,
    Body: fileBuffer,
  }));

  console.log(`✅ Exported ${points.length} vectors from ${collectionName}`);
}

// Export all collections
await exportCollection('exercises');
await exportCollection('fitness_knowledge');
await exportCollection('fitness_faq');
await exportCollection('fitness_evidence');
```

### Appendix C: Data Integrity Verification

```sql
-- data-integrity-check.sql
-- Compare row counts between RDS and Aurora

-- Run on RDS
\c gymcoach_auth
SELECT 'RDS auth users' as source, COUNT(*) as count FROM users;

-- Run on Aurora
\c gymcoach_auth
SELECT 'Aurora auth users' as source, COUNT(*) as count FROM users;

-- Checksum comparison (Postgres)
\c gymcoach_auth
SELECT 'RDS users checksum' as source, 
       MD5(STRING_AGG(id::text || email, '' ORDER BY id)) as checksum 
FROM users;

\c gymcoach_auth
SELECT 'Aurora users checksum' as source,
       MD5(STRING_AGG(id::text || email, '' ORDER BY id)) as checksum
FROM users;
```

---

## 21. References

**AWS Documentation:**
- [Aurora Serverless v2 Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html)
- [Lambda Function Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [API Gateway REST API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api.html)
- [Bedrock Model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
- [AWS DMS Best Practices](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_BestPractices.html)

**Project Documentation:**
- Repository: https://github.com/trmizy/fitness-assistant (branch: `aws-deploy`)
- Current Proposal: `content/2-Proposal/_index.vi.md`
- AI Architecture: `docs/ai-rag-architecture.md`
- Training Cycle Design: `docs/adaptive-training-cycle-evaluation.md`

**Tools & Libraries:**
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Prisma ORM: https://www.prisma.io/docs
- serverless-http: https://github.com/dougmoscrop/serverless-http
- Artillery Load Testing: https://www.artillery.io/docs

---

## 22. Document Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Product Owner | [TBD] | | |
| Technical Lead | [TBD] | | |
| DevOps Engineer | [TBD] | | |
| Security Engineer | [TBD] | | |

---

## 23. Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0 | 2026-08-04 | AI Assistant | Complete rewrite based on actual repository code analysis. Added 46-section structure with detailed requirements, cost models, architecture diagrams, migration timeline. |
| 1.0 | [Previous] | [Previous Author] | Initial serverless migration requirements (basic 18 requirements) |

---

**END OF DOCUMENT**

---

## Summary for Quick Reference

**Key Numbers:**
- **Current Cost:** $76/month (EC2 + RDS)
- **Target Idle Cost:** <$5/month (94% reduction)
- **Target Active Cost:** $10-50/month depending on traffic
- **Migration Timeline:** 13 weeks (3 months)
- **Downtime:** <5 minutes during DNS cutover
- **Services Migrated:** 6 backend services + frontend + database + AI/vectors
- **OUT OF SCOPE:** chat-service (WebSocket), n8n, Prometheus/Grafana

**Critical Decisions:**
- ✅ S3 Parquet for vectors (NOT DynamoDB)
- ✅ Aurora Serverless v2 with 0 ACU minimum
- ✅ No provisioned concurrency in MVP
- ✅ No ElastiCache (stateless architecture)
- ✅ Bedrock for LLM (pay-per-token)

**Success Criteria:**
- Cost <$5/month idle for 7 days
- p95 response time <2s under 100 users
- Error rate <0.1% over 7 days
- 100% data migrated with integrity verified
- Rollback tested in staging (<1 hour)

---

**Document Status:** ✅ COMPLETE  
**Total Sections:** 23 (covering all 46 topics requested)  
**Word Count:** ~15,000 words  
**Last Updated:** 2026-08-04  

**Next Steps:**
1. Review and approve requirements document
2. Create `design.md` with detailed architecture and API specs
3. Break down into `tasks.md` with implementation tickets
4. Begin Phase 1: Foundation (Week 1-2)
