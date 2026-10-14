---
title: "5.2.7 Cost Optimization and Clean-up"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.2.7. </b> "
---

### Cost levers already in use

- **Lambda for six of seven services** — pay per invocation instead of an instance running all day; DEV traffic and the scheduled jobs largely fit in the Lambda free tier.
- **Aurora Serverless v2 with a low floor** — 0.5 ACU while services were being deployed (to avoid auto-pause noise in smoke tests), designed to go to 0 ACU when the environment is idle.
- **One Aurora cluster with seven logical databases** instead of seven clusters.
- **OpenSearch Serverless NextGen at 0–2 OCU** — scales to zero when idle instead of the default maximum of 96 OCU.
- **Bedrock on demand** — no model hosting cost; per-route throttling on the AI routes stops a client or frontend bug from generating runaway token usage.
- **S3 static website for the frontend** — near-zero cost for a build that never changes at request time.
- **One NAT Gateway** for the whole DEV VPC rather than one per Availability Zone.
- **Right-sized Fargate task** — 0.5 vCPU / 1 GB for the Chat Service; the migrator task (1 vCPU / 2 GB) only exists while it runs.
- **Interface VPC endpoints** for Secrets Manager and OpenSearch keep that traffic off the NAT Gateway's per-GB processing charge.

### Where the fixed cost is

With almost everything usage-based, the hourly costs that run even when nobody uses the system are the **NAT Gateway**, the **Chat ALB**, the **Fargate task**, **Aurora's minimum capacity**, the **interface VPC endpoints** and the **public IPv4 addresses** (NAT Elastic IP and the ALB's addresses). The [Proposal's budget](../../../2-Proposal/#budget) estimates them; they are the targets of the "sleep" strategy below.

### Planned, not yet automated

- **DEV sleep strategy** — Aurora to 0 ACU, the Chat service to 0 tasks out of hours, and the NAT Gateway deleted between test sessions (see [5.7](../../5.7-Cleanup/#pause)).
- **CloudFront** in front of a private frontend bucket, adding caching and HTTPS.
- **AWS Budgets alert** on the account so an unexpected charge is noticed within a day.

### Clean-up

The full, dependency-ordered teardown of every resource in this architecture is in [5.7 Clean-up](../../5.7-Cleanup/).
