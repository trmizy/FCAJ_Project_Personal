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
This Workshop previously documented an earlier, simpler EC2 + Docker Compose MVP plan. That plan has since been superseded by the serverless architecture described from here on — Lambda-based microservices behind API Gateway, Aurora PostgreSQL Serverless, and ECS Fargate for the one component (Chat) that genuinely needs a long-lived connection. The [Proposal](../../2-Proposal/) still reflects the earlier EC2 plan and is pending an update to match; where the two disagree, this Workshop and the architecture pages under [5.2](../5.2-Architecture-Description/) describe what was actually deployed.
{{% /notice %}}

### Target Users

- Gym members / fitness app end users tracking workouts, goals, and receiving AI coaching suggestions.
- The FCAJ mentor/reviewer evaluating this internship's execution.

### Application Features (as actually deployed)

- User registration and login, JWT-based (`auth-service`, Lambda).
- Profile management, including InBody body-composition record uploads with AI-assisted extraction (`user-service`, Lambda).
- Exercise catalog, workout plans, and workout logging (`fitness-service`, Lambda).
- AI-assisted coaching: Amazon Bedrock (Nova Pro for chat/vision, Cohere multilingual embeddings for retrieval) (`ai-service`, Lambda + an async AI Worker for background jobs).
- Gym/PT listings and QR check-in (`gym-service`, Lambda), and wallet/PT-contract payments through VNPAY, with MoMo/PayOS/ZaloPay credentials added as they become available (`payment-service`, Lambda).
- Real-time chat (`chat-service`), running on Amazon ECS Fargate behind an Application Load Balancer — unlike the other services, Socket.IO needs a long-lived connection that a request/response Lambda cannot hold open.

{{% notice note %}}
The AI coaching feature originally ran on a self-hosted LLM (Ollama) with a Qdrant vector store, as described in [Week 8](../../1-Worklog/1.8-Week8/) of the Worklog — a deliberate choice at the time to avoid managed-endpoint cost. The service has since moved to Amazon Bedrock (model `apac.amazon.nova-pro-v1:0` for chat/vision, `cohere.embed-multilingual-v3` for embeddings), which removes the operational burden of sizing and patching an EC2 instance for the LLM. The separate InBody photo-extraction feature in `user-service` also calls into this same AI path rather than a separate direct API integration. Neither feature is a substitute for medical advice — see the disclaimer in [5.17 Conclusion](../5.17-Conclusion/).
{{% /notice %}}

### Desired Outcome

A working DEV environment reachable over the internet: a static frontend on Amazon S3, an Amazon API Gateway front door, six Lambda-based microservices and one ECS Fargate service behind it, and a single Amazon Aurora PostgreSQL Serverless cluster holding one logical database per service — documented step by step with evidence (console screenshots, environment variable listings, verification notes), not assumptions.

### Scope

- **Shared infrastructure:** one VPC, private application subnets for Lambda, a separate private DB subnet (no internet route), a public subnet for the NAT Gateway only, and a NAT + Internet Gateway pair for outbound calls (API Gateway invocations, Bedrock, Secrets Manager).
- **Eight services documented end to end:** Auth, User, Fitness, Gym, Payment, AI (HTTP + Worker + Jobs), Chat, and the one-off Database Migration that moved 7 local Postgres dumps into Aurora.
- **Frontend:** a static build hosted on Amazon S3 (website endpoint over HTTP for now; CloudFront + Origin Access Control is a known follow-up, not yet usable in this environment).

### Components Still Incomplete

- **CI/CD pipeline:** not yet built — deployments so far are manual console/CLI steps, captured as they happened.
- **End-to-end validation:** Auth and User are fully verified; Fitness, Gym, Payment, AI/Worker/Jobs, Chat, and the Frontend integration still need a full E2E pass (tracked as "NEEDS VERIFICATION" in the deployment status table in [5.2.1 Architecture Overview](../5.2-Architecture-Description/5.2.1-Architecture-Overview/)).
- **Security follow-ups deliberately postponed:** rotating the ADMIN credential and remediating the remaining seed accounts — not blockers for the current DEV environment, but tracked as open items.
- **Cost controls:** a DEV "sleep" strategy for idle resources (e.g. pausing Aurora, scaling the Chat Fargate service to zero outside working hours) is planned but not yet implemented.

### Deliverables

- This Workshop, rewritten section by section to match what was actually deployed, with reproducible steps and evidence.
- An architecture description covering the request flows, AWS service choices, security/IAM model, scalability approach, and cost posture (this section, [5.2](../5.2-Architecture-Description/)).
- A step-by-step deployment guide per service, carried over from the internal deployment runbook ([5.4](../5.4-Run-Local/), in progress).
- IAM policy examples and a test case table with evidence status.

### Definition of Done

- Every AWS service marked "Implemented" or "Deployed" elsewhere in this report is backed by a screenshot, log excerpt, or command output somewhere in this Workshop.
- No step here claims success without a corresponding Evidence subsection, even if that subsection currently says `TODO` — carried over unchanged as a rule from the original MVP Workshop, and still the right rule for a serverless system with eight moving parts.
