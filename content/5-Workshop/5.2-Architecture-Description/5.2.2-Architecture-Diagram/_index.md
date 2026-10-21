---
title: "5.2.2 Architecture Diagram"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

The diagram below is the architecture image supplied for this project. Unlike earlier revisions of this page, every node here is checked directly against live AWS state (not copied from an older draft) — [5.4 Deployment Guide](../../5.4-Deployment-Guide/) and [5.5.5 Validation status and open items](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) carry the step-by-step evidence behind each claim, and [5.2.1](../5.2.1-Architecture-Overview/) covers how the deployment arrived at its current state.

{{% notice note %}}
Two corrections made while re-verifying this page on 2026-10-21, against real AWS calls, not inferred:
- **API Gateway is an HTTP API, not a REST API** — this project uses `apigatewayv2`, confirmed by every route/CORS/stage call made against it throughout this engagement. An earlier revision of this diagram said "REST API"; that was wrong.
- **The Aurora Serverless v2 reader replica is already deployed**, not a "designed but not built" item: `aws rds describe-db-clusters` lists two real cluster members (`fitness-assistant-dev-aurora-instance-1`, writer; `fitness-assistant-dev-aurora-instance-2`, reader, `PromotionTier: 1`), re-confirmed live the same day this note was written.
{{% /notice %}}

### Component diagram

![AWS serverless architecture of Fitness Assistant](/images/workshop/architecture/architecture.png)

{{% notice note %}}
Everything in the component diagram outside the Edge and DevOps groups runs inside a VPC spread across multiple Availability Zones. The chat service is the one deliberate exception to "no EC2 instances or containers in this design": it is stateful WebSocket traffic, which does not fit a request/response Lambda well, so it runs as an ECS Fargate task behind its own Application Load Balancer — both on-demand (started/stopped per session with the NAT Gateway and OpenSearch/Secrets Manager VPC endpoints, via `dev-start.ps1`/`dev-stop.ps1`), not always-on.

The AI component is a dual-provider setup, not a single LLM: **Ollama running a self-hosted Qwen3-4B model is the default for local/dev work** (no per-token cost, no AWS dependency), while **the real, deployed AWS Lambda calls Amazon Bedrock's Nova Pro** — not through the DEV account's own Bedrock quota (which is account-level 0 and not self-service-adjustable), but through a dedicated cross-account IAM role in a separate AWS account, assumed via STS for every Bedrock call. This was exercised for real, not just configured: CloudWatch shows a successful `llm_call` log line with `provider":"bedrock"` and a real `apac.amazon.nova-pro-v1:0` response.

On infrastructure-as-code: **CloudFormation, not Terraform, is what actually provisions and manages this project's real AWS resources** (API Gateway, the CI/CD OIDC IAM roles, the on-demand network stack, the frontend CDN, monitoring) — confirmed by listing every live `CREATE_COMPLETE`/`UPDATE_COMPLETE` stack in the account. The repository does contain a Terraform module, but it is wired up only to a separate, unrelated "hello world" bootstrap API with no live `.tfstate` for this environment — it is not this project's real IaC path, despite being present in the codebase.

[5.5.5](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) is the page to check for the full, itemized build/confirmed status of every piece here.
{{% /notice %}}
