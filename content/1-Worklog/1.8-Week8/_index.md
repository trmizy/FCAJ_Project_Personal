---
title: "Week 8"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 1.8. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Launch the EC2 instance that will host the application containers.
- Install Docker and Docker Compose, authenticate to ECR, pull images, and bring the MVP stack up.

### Tasks Performed

- Launched an EC2 instance in the public subnet, attached the IAM Role created in Week 7, and applied the EC2 Security Group from Week 5.
- Installed Docker Engine and the Docker Compose plugin on the instance.
- Logged in to ECR from the EC2 instance and pulled the MVP images.
- Wrote a `docker-compose.aws.example.yml` describing how the MVP services (frontend, gateway, auth-service, user-service, fitness-service, ai-service) are wired together on EC2, pointing `DATABASE_URL` at the RDS endpoint from Week 6 instead of a local Postgres container.
- Started the stack and checked container status and logs.
- Explicitly sized the instance with the AI/RAG service in mind: `ai-service` depends on Ollama (a self-hosted LLM, default model `llama3.2:3b`) and Qdrant, both of which need meaningfully more CPU and RAM than a `t3.micro` provides.

### Results Achieved

- MVP containers running on EC2, connected to RDS.
- TODO: Confirm final instance type chosen and record actual CPU/RAM usage under load.

### Difficulties

- A `t3.micro` (1 vCPU, 1 GiB RAM) is not realistic for running Ollama plus the rest of the stack — this was identified as a resourcing risk, not glossed over.

### How It Was Resolved

- Documented a minimum recommended instance size for the full AI stack in [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/), and noted that a smaller instance (e.g. Free Tier eligible) can only realistically run the MVP without the Ollama-backed AI service, or with the AI service pointed at a remote/managed LLM endpoint instead.

### AWS Skills / Services Learned

- EC2 launch configuration (AMI, instance type, IAM Role, Security Group, EBS).
- Practical instance-sizing trade-offs for containerized workloads with an embedded LLM.

### Evidence Still Required

- TODO: Screenshot of the EC2 instance details.
- TODO: `docker ps` output showing running containers.
- TODO: `docker compose logs` excerpt showing successful startup.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Launch EC2, attach IAM Role and Security Group | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 2 | Install Docker and Docker Compose | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 3 | Pull images from ECR and deploy `docker-compose.aws.example.yml` | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 4 | Validate containers and resource usage | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] EC2 launched with correct IAM Role and Security Group
- [ ] Docker/Docker Compose installed
- [ ] Images pulled from ECR and stack started
- [ ] Instance-sizing risk for Ollama/AI service documented

### Related Workshop Section

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/)
