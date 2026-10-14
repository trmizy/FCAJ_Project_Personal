---
title: "5.4.1 Shared network infrastructure"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.4.1. </b> "
---

All Lambda-based services share one VPC and one Lambda security group; the Chat Service adds its own security groups in [5.4.10](../5.4.10-Chat-Service-ECS/).

#### Starting point

The base VPC, the two private application subnets, the private DB subnets, the Aurora cluster and the Secrets Manager VPC endpoint already existed before the first step recorded in the runbook, so their creation is not shown here. The table is the reference used by every later step.

| Resource | Name | Detail |
|---|---|---|
| VPC | `fitness-assistant-dev-vpc` | `10.0.0.0/16`, `ap-southeast-1` |
| Private app subnet A | `fitness-assistant-dev-private-app-a` | `10.0.10.0/24`, `ap-southeast-1a` — Lambda and Fargate placement |
| Private app subnet B | `fitness-assistant-dev-private-app-b` | `10.0.11.0/24`, `ap-southeast-1b` |
| Private DB subnets | DB subnet group | Route table `fitness-assistant-dev-private-db-rt`, **no** NAT or internet route |
| Lambda security group | `fitness-assistant-dev-lambda-sg` | Shared by every Lambda function |
| Aurora security group | `fitness-assistant-dev-aurora-sg` | Inbound 5432 only from the Lambda SG (and later the Chat SG) |
| VPC endpoint security group | `fitness-assistant-dev-vpce-sg` | Inbound 443 from the Lambda SG; used by the Secrets Manager and OpenSearch endpoints |

The steps below were added during the User Service deployment, when the first Lambda needed outbound internet access (to call API Gateway, Bedrock and other AWS APIs) from inside the private subnets.

#### Step 1 — Create and attach an Internet Gateway

**VPC → Internet gateways → Create internet gateway**, name it `fitness-assistant-dev-igw`, then **Actions → Attach to a VPC → `fitness-assistant-dev-vpc`**.

![Internet Gateway fitness-assistant-dev-igw attached to the VPC](/images/workshop/runbook/img023.jpg)

#### Step 2 — Create a public subnet for the NAT Gateway

**VPC → Subnets → Create subnet**: VPC `fitness-assistant-dev-vpc`, name `fitness-assistant-dev-public-a`, AZ `ap-southeast-1a`, CIDR `10.0.1.0/24`. Auto-assign public IPv4 stays off — the NAT Gateway uses its own Elastic IP. One public subnet is enough for one NAT Gateway in DEV.

![Public subnet fitness-assistant-dev-public-a (10.0.1.0/24)](/images/workshop/runbook/img024.jpg)

#### Step 3 — Create the public route table

**VPC → Route tables → Create route table**: name `fitness-assistant-dev-public-rt`, VPC `fitness-assistant-dev-vpc`. In **Routes → Edit routes**, add `0.0.0.0/0 → Internet Gateway fitness-assistant-dev-igw`.

![Public route table with 0.0.0.0/0 pointing to the Internet Gateway](/images/workshop/runbook/img025.jpg)

In **Subnet associations → Edit subnet associations**, associate `fitness-assistant-dev-public-a`.

![Subnet association of fitness-assistant-dev-public-a](/images/workshop/runbook/img026.jpg)

#### Step 4 — Create the NAT Gateway

**VPC → NAT gateways → Create NAT gateway**: name `fitness-assistant-dev-nat-a`, subnet `fitness-assistant-dev-public-a`, connectivity type **Public**, and **Allocate Elastic IP**. Wait for the state to change from *Pending* to *Available* before touching the private route table.

![NAT Gateway fitness-assistant-dev-nat-a with its Elastic IP](/images/workshop/runbook/img027.jpg)

#### Step 5 — Route the private app subnets through the NAT Gateway

**VPC → Route tables → `fitness-assistant-dev-private-app-rt` → Routes → Edit routes**, add `0.0.0.0/0 → NAT Gateway fitness-assistant-dev-nat-a`.

![Private app route table: 10.0.0.0/16 local and 0.0.0.0/0 via the NAT Gateway](/images/workshop/runbook/img028.jpg)

The route table now contains:

```
10.0.0.0/16   → local
0.0.0.0/0     → fitness-assistant-dev-nat-a
```

Both private app subnets use this route table, so every Lambda placed in them gets outbound access:

```
Lambda → Private App Subnet → NAT Gateway → Internet Gateway → API Gateway / Bedrock / AWS APIs
```

{{% notice warning %}}
Do **not** add a NAT route to `fitness-assistant-dev-private-db-rt`. The database subnets stay fully private.
{{% /notice %}}

#### Step 6 — Add a second public subnet (needed later by the Chat ALB) {#second-public-subnet}

An internet-facing Application Load Balancer needs subnets in at least two Availability Zones. When the Chat Service was deployed, a second public subnet was added: **VPC → Subnets → Create subnet**, name `fitness-assistant-dev-public-b`, AZ `ap-southeast-1b`, CIDR `10.0.2.0/24`.

![Creating fitness-assistant-dev-public-b (10.0.2.0/24) in ap-southeast-1b](/images/workshop/runbook/img305.jpg)

Then select the new subnet → **Actions → Edit route table association** and choose `fitness-assistant-dev-public-rt`, the same table used by `public-a`.

![Edit route table association for the new public subnet](/images/workshop/runbook/img306.jpg)

![public-b associated with fitness-assistant-dev-public-rt (local + 0.0.0.0/0 → IGW)](/images/workshop/runbook/img307.jpg)

#### Result

| Subnet | CIDR | AZ | Route table | Hosts |
|---|---|---|---|---|
| `public-a` | 10.0.1.0/24 | 1a | `public-rt` (→ IGW) | NAT Gateway, Chat ALB |
| `public-b` | 10.0.2.0/24 | 1b | `public-rt` (→ IGW) | Chat ALB |
| `private-app-a` | 10.0.10.0/24 | 1a | `private-app-rt` (→ NAT) | Lambda, Fargate tasks |
| `private-app-b` | 10.0.11.0/24 | 1b | `private-app-rt` (→ NAT) | Lambda, Fargate tasks |
| private DB subnets | — | 1a/1b | `private-db-rt` (no internet) | Aurora |
