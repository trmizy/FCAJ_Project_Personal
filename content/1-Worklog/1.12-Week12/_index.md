---
title: "Week 12 Worklog"
date: 2026-07-15
weight: 12
chapter: false
pre: " <b> 1.12. </b> "
draft: false
---

# WORKLOG WEEK 12

### Week 12 Objectives:

- Finalize and aggregate 12-week technical worklog documentation for culminating internship report

### Work Completed This Week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Finalized and aggregated 12-week technical worklog documentation for culminating internship report | 19-10-2026 | 19-10-2026 | |

### Week 12 Results:

**Overview:**

In this final week, my primary operational focus was to review, refine, and aggregate comprehensive 12-week worklog documentation. This effort served to systematize all knowledge and outcomes achieved throughout the internship and project lifecycle, ensuring full readiness for the final internship report.

**Theoretical Knowledge Gained:**

- **Documentation and Reporting:** Enhanced skills in systematizing information and presenting technical documentation in a clear, professional, and logical manner.

- **Retrospective Assessment:** Systematically reviewed the entire project lifecycle, from ideation and architectural design to infrastructure deployment and environment testing.

**Hands-on Labs Completed:**

- Completed detailed documentation for all internship weeks within worklog system
- Conducted thorough reviews of spelling, grammar, and overall document formatting
- Packaged all finalized materials to support a polished and professional final report

**Fitness Assistant Project Summary:**

**Architecture Delivered (DEV environment, `ap-southeast-1`):**
- Six services on AWS Lambda (12 long-lived functions for HTTP, scheduled jobs and the AI worker) behind one API Gateway HTTP API
- Aurora PostgreSQL Serverless v2: one cluster with seven logical databases, credentials in Secrets Manager
- Chat (REST + Socket.IO) on ECS Fargate behind an Application Load Balancer
- AI on Amazon Bedrock (Nova Pro, Cohere Embed Multilingual v3) with vector search on OpenSearch Serverless, long jobs through SQS and 13 EventBridge Scheduler schedules
- Private networking: Lambda, Fargate and Aurora in private subnets, one NAT Gateway, VPC endpoints for Secrets Manager and OpenSearch
- Data moved from the local databases with a one-off Fargate task: 7 of 7 databases restored, 23 of 23 foreign keys validated

**Technical Skills Gained:**
- Serverless: AWS Lambda, API Gateway (HTTP API), Amazon SQS, EventBridge Scheduler
- Databases: Aurora PostgreSQL Serverless v2, schema migrations run by dedicated Lambda functions, restoring dumps with an ECS task
- Containers: Docker, Amazon ECR, ECS Fargate, Application Load Balancer
- AI/ML: Amazon Bedrock and OpenSearch Serverless vector search in the project; SageMaker in Module 7
- Networking and security: VPC design, security groups that reference each other, least-privilege IAM per function, Secrets Manager
- Data analytics (Glue, Athena, QuickSight) from Module 6

**Community Contributions:**
- Published technical blogs about cost optimization and security
- Participated in FCAJ Community Day events
- Shared knowledge with AWS Study Group VN community

**Project Outcomes:**
- Architecture description and diagrams ([Workshop 5.2](../../5-Workshop/5.2-Architecture-Description/))
- Step-by-step deployment guide with console screenshots ([Workshop 5.4](../../5-Workshop/5.4-Deployment-Guide/))
- Test plan and results ([5.5](../../5-Workshop/5.5-Test-Validation/)): Auth and User verified end to end; Fitness, Gym, Payment, AI, Chat and the frontend are deployed and waiting for the final end-to-end pass
- Cost estimate with a "sleep mode" for idle time ([Proposal §8](../../2-Proposal/#budget)) and a complete clean-up order ([5.7](../../5-Workshop/5.7-Cleanup/))
- Still open: CI/CD pipeline, CloudWatch alarms, HTTPS with CloudFront
