---
title: "Week 6 Worklog"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 1.6. </b> "
---

# WEEK 6 WORKLOG

### Week 6 Objectives:

- Complete Module 5: Container services
- Master the orchestration and deployment of containerized applications across Lightsail, ECS, and EKS
- Engage with the professional community and integrate further into the office environment
- Deploy the Gym and Payment services, and plan where the Chat service will run

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 5: Container services | 07-9-2026 | 12-9-2026 | 46: https://000046.awsstudygroup.com/ <br>67: https://000067.awsstudygroup.com/ <br>152: https://000152.awsstudygroup.com/ |
| Deploy the Gym and Payment services (databases, functions and schedules) | 08-9-2026 | 08-9-2026 | [5.4.6 Gym Service](../../5-Workshop/5.4-Deployment-Guide/5.4.6-Gym-Service/) <br>[5.4.7 Payment Service](../../5-Workshop/5.4-Deployment-Guide/5.4.7-Payment-Service/) |

### Week 6 Achievements:

**Overview:**

During this week, I focused on AWS Container services (Module 5), exploring how to run and orchestrate containers at varying scales of complexity using Amazon Lightsail, ECS, and EKS. On 8 September I also deployed the Gym and Payment services. Beyond technical skill acquisition, I deepened my professional involvement by working from the office for the second time and actively participating in a weekend technology meetup.

**Learned theory:**

- **Amazon Lightsail Containers:** Learned how to rapidly deploy and run containerized applications within a simplified, predictable pricing environment.

- **Amazon ECS & Fargate:** Understood the architectural strategies for modernizing legacy Monolithic applications into Microservices utilizing Docker, Amazon ECS, and the serverless AWS Fargate compute engine.

- **Amazon EKS & CI/CD:** Grasped the fundamentals of Kubernetes cluster management on AWS (EKS) and learned how to establish a continuous integration and continuous delivery (CI/CD) pipeline using AWS CodePipeline for automated container deployments.

- Gained valuable networking and professional experience by attending community events and integrating into the workplace.

**Hands-on labs:**

- Successfully deployed a containerized application utilizing Amazon Lightsail Containers
- Migrated a monolithic application to a microservices architecture using Docker, orchestrating the deployment via ECS and Fargate
- Configured a robust CI/CD pipeline for Amazon EKS using AWS CodePipeline to automate Kubernetes deployments

**Applied to Fitness Assistant:**

**Container Strategy Evaluation:**

By this week Auth, User and Fitness were running on Lambda (see [Week 5](../1.5-Week5/)), and Gym and Payment followed on 8 September. The question for this week was narrower: where should the one service that needs a long-running process run? That service is Chat, which keeps a Socket.IO connection open for every user. I compared the three platforms from the module:

1. **Amazon Lightsail Containers:**
   - **Pros:** Simple setup, predictable pricing ($10-40/month), good for MVP
   - **Cons:** Limited scaling, and harder to integrate with the private VPC, per-service IAM roles and Secrets Manager used by the rest of the design
   - **Decision:** Not used

2. **Amazon ECS with Fargate:**
   - **Pros:** Serverless (no server management), good AWS integration, cost-effective for small-medium scale
   - **Cons:** Vendor lock-in (AWS-specific), learning curve
   - **Decision:** **Chosen for the Chat service**, deployed in [Week 8](../1.8-Week8/). The same cluster can also run one-off tasks, later used for the database migration job

3. **Amazon EKS (Kubernetes):**
   - **Pros:** Industry standard, portable, powerful orchestration
   - **Cons:** Complex setup, a control-plane fee for every cluster, overkill for a single container service
   - **Decision:** Not needed at this scale

**Implementation Plan for the Chat Service:**

**Phase 1 - Image and registry:**
- Build the production image of chat-service for `linux/amd64`
- Push it to a private Amazon ECR repository in the same region

**Phase 2 - Task and service:**
- One task definition: 0.5 vCPU / 1 GB, container port 3005, database URL and internal secret injected from Secrets Manager
- One ECS service with the Fargate launch type in the private application subnets

