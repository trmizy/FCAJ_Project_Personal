---
title: "5.2.1 Architecture Overview"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.2.1. </b> "
---

### Deployment Status Summary

Snapshot of the current AWS deployment, migration, and end-to-end (E2E) test status, as recorded in the internal deployment runbook. Statuses reflect only what is evidenced there.

| Component | AWS Deployment | Migration | E2E | Status |
|---|---|---|---|---|
| Shared Infrastructure (VPC/Subnets/SGs/NAT/IGW) | Complete | N/A | N/A | **COMPLETE** |
| Aurora PostgreSQL | Complete | Complete — 7/7 service DBs restored | Verified | **COMPLETE** |
| Auth Service | Deployed | Complete | Passed (incl. transaction-atomicity fix) | **COMPLETE** |
| User Service | Deployed | Complete | Passed | **COMPLETE** |
| Fitness Service | Deployed | Complete | Pending full E2E | NEEDS VERIFICATION |
| Gym Service | Deployed | Complete | Pending full E2E | NEEDS VERIFICATION |
| Payment Service | Deployed | Complete | Pending full E2E | NEEDS VERIFICATION |
| AI / Worker / Jobs | Deployed | Complete | Pending E2E | NEEDS VERIFICATION |
| Chat Service (REST + Socket.IO) | Deployed | Complete | Pending full E2E | NEEDS VERIFICATION |
| Frontend (S3) | Deployed | N/A | Pending full integration E2E | NEEDS VERIFICATION |
| CI/CD | Incomplete | N/A | N/A | **INCOMPLETE** |

Database migration verification: 23/23 audited foreign keys applied and validated. ADMIN credential rotation and remaining seed-account remediation were intentionally postponed (not current blockers, but tracked as open security follow-ups).

### Components

**Shared infrastructure**

- One VPC (`fitness-assistant-dev-vpc`, `10.0.0.0/16`, `ap-southeast-1`).
- Two private application subnets (Lambda placement), one public subnet (NAT Gateway placement only — no Lambda or DB resources sit here), and private DB subnets with no internet route at all.
- One shared Lambda security group, used by every Lambda-based service.
- One Internet Gateway and one NAT Gateway, so Lambdas in the private subnets can reach API Gateway, Amazon Bedrock, and other AWS APIs outbound.

**Six Lambda-based microservices:** Auth, User, Fitness, Gym, Payment, and AI (an HTTP Lambda plus a background Worker and a Jobs Lambda for scheduled/async work), all sitting behind one Amazon API Gateway HTTP API and sharing the VPC and security group above.

**One ECS Fargate service:** Chat, which handles both a REST API and a Socket.IO real-time connection. Socket.IO needs a connection that stays open for the life of a chat session — a shape Lambda's request/response model does not fit — so Chat runs as a container on Fargate behind its own Application Load Balancer instead.

**One Aurora PostgreSQL Serverless cluster** (`fitness-assistant-dev-aurora`), holding one logical database per service rather than one database per cluster:

```
fitness-assistant-dev-aurora
├── fitness_assistant          → Auth
├── fitness_assistant_user     → User
├── fitness_assistant_fitness  → Fitness
├── fitness_assistant_gym      → Gym
├── fitness_assistant_payment  → Payment
├── fitness_assistant_ai       → AI
└── fitness_assistant_chat     → Chat
```

Each service's Lambda (or the Chat Fargate task) reads its own database only, resolved from its own `DATABASE_SECRET_ID` in Secrets Manager — no service is configured to reach another service's database directly.

**One static frontend** on Amazon S3 (website hosting, HTTP for now — see [5.2.7](../5.2.7-Cost-Optimization-Cleanup/) for why CloudFront is not yet in front of it).

### How This Differs From the Original MVP Plan

The earlier version of this Workshop (see the [Worklog](../../../1-Worklog/) for Weeks 5–9) planned a single EC2 host running the whole Docker Compose stack, one Amazon RDS instance, and a self-hosted Ollama + Qdrant pair for AI. That plan's own "Future Architecture" note already named the direction this ended up taking: ECS/Fargate instead of a single host, and Amazon Bedrock instead of self-hosted Ollama. Both of those predictions became the real architecture described on this page, ahead of the original 12-week schedule's "Future" bucket.

What changed in practice, service by service, is detailed in each service's entry further down in this report; the sections immediately following this one ([5.2.2](../5.2.2-Architecture-Diagram/) onward) describe the system as it stands now, not its history.
