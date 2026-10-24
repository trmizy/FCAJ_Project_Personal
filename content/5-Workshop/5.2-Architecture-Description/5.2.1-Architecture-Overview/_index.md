---
title: "Architecture Overview"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.2.1. </b> "
---

### Components

**Shared infrastructure**

- One VPC (`fitness-assistant-dev-vpc`, `10.0.0.0/16`, `ap-southeast-1`).
- Two private application subnets (Lambda functions and the Chat Fargate task), two public subnets (only the NAT Gateway and the Chat ALB sit there), and private DB subnets with no internet route at all.
- One shared Lambda security group, used by every Lambda-based service, plus dedicated security groups for Aurora, the VPC endpoints, the Chat task and the Chat ALB.
- One Internet Gateway and one NAT Gateway, so Lambdas in the private subnets can reach Amazon Bedrock and other AWS APIs outbound; interface VPC endpoints keep Secrets Manager and OpenSearch Serverless traffic private.

**Six Lambda-based microservices:** Auth, User, Fitness, Gym, Payment and AI, all behind one Amazon API Gateway HTTP API and sharing the VPC and security group above. Together they run 12 long-lived functions — each service has an HTTP function, User/Fitness/Gym/Payment/AI also have a scheduled jobs function, and AI adds a Worker fed by Amazon SQS — plus one migration function per service. Scheduled work is triggered by 13 Amazon EventBridge Scheduler schedules.

**One ECS Fargate service:** Chat, which handles both a REST API and a Socket.IO real-time connection. Socket.IO needs a connection that stays open for the life of a chat session — a shape Lambda's request/response model does not fit — so Chat runs as a container on Fargate in the private subnets, behind its own internet-facing Application Load Balancer. REST calls reach it through API Gateway (`/chat/{proxy+}`), Socket.IO connects to the ALB directly.

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

**Managed AI:** Amazon Bedrock (Nova Pro for chat and vision, Cohere Embed Multilingual v3 for 1024-dimension embeddings) and an Amazon OpenSearch Serverless vector collection (`fitness-assistant-dev-ai-vectors`, NextGen, scaling between 0 and 2 OCU), reached privately through a VPC endpoint.

**One static frontend** on Amazon S3 served through Amazon CloudFront (Origin Access Control).

### How This Differs From the Original MVP Plan

The earlier version of this Workshop planned a single EC2 host running the whole Docker Compose stack, one Amazon RDS instance, and a self-hosted Ollama + Qdrant pair for AI ([Week 6](../../../1-Worklog/1.6-Week6/) of the Worklog compares that plan with the chosen design). That plan's own "Future Architecture" note already named the direction this ended up taking: ECS/Fargate instead of a single host, and Amazon Bedrock instead of self-hosted Ollama. The real architecture went further: Lambda for six of the seven services, Aurora Serverless instead of a single RDS instance, and OpenSearch Serverless instead of Qdrant.

How each service was actually built is documented step by step in the [Deployment Guide](../../5.4-Deployment-Guide/); the pages from [5.2.2](../5.2.2-Architecture-Diagram/) onward describe the system as it stands now.
