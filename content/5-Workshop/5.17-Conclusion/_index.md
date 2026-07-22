---
title: "5.17 Conclusion"
date: 2026-07-15
weight: 17
chapter: false
pre: " <b> 5.17. </b> "
---

### Results Achieved

TODO: fill in honestly once the deployment is executed. Do not summarize this section until every referenced Workshop step has real evidence. As a structure to fill in:

- Which MVP services were actually deployed and verified end to end.
- Which test cases from [5.13 Testing and Validation](../5.13-Testing-Validation/) actually passed.
- Which monitoring/alerting chains were actually confirmed working.

### Before vs. After Moving to AWS

| Aspect | Before (local Docker Compose) | After (AWS MVP) |
|---|---|---|
| Database | Single `postgres` container, no backups | Amazon RDS, automated backups, private network — TODO confirm |
| Image distribution | Local `docker build` only | Amazon ECR, versioned images — TODO confirm |
| Secrets | Root `.env` file | AWS Secrets Manager — TODO confirm |
| Observability | `docker compose logs` only | CloudWatch Logs/Alarms + SNS — TODO confirm |
| Availability | Single machine, manual restart | Single EC2 host — still a known single point of failure, not yet resolved |

### Knowledge Gained

- Reading an existing, non-trivial codebase carefully enough to describe its real architecture accurately, instead of assuming a generic pattern.
- The practical difference between an application-level gateway container and a managed AWS service with a similar name (Amazon API Gateway).
- VPC/subnet/Security Group design fundamentals, applied to a real multi-service application.
- Database-per-service migration from a single Docker container to a shared managed RDS instance.
- Basic AWS observability: CloudWatch Logs/Metrics/Alarms and SNS notification chains.
- IAM least-privilege policy design in practice, not just in theory.

### Difficulties

TODO: list the genuine difficulties encountered during actual implementation (technical and non-technical). See the [Worklog](../../1-Worklog/) for difficulties already logged week by week.

### How They Were Handled

TODO: summarize the resolution approach for each difficulty above, cross-referencing the relevant Worklog week.

### Limitations

- Single EC2 host: no redundancy, no Auto Scaling.
- `gym-service`, `payment-service`, `chat-service` are not part of this deployment.
- Amazon S3 is not integrated — file uploads remain on local disk.
- TLS/HTTPS is not yet configured for the frontend.
- Secret rotation is not automated.
- No CI/CD pipeline; deployment steps are manual.

### Personal Contribution

TODO: describe, specifically, what was done personally versus with guidance (mentor input, existing documentation, AI-assisted research tools, etc.). Be precise and honest — vague claims ("I did everything") are not useful evidence for evaluation.

### Future Development

- Amazon ECS/Fargate with an Application Load Balancer and Auto Scaling, replacing the single EC2 host.
- Amazon CloudFront and Amazon Route 53 for a CDN and a custom domain.
- Amazon Bedrock as a managed alternative or complement to self-hosted Ollama.
- Amazon S3 (with an actual `user-service` code change) replacing local-disk uploads.
- Amazon ElastiCache for Redis, replacing the Redis container.
- A CI/CD pipeline (GitHub Actions) to automate build, test and deploy.
- Infrastructure as Code (Terraform or AWS CDK) instead of manual console/CLI steps.
- Multi-AZ RDS for higher availability.
- Production Dockerfiles and deployment for `gym-service`, `payment-service`, and `chat-service`.

{{% notice warning %}}
**Health disclaimer:** Fitness Assistant's AI-assisted coaching and nutrition features (Ollama-backed RAG chat, deterministic calculators) provide general fitness information and suggestions only. They do not diagnose medical conditions, and this deployment does not change that. Fitness Assistant is not a substitute for advice from a qualified physician, registered dietitian, or certified fitness professional — this applies equally to the AI coaching feature and to the separate Anthropic Claude Vision-based InBody photo extraction feature, which reads numeric values from a photo and does not itself constitute medical interpretation.
{{% /notice %}}

### Personal Reflection

TODO: write a genuine, first-person reflection after completing the internship — what surprised you, what you would do differently, what this experience changed about how you think about cloud deployment.
