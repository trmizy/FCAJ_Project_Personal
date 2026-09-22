---
title: "Week 8"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 1.8. </b> "
draft: false
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available. Do not replace them with invented dates.
{{% /notice %}}

# WEEK 8 WORKLOG

### Week 8 Objectives:

- Complete Module 7: AI/ML on AWS, and understand how AWS offers managed machine learning infrastructure through Amazon SageMaker.
- Attend the SageMaker Immersion Day workshop (Lab 200) to get hands-on exposure to a managed ML workflow, as a point of comparison against the self-hosted LLM approach already used in the Fitness Assistant's `ai-service`.
- Complete the 3rd required on-site office day.
- Continue the personal project: deploy the MVP container stack to EC2, building on the ECR image and IAM Role set up in Week 7.

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 7: AI/ML on AWS, including SageMaker Immersion Day | [TODO_DATE] | [TODO_DATE] | 200: https://000200.awsstudygroup.com/ |
| Deploy the MVP stack to EC2 (personal project) | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |

### Week 8 Achievements:

**Overview:**

This week was split between the FCJ curriculum (Module 7: AI/ML on AWS) and the personal project's own AI component. Studying SageMaker's managed ML infrastructure turned out to be a useful reference point for a decision already made in the Fitness Assistant project: its `ai-service` runs a self-hosted LLM (Ollama, default model `llama3.2:3b`) and vector database (Qdrant) instead of calling a managed AWS ML endpoint.

**Learned theory:**

- **Amazon SageMaker fundamentals:** how SageMaker removes the undifferentiated heavy lifting of provisioning training and inference infrastructure — managed notebook instances, built-in algorithms, and one-click model deployment to hosted endpoints.
- **Managed vs. self-hosted inference trade-off:** a SageMaker endpoint bills per instance-hour while it is running and scales through configuration, whereas a self-hosted LLM on EC2 has a fixed cost but requires the operator to size and manage the instance directly — directly relevant to the `ai-service` sizing question already on the table for this project.

**Hands-on labs:**

- Completed the SageMaker Immersion Day workshop (Lab 200): created a notebook instance, trained a sample model, and deployed it to a real-time inference endpoint.
- Attended the 3rd on-site office day.
- Continued the personal project's EC2 deployment: launched an EC2 instance in the public subnet, attached the IAM Role created in Week 7, and applied the EC2 Security Group from Week 5.
- Installed Docker Engine and the Docker Compose plugin, logged in to ECR, and pulled the MVP images.
- Wrote a `docker-compose.aws.example.yml` describing how the MVP services (frontend, gateway, auth-service, user-service, fitness-service, ai-service) are wired together on EC2, pointing `DATABASE_URL` at the RDS endpoint from Week 6 instead of a local Postgres container.
- Started the stack and checked container status and logs.

**Applied to Fitness Assistant:**

Working through the SageMaker lab made it easier to justify, in writing, why the project self-hosts its LLM instead of using a managed endpoint: at this project's scale, a fixed-cost EC2 instance running Ollama is cheaper than a per-hour SageMaker endpoint, and it keeps the fitness-recommendation model fully under the team's control. The trade-off, made explicit while sizing this week's EC2 instance, is that the instance has to be sized for the AI workload on top of everything else: `ai-service` depends on Ollama and Qdrant, both of which need meaningfully more CPU and RAM than a `t3.micro` provides.

### Difficulties Encountered:

- **SageMaker learning curve:** SageMaker's console has many moving pieces (notebook instances, training jobs, model registry, endpoints) that took time to map onto the simpler self-hosted flow already used in this project.
- **EC2 instance sizing for the AI workload:** a `t3.micro` (1 vCPU, 1 GiB RAM) is not realistic for running Ollama plus the rest of the stack — this was identified as a resourcing risk, not glossed over.

### How It Was Resolved:

- **SageMaker:** worked through the Immersion Day lab end-to-end rather than skimming it, using the deployed endpoint as a concrete anchor for what a managed alternative would look like.
- **Instance sizing:** documented a minimum recommended instance size for the full AI stack in [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/), noting that a smaller instance (e.g. Free Tier eligible) can only realistically run the MVP without the Ollama-backed AI service, or with the AI service pointed at a remote/managed LLM endpoint instead.

### AWS Skills / Services Learned:

**Services:**
- Amazon SageMaker (notebook instances, training jobs, real-time inference endpoints)
- EC2 launch configuration (AMI, instance type, IAM Role, Security Group, EBS)

**Skills:**
- Comparing managed vs. self-hosted ML inference cost and operational trade-offs
- Practical instance-sizing decisions for containerized workloads with an embedded LLM

### Connection to Fitness Assistant Architecture:

**Immediate Applications:**
- Documented the reasoning for self-hosting the LLM instead of using a managed SageMaker endpoint, as a design-decision record for the Proposal.
- MVP containers now running on EC2, connected to RDS.

**Future Enhancements:**
- Revisit the SageMaker option if the AI feature set grows enough that operating Ollama/Qdrant directly becomes a bigger burden than paying for a managed endpoint.
- TODO: Confirm the final instance type chosen and record actual CPU/RAM usage under load.

### Evidence Still Required:

- TODO: Screenshot of the SageMaker Immersion Day notebook/endpoint.
- TODO: Screenshot of the EC2 instance details.
- TODO: `docker ps` output showing running containers.
- TODO: `docker compose logs` excerpt showing successful startup.
- TODO: Sign-in evidence for the 3rd office day.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Study Module 7 (AI/ML on AWS) | [TODO_DATE] | [TODO_DATE] | 200: https://000200.awsstudygroup.com/ |
| 2 | Complete SageMaker Immersion Day (Lab 200) | [TODO_DATE] | [TODO_DATE] | 200: https://000200.awsstudygroup.com/ |
| 3 | Launch EC2, attach IAM Role and Security Group | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 4 | Install Docker/Docker Compose, pull images from ECR, deploy `docker-compose.aws.example.yml` | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 5 | Validate containers and resource usage; 3rd office day | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] Module 7 (AI/ML on AWS) studied
- [ ] SageMaker Immersion Day (Lab 200) completed
- [ ] 3rd office day attended
- [ ] EC2 launched with correct IAM Role and Security Group
- [ ] Docker/Docker Compose installed, images pulled from ECR, stack started
- [ ] Instance-sizing risk for Ollama/AI service documented

### Related Workshop Section

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/)
