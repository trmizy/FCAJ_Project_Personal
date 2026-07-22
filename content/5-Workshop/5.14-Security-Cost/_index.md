---
title: "5.14 Security and Cost Optimization"
date: 2026-07-15
weight: 14
chapter: false
pre: " <b> 5.14. </b> "
---

### Security Checklist

- [ ] IAM least privilege applied ([5.11 IAM and Secrets](../5.11-IAM-Secrets/)).
- [ ] RDS is private (no public access), reachable only from the EC2 Security Group.
- [ ] Encryption at rest enabled on RDS.
- [ ] Encryption in transit: TLS for the frontend (TODO — not yet configured; the MVP currently serves over plain HTTP, see [5.15 Troubleshooting](../5.15-Troubleshooting/) and consider adding a certificate before any real usage).
- [ ] Secrets in AWS Secrets Manager, not in `.env` files on the host or in the image.
- [ ] No AWS access keys committed to source or baked into images.
- [ ] SSH restricted to a specific IP, never `0.0.0.0/0`.
- [ ] Security Groups follow least privilege ([5.6 Network Infrastructure](../5.6-Network-Infrastructure/)).
- [ ] OS patching plan for the EC2 host (TODO: decide on a patching cadence).
- [ ] Container base images kept reasonably current (`node:20-alpine`, `nginx:1.25-alpine`, `postgres:15-alpine`).
- [ ] Dependency scanning (TODO: not yet run — consider `pnpm audit` or a container scanner).
- [ ] RDS automated backups enabled.
- [ ] CloudWatch Log retention explicitly set, not left unbounded.
- [ ] Rate limiting preserved at the gateway (`express-rate-limit`, already present in source — do not remove or weaken it during deployment).
- [ ] `JWT_SECRET` is a strong, unique value in Secrets Manager, not the example/default value from `.env.example`.
- [ ] Input validation preserved (the application already uses `zod` schema validation in several services — do not bypass it when adapting for AWS).

{{% notice warning %}}
This checklist describes reasonable, evidence-based security practices for a learning MVP. It does not claim the deployment is "fully secure" or production-hardened — no deployment is ever absolutely secure, and this report does not claim otherwise.
{{% /notice %}}

### Cost Optimization Checklist

- [ ] Right-size the EC2 instance based on actual measured CPU/RAM usage (see [5.9 EC2 Deployment](../5.9-EC2-Deployment/)), not a guess.
- [ ] Stop (not just leave idle) the EC2 instance when not actively being used for demonstration or testing.
- [ ] Use a small RDS instance class appropriate for a lab/MVP, not a production-scale instance.
- [ ] Apply an ECR lifecycle policy to expire old/untagged images ([5.8 ECR](../5.8-ECR/)).
- [ ] Apply an S3 lifecycle policy if/when S3 is actually implemented ([5.10 S3 Storage](../5.10-S3-Storage/)).
- [ ] Set explicit CloudWatch Log retention (not "Never expire").
- [ ] **NAT Gateway cost warning:** not used in this MVP design; if added later, note its hourly charge plus per-GB data processing charge before enabling it.
- [ ] **Elastic IP cost warning:** an Elastic IP not attached to a running instance incurs a charge; release any Elastic IP that is not in active use.
- [ ] Delete snapshots that are no longer needed (RDS snapshots, EBS snapshots).
- [ ] Consider AWS Budgets as a recommended (optional) safety net to catch unexpected spend — not yet configured.
- [ ] Do not state a fixed monthly cost figure anywhere in this report without first checking the [AWS Pricing Calculator](https://calculator.aws/).

{{% notice warning %}}
No specific dollar figure is stated here as a guarantee. Actual cost depends on Region, instance types finally chosen, and usage duration — verify with the AWS Pricing Calculator and AWS Cost Explorer before and after deployment.
{{% /notice %}}
