---
title: "Week 5 Worklog"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 1.5. </b> "
---

# WEEK 5 WORKLOG

### Week 5 Objectives:

- Complete Module 3: Optimizing the system, focusing aggressively on System Performance and Cost Optimization strategies
- Complete Module 4: Modernize the application by exploring and implementing Serverless and Microservices architectures

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Complete Module 3: Optimizing the system | 17-7-2026 | 23-7-2026 | **Module 3 - Performance:** <br>15: https://000015.awsstudygroup.com/ <br>16: https://000016.awsstudygroup.com/ <br>17: https://000017.awsstudygroup.com/ <br>23: https://000023.awsstudygroup.com/ <br>24: https://000024.awsstudygroup.com/ <br>25: https://000025.awsstudygroup.com/ <br>35: https://000035.awsstudygroup.com/ <br>**Module 3 - Optimizing costs:** <br>32: https://000032.awsstudygroup.com/ <br>34: https://000034.awsstudygroup.com/ <br>40: https://000040.awsstudygroup.com/ <br>42: https://000042.awsstudygroup.com/ |
| Complete Module 4: Modernize the application | 17-7-2026 | 23-7-2026 | **Module 4 - Modernize the application:** <br>47: https://000047.awsstudygroup.com/ <br>50: https://000050.awsstudygroup.com/ <br>51: https://000051.awsstudygroup.com/ <br>52: https://000052.awsstudygroup.com/ <br>53: https://000053.awsstudygroup.com/ <br>54: https://000054.awsstudygroup.com/ <br>55: https://000055.awsstudygroup.com/ <br>56: https://000056.awsstudygroup.com/ |

### Week 5 Achievements:

**Overview:**

During this intensive week, I accomplished two major tracks: system performance/cost optimization (Module 3) and application modernization (Module 4). The extensive lab workload spanned containerization, robust serverless computing, data lakes, and complex cost analytics.

**Note:** Certain sections within the modernization labs (specifically 47, 54, and 55) mandated the use of AWS Cloud9. As AWS Cloud9 is currently inaccessible in my environment, these specific sections were strategically skipped, while the underlying architectural concepts were still thoroughly studied.

**Learned theory:**

- **Performance & Cost Optimization:** Learned deployment paradigms using Docker and Amazon ECS. Mastered CI/CD automation with AWS CodePipeline. Studied Data Lake foundations and explored financial governance via Savings Plans, EC2 right-sizing, and AWS Glue/Athena querying.

- **Modernization & Microservices:** Grasped architectural patterns for migrating monolithic applications to microservices. Explored decoupled messaging/eventing systems and integrating orchestration tools like AWS Step Functions.

- **Serverless Architecture:** Deepened my expertise in the serverless ecosystem utilizing AWS Lambda, Amazon API Gateway, the Serverless Application Model (SAM), Amazon Cognito for identity, SQS/SNS for asynchronous processing, and AppSync.

**Hands-on labs:**

- Successfully deployed containerized applications on ECS, integrating them with automated CI/CD pipelines
- Configured enterprise storage solutions including File Storage Gateways and FSx for Windows, alongside Data Lake optimizations
- Executed advanced cost tracking and query analysis utilizing AWS Glue and Amazon Athena
- Engineered and deployed fully serverless applications (e.g., Serverless Bookstore), encompassing frontend API integration, SSL setup, CI/CD workflows, and CloudWatch/X-Ray distributed tracing
- Skipped specific execution steps in Labs 47, 54, and 55 due to an inability to provision AWS Cloud9 environments, though the theoretical framework for Step Functions, Messaging/Eventing, and SPA configurations was thoroughly reviewed

**Applied to Fitness Assistant:**

**Performance Optimization:**
- Evaluated containerization strategy: migrating from Docker Compose to Amazon ECS for better scaling and management
- Designed CI/CD pipeline: GitHub → AWS CodePipeline → CodeBuild → ECR → ECS deployment
- Considered CloudFront CDN for frontend assets to reduce latency

