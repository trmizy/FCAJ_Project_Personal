---
title: "5.1 Overview"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.1. </b> "
---

### The Problem

Fitness Assistant is a real, actively developed open-source application, but it is built and tested only for local development via Docker Compose. There is no existing AWS deployment, CI/CD pipeline, or cloud infrastructure of any kind in the source repository. This workshop closes that gap by deploying a production-shaped, serverless-first version of the application on AWS.

{{% notice note %}}
An earlier version of this report planned a simpler EC2 + Docker Compose MVP. That plan was superseded by the serverless architecture described from here on — Lambda-based microservices behind API Gateway, Aurora PostgreSQL Serverless, Amazon Bedrock and OpenSearch Serverless for AI, and ECS Fargate for the one component (Chat) that genuinely needs a long-lived connection. The [Proposal](../../2-Proposal/) and every Workshop page describe what was actually deployed.
{{% /notice %}}

### Target Users

- Gym members / fitness app end users tracking workouts, goals, and receiving AI coaching suggestions.
- Gym owners, personal trainers and administrators managing gyms, contracts and payments.
- The FCAJ mentor/reviewer evaluating this internship's execution.

### Application Features (as actually deployed)

- User registration and login, JWT-based (`auth-service`, Lambda).
- Profile, onboarding, InBody records, PT applications and contracts, with files stored in a private S3 bucket through presigned URLs (`user-service`, Lambda + jobs Lambda).
- Exercise catalog, workout plans, workout logging, nutrition and reminders (`fitness-service`, Lambda + jobs Lambda).
- AI coaching and plan generation on Amazon Bedrock — Nova Pro for chat/vision, Cohere multilingual embeddings with an OpenSearch Serverless vector store for retrieval (`ai-service`: HTTP Lambda, SQS-driven Worker, scheduled Jobs).
- Gym/PT listings and signed QR check-in (`gym-service`, Lambda + jobs Lambda), and wallet/PT-contract payments through VNPAY, with MoMo/PayOS/ZaloPay supported by the code (`payment-service`, Lambda + reconciliation job).
- Real-time chat (`chat-service`) on Amazon ECS Fargate behind an Application Load Balancer — Socket.IO needs a long-lived connection that a request/response Lambda cannot hold open.

{{% notice note %}}
The AI coaching feature originally ran on a self-hosted LLM (Ollama) with a Qdrant vector store, as described in [Week 8](../../1-Worklog/1.8-Week8/) of the Worklog. On AWS it moved to Amazon Bedrock (`apac.amazon.nova-pro-v1:0`, `cohere.embed-multilingual-v3`) and OpenSearch Serverless, which removes the work of sizing and patching an instance for the model. The InBody **photo extraction** feature of `user-service` called the Anthropic API directly in local development; its API key was deliberately not configured on AWS, so that one feature is not enabled in this DEV environment yet. None of the AI features is a substitute for medical advice.
{{% /notice %}}

### Desired Outcome

A working DEV environment reachable over the internet: a static frontend on Amazon S3, an Amazon API Gateway front door, six Lambda-based microservices and one ECS Fargate service behind it, a single Amazon Aurora PostgreSQL Serverless cluster holding one logical database per service, and managed AI on Bedrock and OpenSearch Serverless — documented step by step with evidence (console screenshots, policies, environment variables, verification results), not assumptions.

### Scope

- **Shared infrastructure:** one VPC, private application subnets for Lambda and Fargate, private DB subnets (no internet route), public subnets for the NAT Gateway and the Chat ALB, and a NAT + Internet Gateway pair for outbound calls.
- **Eight deployment blocks documented end to end:** Auth, User, Fitness, Gym, Payment, AI (HTTP + Worker + Jobs + vector search), Chat, and the one-off data migration that restored 7 local PostgreSQL databases into Aurora.
- **Frontend:** a static build hosted on Amazon S3 (website endpoint over HTTP for now; CloudFront + Origin Access Control is a known follow-up, not yet usable in this account).

### Components Still Incomplete

- **CI/CD pipeline:** not yet built — deployments so far are manual console/CLI steps, captured as they happened.
- **End-to-end validation:** Auth and User are fully verified; Fitness, Gym, Payment, AI/Worker/Jobs, Chat and the frontend integration still need a full E2E pass — see [5.5.5](../5.5-Test-Validation/5.5.5-Status-Open-Items/).
- **Security follow-ups deliberately postponed:** rotating the ADMIN credential and remediating the remaining seed accounts — not blockers for DEV, but tracked.
- **Cost controls:** a DEV "sleep" strategy (Aurora to 0 ACU, Chat to 0 tasks, NAT Gateway only when needed) is planned but not yet automated — see [5.7](../5.7-Cleanup/).

### Deliverables

- [5.2 Architecture Description](../5.2-Architecture-Description/) — request flows, AWS service choices, security/IAM, scalability and cost.
- [5.3 Prerequisite](../5.3-Prerequisites/) — account, region and local tools.
- [5.4 Deployment Guide](../5.4-Deployment-Guide/) — every service, step by step, with the original console screenshots and the exact IAM policies.
- [5.5 Test & validation](../5.5-Test-Validation/) — the checks, their expected results and their current status.
- [5.6 Demo](../5.6-Demo/) and [5.7 Clean-up](../5.7-Cleanup/).

### Definition of Done

- Every AWS service marked "Deployed" in this report is backed by a screenshot, log excerpt or command output in this Workshop.
- No step claims success without evidence; checks not run yet are labelled as pending rather than passed.
