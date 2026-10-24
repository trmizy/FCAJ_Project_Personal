---
title: "Deployment region"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.3.2. </b> "
---

Every resource in this workshop is created in **Asia Pacific (Singapore) — `ap-southeast-1`**. Check the region selector in the top-right corner of the console before each step; several resources (secrets, queues, Lambda functions) are invisible from other regions and are easy to recreate by mistake in the wrong one.

| Requirement | How `ap-southeast-1` meets it |
|---|---|
| Low latency for users in Vietnam | Closest commercial AWS region with the full set of services used here |
| Amazon Bedrock — Nova Pro | Invoked through the **APAC** cross-region inference profile `apac.amazon.nova-pro-v1:0` from Singapore |
| Amazon Bedrock — Cohere Embed Multilingual v3 | Available as a foundation model in `ap-southeast-1` |
| Amazon OpenSearch Serverless | The **NextGen** generation (with scale-to-zero) is available in Singapore |
| Aurora PostgreSQL Serverless v2, ECS Fargate, API Gateway HTTP API | All available in the region |

#### Availability Zones used

| AZ | Subnets |
|---|---|
| `ap-southeast-1a` | `fitness-assistant-dev-private-app-a` (10.0.10.0/24), `fitness-assistant-dev-public-a` (10.0.1.0/24) |
| `ap-southeast-1b` | `fitness-assistant-dev-private-app-b` (10.0.11.0/24), `fitness-assistant-dev-public-b` (10.0.2.0/24) |

Lambda functions and the Chat Fargate task run in both private application subnets. The second public subnet exists because an internet-facing Application Load Balancer requires subnets in at least two Availability Zones.