**Phase 3 - Load balancer and routing:**
- Internet-facing Application Load Balancer in the public subnets, with an IP target group checked on `/health`
- Target-group stickiness and a longer idle timeout, so Socket.IO connections are not cut
- Listener rules that answer `/internal/*` and `/metrics` with 404; REST calls under `/chat/*` reach the ALB through API Gateway

**Later:**
- Run more than one Chat task only after adding a shared Socket.IO adapter (session state is kept in memory today)
- CI/CD for the image; CloudWatch Container Insights and an alarm on target health

**Architecture Comparison:**

*First plan (lift-and-shift onto one host):*
```
User → EC2 (Docker Compose with all services, Ollama, Qdrant, Redis) → RDS
```

*Chosen design:*
```
Browser → S3 static website (frontend)
Browser → API Gateway (HTTP API) → Lambda (auth, user, fitness, gym, payment, ai) → Aurora PostgreSQL
Browser → Chat ALB (Socket.IO; REST through API Gateway /chat/*) → ECS Fargate (chat) → Aurora PostgreSQL
```

### Difficulties Encountered:

- **ECS vs EKS Decision:** Initially confused about when to use ECS vs EKS. ECS simpler but AWS-specific, EKS industry standard but much more complex.

- **Task Definition Complexity:** ECS Task Definitions have many configuration options (CPU, memory, networking mode, volume mounts, environment variables, secrets). Hard to optimize correctly.

- **Fargate Pricing Model:** Fargate pricing based on vCPU and memory allocated per second, and the load balancer in front of it is a fixed monthly cost. At DEV traffic, the always-on chat path costs more than all six Lambda services together.

- **Service-to-service calls:** In Docker Compose the services call each other by hostname on a shared network. Neither Lambda functions nor a Fargate task behind a load balancer have that, and AWS Cloud Map for service discovery has its own learning curve.

### How It Was Resolved:

- **Platform Decision:** ECS on Fargate for Chat only: production-ready, AWS-integrated, manageable complexity, lower cost than EKS. EKS stays an option if the project ever needs Kubernetes or multi-cloud portability.

- **Task Definitions:** Started from the smallest task definition that works (one container, one port, secrets from Secrets Manager) and kept every change as a new revision.

- **Cost Management:** Used AWS Pricing Calculator to estimate Fargate and ALB costs. Kept Chat at one small task that can be scaled to zero between test sessions; Savings Plans only if a steady baseline appears.

- **Service-to-service calls:** No Cloud Map: internal calls are direct Lambda invocations on exact function ARNs that carry a shared internal secret, and the chat task calls Auth and User the same way. API Gateway has no `/internal/*` route, so these endpoints are never public.

### AWS Skills / Services Learned:

**Services:**
- Amazon Lightsail Containers
- Amazon ECS (Elastic Container Service)
- AWS Fargate (serverless compute for containers)
- Amazon EKS (Elastic Kubernetes Service)
- AWS CodePipeline (for container CI/CD)
- Amazon ECR (Elastic Container Registry)
- AWS Cloud Map (service discovery)
- Application Load Balancer (ALB)
- AWS Copilot CLI

**Skills:**
- Container orchestration strategies
- ECS vs EKS evaluation and selection
- Fargate serverless container management
- Kubernetes fundamentals (EKS)
- CI/CD pipeline design for containers
- Microservices deployment patterns
- Service discovery and inter-service communication
- Container cost optimization

### Connection to Fitness Assistant Architecture:

**Immediate Actions:**
- Production Dockerfile for chat-service (the other services are packaged as Lambda ZIP files instead of images)
- One task definition and one ECS service for Chat
- ALB rules for Socket.IO and for hiding internal paths

**Medium-term Goals:**
- Implement full CI/CD pipeline
- Shared Socket.IO adapter before scaling Chat beyond one task
- Alarm on the chat target's health

### Related Workshop Sections:

- [5.4.1 Shared network infrastructure](../../5-Workshop/5.4-Deployment-Guide/5.4.1-Shared-Network/) - VPC, subnets and NAT setup
- [5.4.10 Chat Service on ECS Fargate](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/) - Container deployment on ECS Fargate behind an ALB
