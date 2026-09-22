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

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 5: Container services | 24-7-2026 | 30-7-2026 | 46: https://000046.awsstudygroup.com/ <br>67: https://000067.awsstudygroup.com/ <br>152: https://000152.awsstudygroup.com/ |

### Week 6 Achievements:

**Overview:**

During this week, I focused exclusively on AWS Container services (Module 5), exploring how to run and orchestrate containers at varying scales of complexity using Amazon Lightsail, ECS, and EKS. Beyond technical skill acquisition, I deepened my professional involvement by working from the office for the second time and actively participating in a weekend technology meetup.

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

After learning 3 container platforms, evaluated the best fit for Fitness Assistant:

1. **Amazon Lightsail Containers:**
   - **Pros:** Simple setup, predictable pricing ($10-40/month), good for MVP
   - **Cons:** Limited scaling, not suitable for production growth
   - **Decision:** Possible for initial prototype testing

2. **Amazon ECS with Fargate:**
   - **Pros:** Serverless (no server management), good AWS integration, cost-effective for small-medium scale
   - **Cons:** Vendor lock-in (AWS-specific), learning curve
   - **Decision:** **Recommended choice for MVP** - balance between simplicity and production-readiness

3. **Amazon EKS (Kubernetes):**
   - **Pros:** Industry standard, portable, powerful orchestration
   - **Cons:** Complex setup, higher cost, overkill for current scale
   - **Decision:** Future consideration when scaling or need multi-cloud portability

**Implementation Plan for Fitness Assistant:**

**Phase 1 - ECS Migration (Immediate):**
- Containerize all services (auth, user, fitness, ai, gateway)
- Create ECS Task Definitions for each service
- Setup ECS Service with Fargate launch type
- Configure Application Load Balancer for routing
- Migrate from single EC2 → ECS cluster

**Phase 2 - CI/CD Pipeline:**
- GitHub repository → AWS CodePipeline trigger on push
- CodeBuild stage: build Docker images, run tests
- Push images → Amazon ECR
- CodeDeploy stage: deploy to ECS with blue/green deployment
- Automated rollback on failure

**Phase 3 - Advanced Features:**
- Service Auto Scaling based on CPU/memory
- Service Mesh with AWS App Mesh for advanced traffic management
- CloudWatch Container Insights for detailed monitoring

**Architecture Comparison:**

*Current (MVP on EC2):*
```
User → EC2 (Docker Compose with all services) → RDS
```

*After ECS Migration:*
```
User → ALB → ECS Services (independent auth/user/fitness/ai) → RDS
                ↓
            Fargate Tasks (auto-scale)
```

### Difficulties Encountered:

- **ECS vs EKS Decision:** Initially confused about when to use ECS vs EKS. ECS simpler but AWS-specific, EKS industry standard but much more complex.

- **Task Definition Complexity:** ECS Task Definitions have many configuration options (CPU, memory, networking mode, volume mounts, environment variables, secrets). Hard to optimize correctly.

- **Fargate Pricing Model:** Fargate pricing based on vCPU and memory allocated per second. Difficult to estimate costs accurately vs flat EC2 pricing.

- **Service Discovery:** When migrating to microservices on ECS, services need to communicate with each other. AWS Cloud Map for service discovery has learning curve.

### How It Was Resolved:

- **Platform Decision:** Decided to use ECS for MVP based on criteria: production-ready, AWS-integrated, manageable complexity, lower cost than EKS. Reserve EKS for future if need Kubernetes expertise or multi-cloud.

- **Task Definitions:** Started with simple task definitions, iterate gradually. Used AWS Copilot CLI (tool simplifying ECS deployments) for initial setup, then refine manually.

- **Cost Management:** Used AWS Pricing Calculator to estimate Fargate costs. Set up CloudWatch alarms for cost thresholds. Consider Savings Plans for Fargate if predictable baseline.

- **Service Discovery:** Implemented AWS Cloud Map for service-to-service communication. Combined with Environment Variables for flexibility.

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
- Design ECS cluster architecture
- Create production Dockerfiles (if not yet available)
- Plan Task Definitions for each service
- Design ALB routing rules

**Medium-term Goals:**
- Implement full CI/CD pipeline
- Setup auto-scaling policies
- Migrate production traffic from EC2 → ECS

### Related Workshop Sections:

- [5.6 Network Infrastructure](../../5-Workshop/5.6-Network-Infrastructure/) - VPC and ALB setup
- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - Container migration strategy
