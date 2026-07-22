---
title: "5.11 IAM and Secrets"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 5.11. </b> "
---

### IAM Role for EC2

A single IAM Role attached to the EC2 instance profile, scoped to only what the MVP actually needs: pulling images from ECR, writing logs/metrics to CloudWatch, and reading secrets from Secrets Manager.

See [`/files/policies/ec2-ecr-policy.example.json`](/files/policies/ec2-ecr-policy.example.json) for a reference policy using placeholder ARNs.

### Least Privilege

- No `"Action": "*"` and no `"Resource": "*"` where a specific ARN can be used instead.
- ECR permissions scoped to the specific repository ARNs created in [5.8 ECR](../5.8-ECR/), not all of ECR.
- Secrets Manager permissions scoped to the specific secret ARNs used by this deployment.

### ECR Pull Permissions

`ecr:GetAuthorizationToken` (must be `Resource: "*"` — this specific action does not support resource-level restriction), plus `ecr:BatchGetImage` and `ecr:GetDownloadUrlForLayer` scoped to the MVP repository ARNs.

### CloudWatch Permissions

`logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, `cloudwatch:PutMetricData` — scoped to the log groups used by this project where CloudWatch's IAM model allows resource-level scoping.

### S3 Permissions

Not attached to the EC2 role for the MVP, since S3 is not yet used by the application (see [5.10 S3 Storage](../5.10-S3-Storage/), status Planned). Add only if/when the S3 integration is actually implemented, scoped to the single bucket ARN — see [`/files/policies/s3-access-policy.example.json`](/files/policies/s3-access-policy.example.json).

### Secrets Manager Permissions

`secretsmanager:GetSecretValue` scoped to the specific secret ARNs holding `DATABASE_URL` credentials, `JWT_SECRET`, `JWT_REFRESH_SECRET`, and `ANTHROPIC_API_KEY` — never a wildcard across all secrets in the account.

### Resource-Level Permissions

Every policy statement above should reference a specific ARN pattern (`arn:aws:ecr:<region>:<account-id>:repository/fitness-assistant/*`, `arn:aws:secretsmanager:<region>:<account-id>:secret:fitness-assistant/*`) rather than `*`, so a compromised instance role cannot reach unrelated resources in the same account.

### No Wildcards Where Avoidable

`ecr:GetAuthorizationToken` is a documented exception (AWS requires `Resource: "*"` for this specific action) — every other permission in the example policy is scoped to a specific ARN pattern.

### No Hard-Coded AWS Credentials

The EC2 instance role provides temporary, automatically rotated credentials via the instance metadata service — no long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` should ever be placed in a `.env` file, a Dockerfile, or committed to source.

### No `.env` Committed

`.gitignore` in this repository and in the application source excludes `.env`, `.env.*` (except `.env.example`), `*.pem`, and `*.key`. Verify before every commit with `git status`.

### Secret Rotation

Not implemented in the MVP; listed as future work. AWS Secrets Manager supports automatic rotation for RDS credentials, which would be a natural next step once the MVP is stable.

### Example Least-Privilege Policy

See [`/files/policies/ec2-ecr-policy.example.json`](/files/policies/ec2-ecr-policy.example.json) — uses `<YOUR_AWS_ACCOUNT_ID>` and `<YOUR_AWS_REGION>` placeholders, never a real account ID.
