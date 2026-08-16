---
title: "Week 2 Worklog"
date: 2026-08-10
weight: 2
chapter: false
pre: " <b> 1.2. </b> "
---

### Week 2 Objectives:

- Research workshop template repository to learn proper report format.
- Continue learning important AWS labs: IAM Role, S3, Lightsail, Auto Scaling, CloudWatch, Route 53, AWS CLI.
- Start analyzing personal project source code to prepare AWS architecture design.

### Tasks for This Week:

| Task | Start Date | Completion Date | Workshop / Reference Materials |
|------|------------|----------------|--------------------------------|
| - Analyze workshop template repo <br/> - Learn labs on IAM Role, S3, CloudWatch, Auto Scaling <br/> - Read project source code to understand structure | 08-10-2026 | 08-15-2026 | 48: https://000048.awsstudygroup.com/ <br/> 57: https://000057.awsstudygroup.com/ <br/> 45: https://000045.awsstudygroup.com/ <br/> 06: https://000006.awsstudygroup.com/ <br/> 08: https://000008.awsstudygroup.com/ <br/> 10: https://000010.awsstudygroup.com/ <br/> 11: https://000011.awsstudygroup.com/ |
| - Office work visit <br/> - Research blog about Docker and Amazon ECR | 08-12-2026 | 08-12-2026 | AWS Blog: https://aws.amazon.com/blogs/containers/automated-software-delivery-using-docker-compose-and-amazon-ecs <br/> Lab: https://000067.awsstudygroup.com/ (Monolith to Microservices) |

### Week 2 Results:

**Overview:**

This week had 2 main areas: one is continuing AWS labs to master more important services, two is starting to read and understand project source code for easier AWS architecture design later. Also researched workshop template repo to know how to write reports following FCAJ format requirements.

**Knowledge Learned:**

- **IAM Roles for Applications:** Last week learned IAM users, this week learned IAM Role - how to let EC2 or Lambda access other services (S3, RDS...) without hardcoding access keys. Important best practice for security.

- **Amazon S3:** Understood S3 is object storage, different from block storage (EBS). Did labs creating buckets, uploading files, configuring public access, versioning. S3 is cheap and convenient but need to be careful with permissions.

- **Cost Optimization & Lightsail:** Learned ways to save money when using AWS (Reserved Instance, Spot Instance, S3 Intelligent-Tiering). Lightsail is like a simpler VPS than EC2, fixed monthly price, suitable for small apps.

- **Auto Scaling:** Mechanism to automatically increase/decrease EC2 instances based on load. Combined with Load Balancer to ensure app is always available when traffic spikes. Concepts of Launch Template and scaling policy.

- **Amazon CloudWatch:** Service to monitor metrics (CPU, memory, network) and create alarms. Important to know when app has errors or is overloaded. Can send notifications via SNS.

- **Route 53:** AWS DNS service, learned how to create hosted zone, A records, CNAME. Has Hybrid DNS feature with Route 53 Resolver to connect on-premise DNS with AWS.

- **AWS CLI:** Practiced many CLI commands to manage resources instead of using Console. Faster and can script automation. Learned how to config credentials, use --query to filter JSON output.

**Hands-on Practice:**

- Analyzed workshop template repo, understood folder structure: content/, static/, config.toml. Learned how to use Hugo to generate static site.
- Completed 7 labs from 000048 to 000011, practiced with IAM Role, S3, Lightsail, Auto Scaling, CloudWatch, Route 53 and AWS CLI.
- Read personal project source code (fitness-assistant or similar project), noted tech stack: what frontend uses (React/Vue?), backend (Node/Python?), database (PostgreSQL/MySQL?).
- Listed services/ports: which port frontend runs on, which port backend API, is it microservices or monolith.
- Visited office for work on Tuesday August 12, familiarized with environment and setup workspace.
- Read and researched blog "From Development Container to Production-ready Microservices with Docker and Amazon ECR" to prepare for containerizing project later. This blog is good because it clearly explains the flow from local dev with Docker to pushing images to ECR and deploying to production.

**Difficulties Encountered:**

1. **Route 53 domain cost:** Want to practice Route 53 fully need to buy domain but domains on Route 53 are a bit expensive ($.12+ for .com). Tried using Freenom free domain but doesn't integrate well with Route 53.

2. **Auto Scaling policy confusion:** There are many types of scaling policies: target tracking, step scaling, simple scaling. Not clear when to use which, how to configure threshold appropriately.

3. **CloudWatch custom metrics:** CloudWatch by default only has basic metrics (CPU, network). To monitor app-level metrics (request count, error rate) must push custom metrics yourself, a bit complex.

4. **Source code without .env.example:** When reading project source code there was no `.env.example` file, had to read code to guess what environment variables are needed. Time consuming and error prone.

5. **Distinguishing API routing vs API Gateway:** In code there's Express router (internal routing) but AWS has a service called API Gateway. Initially confused between these 2 concepts when drawing architecture.

**Solutions:**

- **Route 53 domain:** Temporarily practice with subdomain on free domain or use existing domain. DNS part is mainly understanding concepts of hosted zone, record types, TTL.

- **Auto Scaling policy:** Read AWS docs and best practices. For typical web apps, using target tracking policy with 70% CPU is simplest and most effective. Step scaling is for more complex patterns.

- **CloudWatch custom metrics:** Learned how to use CloudWatch agent or SDK to push metrics from app. But for MVP stage, using basic metrics combined with application logs is sufficient.

- **Environment variables:** Listed all env variables by grepping in code: `grep -r "process.env" .` or `grep -r "os.getenv" .`. Created separate note file to track.

- **API Gateway:** Noted clearly: Express router = code logic to route requests in app. API Gateway = AWS managed service for API endpoint, authentication, rate limiting. Two completely different things.
