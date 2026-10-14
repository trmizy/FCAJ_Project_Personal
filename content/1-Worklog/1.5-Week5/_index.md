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

During this intensive week, I accomplished two major tracks: system performance/cost optimization (Module 3) and application modernization (Module 4). The extensive lab workload spanned containerization, robust serverless computing, data lakes, and complex cost analytics. Module 4 also answered the biggest design question of the project: most of the Fitness Assistant does not need servers at all.

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

**Modernization Path (the main design decision):**
- The application is already split into services (auth, user, fitness, gym, payment, ai, chat) that run together with Docker Compose locally. Six of them only answer short HTTP requests or run scheduled jobs, which is exactly the Lambda model; only chat has to keep a Socket.IO connection open.
- Decision: run the six HTTP services as Lambda functions behind one API Gateway HTTP API, which replaces the application gateway container as the single entry point.
- Scheduled work (session settlement, workout reminders, payouts, payment reconciliation, AI knowledge refresh) moves from timers inside the process to EventBridge Scheduler, which invokes one jobs function per service.
- Long AI work (workout and nutrition plan generation) moves to an SQS queue and a worker function, so no HTTP call has to wait past API Gateway's ~30-second limit. This also replaces the Redis/BullMQ queue, which would have needed a cache cluster running all the time.
- Chat stays a container; where to run it is evaluated in [Week 6](../1.6-Week6/).

**Performance Optimization:**
- Memory is the only sizing setting on Lambda (CPU grows with it), so there are no instance types to right-size
- Considered CloudFront CDN for frontend assets to reduce latency, postponed until the site has a domain and HTTPS

**Cost Optimization:**
- Pay-per-use services for the application tier (Lambda, HTTP API, which is cheaper than a REST API, SQS, EventBridge Scheduler) and Aurora Serverless v2 instead of a fixed-size database instance
- Listed the costs that remain while the app is idle (NAT Gateway, load balancer, VPC endpoints, the database's capacity floor); they became the main lines of the [budget](../../2-Proposal/#budget)
- One naming scheme for every resource (`fitness-assistant-dev-<service>-…`), so cost and clean-up can be filtered per service
- Researched Savings Plans for predictable workloads (Compute Savings Plans also cover Lambda and Fargate)
- Set up AWS Budgets and Cost Anomaly Detection alerts

**CI/CD:**
- Sketched a pipeline: build each service's Lambda package into the deployments bucket and the chat image into ECR, then update the functions and the ECS service. Not built yet: deployments are manual and documented step by step in [5.4](../../5-Workshop/5.4-Deployment-Guide/), and CI/CD is the largest open item.

### Difficulties Encountered:

- **Cloud9 Limitation:** Unable to access AWS Cloud9 (possibly due to region restrictions or account limitations), resulting in skipped hands-on steps in labs 47, 54, 55. However, conceptual learning was maintained through documentation and video tutorials.

- **Mapping Docker Compose to serverless:** In Docker Compose every service is a long-running container that calls the others by hostname. On Lambda there is no long-running process and no hostname, so in-process timers, the Redis queue and service-to-service calls all had to change.

- **Serverless Cold Start Trade-offs:** When researching Lambda migration, realized cold start latency could impact user experience for synchronous APIs. Needed to carefully evaluate which workloads are suitable for serverless.

- **Cost Calculation Complexity:** AWS cost model is very granular (per request, per GB-second, data transfer costs). Difficult to forecast costs accurately when planning serverless migration.

### How It Was Resolved:

- **Cloud9 Workaround:** Used local development environment with AWS CLI and SAM CLI to simulate Cloud9 workflows. Read lab documentation thoroughly to understand intended outcomes.

- **Mapping:** Listed every long-running part of each service and chose a managed replacement for each: timers → EventBridge Scheduler and a jobs function, Redis/BullMQ → SQS and a worker, sockets → the chat container on ECS, service-to-service HTTP calls → direct Lambda invocations on exact function ARNs.

- **Cold Start Mitigation:** Accepted cold starts for the DEV environment, where they only affect the first request after an idle period. Provisioned concurrency remains the option for production, so the synchronous APIs did not need to stay on containers.

- **Cost Forecasting:** Used AWS Pricing Calculator to estimate costs. Set up granular billing alerts. Planned to deploy one service at a time so the cost of each step could be checked.

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
- Six HTTP services on Lambda behind one API Gateway HTTP API
- Scheduled jobs on EventBridge Scheduler; long AI tasks through SQS and a worker function
- CloudWatch Logs for every function; X-Ray tracing as a later addition

**Future Enhancements:**
- CI/CD pipeline for the Lambda packages and the chat image
- CloudFront and HTTPS for the frontend
- Build data lake for workout analytics and user behavior analysis

### Related Workshop Sections:

- [5.2.4 AWS Services and Selection Rationale](../../5-Workshop/5.2-Architecture-Description/5.2.4-AWS-Services-Selection/) - Why Lambda, API Gateway, SQS and EventBridge Scheduler
- [5.4.2 Auth Service and API Gateway](../../5-Workshop/5.4-Deployment-Guide/5.4.2-Auth-Service-API-Gateway/) - The first service deployed with this pattern
