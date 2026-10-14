---
title: "Week 8 Worklog"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 1.8. </b> "
draft: false
---

# WEEK 8 WORKLOG

### Week 8 Objectives:

- Complete Module 7: AI/ML service on AWS
- Experience AWS SageMaker through the Immersion Day workshop
- Continue integration into corporate environment
- Deploy the Chat service on ECS Fargate and migrate the local data to Aurora

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 7: AI/ML service on AWS | 21-9-2026 | 26-9-2026 | Lab 200: https://000200.awsstudygroup.com/ |
| Deploy the Chat service on ECS Fargate behind an Application Load Balancer | 22-9-2026 | 22-9-2026 | [5.4.10 Chat Service on ECS Fargate](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/) |
| Migrate the data of the seven local databases to Aurora with a one-off Fargate task | 23-9-2026 | 23-9-2026 | [5.4.11 Data migration to Aurora](../../5-Workshop/5.4-Deployment-Guide/5.4.11-Data-Migration/) |

### Week 8 Achievements:

**Overview:**

During this week, I shifted my focus to Artificial Intelligence and Machine Learning on AWS by completing Module 7. I gained practical exposure to AWS SageMaker through hands-on workshops. In addition, I continued to engage with the team and professional community. Alongside the module, I deployed the Chat service on ECS Fargate (22 September) and moved the data of the seven local databases to Aurora (23 September).

**Learned theory:**

- **AI/ML on AWS:** Understood the fundamentals of Machine Learning workflows on the cloud and core AWS services for ML lifecycle.

- **AWS SageMaker:** Learned how to build, train, and deploy machine learning models quickly using SageMaker's fully managed infrastructure.

**Hands-on labs:**

- Successfully completed the SageMaker Immersion Day workshop (Lab 200), getting hands-on experience with deploying and testing ML models
- Experimented with SageMaker features: notebook instances, training jobs, model deployment, real-time inference endpoints

**Applied to Fitness Assistant:**

Identified ML use cases: workout recommendations enhancement, exercise form analysis, personalized nutrition, progress prediction, and churn prediction. Compared SageMaker with the Amazon Bedrock setup that had replaced the self-hosted Ollama model the week before (Ollama needed a larger EC2 instance, manual scaling and maintenance; Bedrock is billed per request), based on cost, control, and scalability considerations.

### Difficulties Encountered:

- **SageMaker Learning Curve:** Many components overwhelming initially
- **Cost Understanding:** Complex pricing model difficult to estimate
- **Model Selection:** Confusion about when to use which AWS ML service
- **Integration Planning:** Unclear how to integrate with existing architecture

### How It Was Resolved:

- Completed full workshop end-to-end
- Used AWS Pricing Calculator for cost analysis
- Created decision matrix for service selection
- Designed architecture diagram for SageMaker endpoint integration

### AWS Skills / Services Learned:

**Services:**
- Amazon SageMaker (full lifecycle)
- Amazon Bedrock (overview)
- Amazon Rekognition (overview)

**Skills:**
- ML workflow on AWS cloud
- Managed vs self-hosted trade-off analysis
- Cost optimization for ML workloads

### Related Workshop Sections:

- [5.4.8 AI Service — database, queue and Bedrock](../../5-Workshop/5.4-Deployment-Guide/5.4.8-AI-Service-Core/) - AI service deployment on Amazon Bedrock
- [5.4.10 Chat Service on ECS Fargate](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/) - Deployed this week
- [5.4.11 Data migration to Aurora](../../5-Workshop/5.4-Deployment-Guide/5.4.11-Data-Migration/) - 7 of 7 databases restored this week
