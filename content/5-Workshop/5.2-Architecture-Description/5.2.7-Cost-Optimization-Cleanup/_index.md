---
title: "Cost Optimization and Clean-up"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.2.7. </b> "
---

### Cost estimate with the AWS Pricing Calculator

The monthly cost of the DEV environment was estimated with the **AWS Pricing Calculator** for the Singapore Region (`ap-southeast-1`), assuming everything runs 24×7. The shared estimate is here: [Gymini DEV ap-southeast-1 estimate](https://calculator.aws/#/estimate?id=0ad0dd36cae8f89d2b9a5dbf13cea7af8e8ee21b) (the calculator keeps a shared link for one year).

![The services of the estimate with their monthly cost](/images/workshop/console/calc-3-services-table.jpg)
*The estimate lists five services with their monthly cost.*

| Service | Configuration used | Monthly cost (USD) |
|---|---|---|
| Amazon Aurora PostgreSQL Serverless v2 | Writer and Reader at the 0.5 ACU floor (1 ACU in total), 730 hours, 10 GB storage | 75.28 |
| AWS PrivateLink (interface VPC endpoints) | 2 endpoints (Secrets Manager, OpenSearch) in 2 Availability Zones, 10 GB per month | 38.06 |
| AWS Fargate (Chat service) | 1 task running 24 hours a day, 0.5 vCPU, 1 GB memory, 20 GB ephemeral storage | 22.50 |
| Elastic Load Balancing | 1 Application Load Balancer, light traffic | 18.98 |
| AWS Secrets Manager | 9 secrets, 100,000 API calls per month | 4.10 |
| **Total of the estimate** | | **158.92 per month (1,907.04 per 12 months)** |

**Not in the shared estimate, priced separately:**

- **NAT Gateway**: the calculator makes a "Regional NAT Gateway" entry mandatory next to the standard one, which would overstate the cost, so it was left out. One gateway for 730 hours plus 20 GB of data is about **44 USD per month** (the calculator showed 44.25 USD for that configuration while the form was open, before it was discarded). With it the running total is about **203 USD per month**, inside the 190–230 USD range of the proposal.
- **Usage-based items with very small DEV volume**: Lambda, API Gateway, S3, CloudWatch, SQS, EventBridge, OpenSearch Serverless (scales to zero when idle) and Amazon Bedrock (per token).

**Reading the number.** These are the costs of leaving everything on for a full month. The sleep procedure ([5.7](../../5.7-Cleanup/#pause)) removes the NAT Gateway, stops Aurora and scales the Chat service to zero outside test sessions, which is why the real spend is a fraction of this figure.

#### How the estimate was built

1. Open the calculator, click **Add service**, keep **Search by location type**, choose the Region **Asia Pacific (Singapore)** and type the service name in **Find Service**.

![Add service page with the Region and the service search marked](/images/workshop/console/calc-1-add-service.jpg)
*Step 1: choose the Region (1) and search for the service (2).*

2. Click **Configure** on the service card and fill in its form. For the Chat service on Fargate: **Number of tasks** 1 per day (1), **Average duration** 1 day (2), **Amount of vCPU** 0.5 (3), **Amount of memory** 1 GB. Then click **Save and add service**.

![Fargate form with the number of tasks, duration and vCPU marked](/images/workshop/console/calc-2-fargate-form.jpg)
*Step 2: the Fargate form (shown with its default values before they were changed).*

3. Repeat for Aurora PostgreSQL (choose the **Serverless** edition, 1 ACU, 10 GB), the VPC form with **AWS PrivateLink** (2 endpoints, 2 Availability Zones), Elastic Load Balancing (1 Application Load Balancer, a small amount of processed data) and Secrets Manager (9 secrets).
4. Open the summary. Click **Edit** next to the name to rename the estimate, then click **Share** (2) and **Agree and continue**. Use **Add service** (1) to add more services at any time.

![Estimate summary with Add service and Share marked and the total cost](/images/workshop/console/calc-4-summary.jpg)
*Step 4: the summary shows 158.92 USD per month.*

5. The calculator stores the estimate on AWS public servers and shows a public link. Click **Copy public link** (1) to copy it. Anyone with the link can open the estimate.

![Save estimate dialog with the public share link and the Copy public link button marked](/images/workshop/console/calc-5-share.jpg)
*Step 5: the shared link of the estimate.*

### Cost levers already in use

- **Lambda for six of seven services** — pay per invocation instead of an instance running all day; DEV traffic and the scheduled jobs largely fit in the Lambda free tier.
- **Aurora Serverless v2 with a low floor** — 0.5 ACU while services were being deployed (to avoid auto-pause noise in smoke tests), designed to go to 0 ACU when the environment is idle.
- **One Aurora cluster with seven logical databases** instead of seven clusters.
- **OpenSearch Serverless NextGen at 0–2 OCU** — scales to zero when idle instead of the default maximum of 96 OCU.
- **Bedrock on demand** — no model hosting cost; per-route throttling on the AI routes stops a client or frontend bug from generating runaway token usage.
- **CloudFront and S3 for the frontend** — near-zero cost for a build that never changes at request time, with caching and HTTPS.
- **One NAT Gateway** for the whole DEV VPC rather than one per Availability Zone.
- **Right-sized Fargate task** — 0.5 vCPU / 1 GB for the Chat Service; the migrator task (1 vCPU / 2 GB) only exists while it runs.
- **Interface VPC endpoints** for Secrets Manager and OpenSearch keep that traffic off the NAT Gateway's per-GB processing charge.

### Where the fixed cost is

With almost everything usage-based, the hourly costs that run even when nobody uses the system are the **NAT Gateway**, the **Chat ALB**, the **Fargate task**, **Aurora's minimum capacity**, the **interface VPC endpoints** and the **public IPv4 addresses** (NAT Elastic IP and the ALB's addresses). The [Proposal's budget](../../../2-Proposal/#budget) estimates them; they are the targets of the "sleep" strategy below.

### Pausing between sessions

- **DEV sleep strategy** — Aurora to 0 ACU, the Chat service to 0 tasks out of hours, and the NAT Gateway deleted between test sessions (see [5.7](../../5.7-Cleanup/#pause)).

### Clean-up

The full, dependency-ordered teardown of every resource in this architecture is in [5.7 Clean-up](../../5.7-Cleanup/).
