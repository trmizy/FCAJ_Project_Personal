---
title: "5.1 Overview"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.1. </b> "
---

### The Problem

Fitness Assistant is a real, actively developed open-source application, but it is built and tested only for local development via Docker Compose. There is no existing AWS deployment, CI/CD pipeline, or cloud infrastructure of any kind in the source repository. This workshop closes that gap for a minimum viable subset of the application.

### Target Users

- Gym members / fitness app end users tracking workouts, goals, and receiving AI coaching suggestions.
- The FCAJ mentor/reviewer evaluating this internship's execution.

### Application Features (as verified in source)

- User registration and login (`auth-service`, JWT-based).
- Profile management, including InBody body-composition record uploads with AI-assisted extraction (`user-service`).
- Exercise catalog, workout plans, and workout logging (`fitness-service`).
- AI-assisted coaching: a self-hosted LLM (Ollama, `llama3.2:3b`) combined with a Qdrant-backed Retrieval-Augmented Generation (RAG) pipeline (`ai-service`).
- Real-time chat (`chat-service`), gym management (`gym-service`) and payments (`gym-service`/`payment-service`) also exist in source but are **not** part of this MVP (see below).

{{% notice note %}}
The AI coaching feature is a genuine LLM-backed RAG system (Ollama + Qdrant), not a purely rule-based recommendation engine — though deterministic guardrails (nutrition calculators, safety checks) also run alongside the LLM. The separate InBody photo-extraction feature calls the Anthropic Claude API, which is a distinct integration from the Ollama-based coaching chat. Neither of these is a substitute for medical advice — see the disclaimer in [5.17 Conclusion](../5.17-Conclusion/).
{{% /notice %}}

### Desired Outcome

A working MVP reachable over the internet, backed by Amazon RDS, with container images in Amazon ECR, running on Amazon EC2, with basic monitoring and alerting — documented step by step with evidence, not assumptions.

### MVP Scope

See [Proposal Section 8](../../2-Proposal/#8-mvp-scope) for the full list. In short: frontend, application gateway, auth-service, user-service, fitness-service, ai-service (with Ollama and Qdrant as containers), and PostgreSQL migrated to Amazon RDS.

### Components Excluded from MVP

- `chat-service`, `gym-service`, `payment-service` (the latter two currently lack a production Dockerfile in source).
- Amazon S3 (uploads remain on local disk for the MVP — no S3 client exists in the application source today).
- Amazon ElastiCache, Amazon Bedrock, Amazon CloudFront, Amazon Route 53, Application Load Balancer, Auto Scaling, CI/CD, and Infrastructure as Code — all listed as Optional/Future in the [Proposal](../../2-Proposal/#25-future-development).

### Deliverables

- This documented Workshop with reproducible steps.
- Production Dockerfile examples for MVP services.
- `docker-compose.aws.example.yml` describing the EC2 deployment.
- Architecture diagram (draw.io source + exported PNG) — TODO, pending final implementation.
- IAM policy and Security Group examples.
- A test case table with evidence status.

### Definition of Done

- Every AWS service marked "Implemented" elsewhere in this report is backed by a screenshot, log excerpt, or command output in this Workshop.
- No step here claims success without a corresponding Evidence subsection, even if that subsection currently says `TODO`.
