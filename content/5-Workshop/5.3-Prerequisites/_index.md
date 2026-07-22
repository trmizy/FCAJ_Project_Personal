---
title: "5.3 Prerequisites"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.3. </b> "
---

### Accounts and Access

- An **AWS account** (Free Tier eligible account is fine to start, but see the cost warning below regarding the AI stack).
- **AWS Region:** `[TODO_AWS_REGION]` — pick one Region and use it consistently throughout this Workshop.
- An IAM user or role with sufficient permissions to create VPC, EC2, RDS, ECR, IAM, Secrets Manager, CloudWatch and SNS resources. Do not use root account credentials for day-to-day work.

### Local Tools

| Tool | Purpose | Check command |
| --- | --- | --- |
| AWS CLI v2 | Interact with AWS from the terminal | `aws --version` |
| Git | Clone the application and this report's repository | `git --version` |
| Docker | Build and run containers locally | `docker --version` |
| Docker Compose plugin | Run the application's multi-container stack | `docker compose version` |
| Hugo (Extended) | Build and preview this report site | `hugo version` |

{{% notice note %}}
Run each check command and confirm a version is printed before continuing. Do not paste real AWS access keys into any file in this repository.
{{% /notice %}}

### Required IAM Permissions (Summary)

At minimum, the IAM identity used for this Workshop needs permissions to manage: VPC/EC2 networking resources, EC2 instances, Amazon ECR repositories, Amazon RDS instances, IAM roles/policies (for the EC2 instance role), AWS Secrets Manager secrets, CloudWatch Logs/Metrics/Alarms, and SNS topics. See [5.11 IAM and Secrets](../5.11-IAM-Secrets/) for a least-privilege policy example.

### Domain Name

Optional for the MVP. The application is reachable via the EC2 instance's public IP/DNS name for this workshop; a custom domain via Amazon Route 53 is listed as future work in the [Proposal](../../2-Proposal/#25-future-development).

### Baseline Knowledge Assumed

- Basic Linux command line usage.
- Basic Docker and Docker Compose concepts.
- Basic understanding of HTTP, REST APIs, and relational databases.

### Estimated Time

TODO: Record the actual time spent per Workshop section as it is completed (see the [Worklog](../../1-Worklog/) for the week-by-week breakdown).

### Estimated Cost Warning

{{% notice warning %}}
AWS pricing changes by Region and over time. Before creating any resource, check the [AWS Pricing Calculator](https://calculator.aws/). Do not assume Free Tier fully covers this workload — the AI service depends on a self-hosted LLM (Ollama) and a vector database (Qdrant), which typically need more compute than a Free Tier-eligible instance provides. See [5.9 EC2 Deployment](../5.9-EC2-Deployment/) and [5.14 Security and Cost Optimization](../5.14-Security-Cost/) for sizing and cost guidance.
{{% /notice %}}