**Cost Optimization:**
- Right-sizing analysis: monitored EC2 utilization, identified opportunities to downsize instances
- Implemented tagging strategy for cost allocation by service (auth-service, fitness-service, ai-service)
- Researched Savings Plans and Reserved Instances for predictable workloads
- Set up AWS Budgets and Cost Anomaly Detection alerts

**Modernization Path:**
- Evaluated serverless migration for specific workloads:
  - Notification service → Lambda + SQS
  - Image processing (nutrition labels) → Lambda triggered by S3
  - Daily stats aggregation → Lambda with scheduled EventBridge rules
- Planned microservices decomposition strategy (future enhancement when scaling)
- Considered API Gateway to replace application gateway container (better managed service)

### Difficulties Encountered:

- **Cloud9 Limitation:** Unable to access AWS Cloud9 (possibly due to region restrictions or account limitations), resulting in skipped hands-on steps in labs 47, 54, 55. However, conceptual learning was maintained through documentation and video tutorials.

- **Containerization Complexity:** Understanding the difference between Docker Compose (local dev) and ECS (production) required learning curve about task definitions, services, and clusters.

- **Serverless Cold Start Trade-offs:** When researching Lambda migration, realized cold start latency could impact user experience for synchronous APIs. Needed to carefully evaluate which workloads are suitable for serverless.

- **Cost Calculation Complexity:** AWS cost model is very granular (per request, per GB-second, data transfer costs). Difficult to forecast costs accurately when planning serverless migration.

### How It Was Resolved:

- **Cloud9 Workaround:** Used local development environment with AWS CLI and SAM CLI to simulate Cloud9 workflows. Read lab documentation thoroughly to understand intended outcomes.

- **ECS Learning:** Drew comparison diagrams between Docker Compose concepts and ECS equivalents. Practiced with simple containerized apps before applying to Fitness Assistant.

- **Cold Start Mitigation:** Researched provisioned concurrency for critical Lambda functions. Planned hybrid approach: keep synchronous APIs on containers, async workloads on Lambda.

- **Cost Forecasting:** Used AWS Pricing Calculator to estimate costs. Set up granular billing alerts. Planned phased migration to monitor costs incrementally.

### AWS Skills / Services Learned:

**Services - Containerization & CI/CD:**
- Amazon ECS (Elastic Container Service)
- Amazon ECR (Elastic Container Registry)
- AWS CodePipeline
- AWS CodeBuild
- AWS CodeDeploy

**Services - Serverless:**
- AWS Lambda
- Amazon API Gateway
- AWS SAM (Serverless Application Model)
- Amazon Cognito
- Amazon SQS/SNS
- AWS AppSync
- AWS Step Functions

**Services - Storage & Data:**
- AWS Storage Gateway
- Amazon FSx
- AWS Glue
- Amazon Athena
- Data Lake architecture

**Services - Cost & Monitoring:**
- AWS Cost Explorer
- AWS Budgets
- Savings Plans
- Amazon CloudWatch
- AWS X-Ray (distributed tracing)

**Skills:**
- Container orchestration with ECS
- CI/CD pipeline design and implementation
- Serverless architecture patterns
- Cost optimization strategies
- Data Lake design fundamentals
- Distributed tracing and observability

### Connection to Fitness Assistant Architecture:

**Immediate Applications:**
- Containerize all services and deploy to ECS instead of single EC2
- Set up CI/CD pipeline for automated deployments
- Implement CloudWatch monitoring and X-Ray tracing

**Future Enhancements:**
- Migrate notification service to Lambda + SQS
- Implement API Gateway for better API management
- Build data lake for workout analytics and user behavior analysis

### Related Workshop Sections:

- [5.6 Network Infrastructure](../../5-Workshop/5.6-Network-Infrastructure/) - VPC design for ECS
- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - Container deployment strategies
