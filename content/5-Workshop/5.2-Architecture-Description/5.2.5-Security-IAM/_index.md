---
title: "5.2.5 Security and IAM"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.2.5. </b> "
---

### Network Isolation

- All Lambda-based services and Aurora sit inside one VPC (`fitness-assistant-dev-vpc`), with no resource placed in a public subnet except the NAT Gateway itself.
- Lambda functions run in two private application subnets, routed to the internet only indirectly, through the NAT Gateway and Internet Gateway — there is no direct inbound path to a Lambda's ENI from the internet.
- Aurora sits in its own private DB subnets, associated with a route table that has **no** NAT or internet route at all — the database tier cannot reach, or be reached from, the internet under any configuration mistake in the other route tables.
- One shared security group (`fitness-assistant-dev-lambda-sg`) covers every Lambda-based service's outbound rules; Aurora's security group only accepts inbound connections on port 5432 from that Lambda security group (and, separately, from the Chat Fargate task's own security group).
- The Chat Fargate task has its own security group, reachable only from the Chat ALB's security group on its container port — not from the internet directly, and not from the Lambda security group.

### IAM — Least Privilege Per Service

Every Lambda has its own execution role, rather than one role shared across services. Each role is built from the same small set of AWS managed policies (`AWSLambdaBasicExecutionRole` for CloudWatch Logs, `AWSLambdaVPCAccessExecutionRole` for running inside the VPC) plus an inline policy scoped to exactly what that one service needs, for example:

- A migration Lambda's inline policy grants `secretsmanager:GetSecretValue` on only its own service's database secret ARN — not every secret in the account.
- A service that needs to call another service directly (e.g. Payment invoking Auth or User) gets an inline policy scoped to `lambda:InvokeFunction` on only the specific target function ARNs it calls, not a wildcard `lambda:*`.
- The AI Worker and Jobs Lambdas' roles are scoped to the AI database secret and the specific SQS queue / EventBridge schedule they consume from — not account-wide SQS or EventBridge access.
- Bedrock access was added to the AI HTTP Lambda's role as a targeted addition of Bedrock-specific statements onto its existing policy, not a replacement with a broad managed policy like `AmazonBedrockFullAccess`.

### Secrets Management

- Every database credential lives in AWS Secrets Manager, one secret per service database (`fitness-assistant/dev/<service>-database`). No Lambda environment variable holds a raw password — each Lambda holds a `DATABASE_SECRET_ID` and resolves the value from Secrets Manager at runtime.
- Service-to-service calls (e.g. Payment invoking Auth) are authenticated with a shared `INTERNAL_SERVICE_SECRET`, separate from any end-user JWT, so an internal call cannot be replayed as if it came from a logged-in user.
- A separate secret, `CHECKIN_TOKEN_SECRET`, signs the Gym Service's QR check-in tokens — deliberately a different value from `INTERNAL_SERVICE_SECRET`, so that compromising one does not compromise the other.
- Payment provider credentials (VNPAY, and MoMo/PayOS/ZaloPay as they are added) follow the same pattern: stored as secrets, referenced by ID, never pasted into chat, documentation, or source control.

### Known Security Gaps (Open, Not Hidden)

Consistent with this report's [Definition of Done](../../5.1-Overview/), these are tracked openly rather than left implicit:

- **ADMIN credential rotation** — postponed. Not a blocker for the current DEV environment, but required before any wider release.
- **Remaining seed-account remediation** — 12 seed accounts from initial data load still need remediation.
- **HTTPS** — both the frontend (S3 website endpoint) and the Chat ALB currently serve over plain HTTP in DEV. Moving to HTTPS depends on a domain name and an ACM certificate, which are not yet in place.
- **No WAF yet** — see [5.2.4](../5.2.4-AWS-Services-Selection/) for why; there is no CloudFront distribution or HTTPS ALB listener to attach a web ACL to at this stage.

### Handling of Screenshot Evidence Containing Secrets

While assembling the deployment evidence for this report, a small number of console screenshots (Secrets Manager "Store a new secret" screens and Lambda "Environment variables" screens) were found to contain real secret values in plaintext. Each was pixel-level redacted (the secret value itself blacked out in the image data, not cropped or blurred, since cropping/blurring can leave the original pixels recoverable) before being considered for inclusion in this report. This is noted here for transparency about how the evidence in later Workshop sections was sanitized, not as a claim that every one of the hundreds of captured screenshots has been individually re-verified since.
