---
title: "5.4.1 Shared network infrastructure"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.4.1. </b> "
---

All Lambda-based services share one VPC and one Lambda security group; the Chat Service adds its own security groups in [5.4.10](../5.4.10-Chat-Service-ECS/).

In every screenshot on the deployment pages, the **red rectangles** mark what to fill in or click for the sub-step written just above it. Where the runbook has no screenshot for an action, the text says so.

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

**1.1 — Create the gateway.** Open **VPC → Internet gateways → Create internet gateway**, enter the name tag `fitness-assistant-dev-igw` and click **Create internet gateway**.

![Create internet gateway: name tag fitness-assistant-dev-igw, then Create](/images/workshop/runbook/img023.jpg)

**1.2 — Attach it to the VPC.** Open the new gateway and choose **Actions → Attach to a VPC → `fitness-assistant-dev-vpc`**. *The runbook has no screenshot of this action.*

#### Step 2 — Create a public subnet for the NAT Gateway

**2.1 — Fill in the subnet.** Open **VPC → Subnets → Create subnet** and enter: VPC `fitness-assistant-dev-vpc`, subnet name `fitness-assistant-dev-public-a`, Availability Zone `ap-southeast-1a`, IPv4 subnet CIDR block `10.0.1.0/24`. Then scroll down and click **Create subnet**.

![Create subnet: VPC, name public-a, ap-southeast-1a, CIDR 10.0.1.0/24](/images/workshop/runbook/img024.jpg)

Auto-assign public IPv4 stays off — the NAT Gateway uses its own Elastic IP. One public subnet is enough for one NAT Gateway in DEV.

#### Step 3 — Create the public route table

**3.1 — Create the table.** Open **VPC → Route tables → Create route table**, name it `fitness-assistant-dev-public-rt`, choose the VPC `fitness-assistant-dev-vpc` and click **Create route table**. *The runbook has no screenshot of this action.*

**3.2 — Add the internet route.** Select the table, open **Routes → Edit routes → Add route**, enter the destination `0.0.0.0/0`, choose the target **Internet Gateway** `fitness-assistant-dev-igw`, then click **Save changes**.

![Edit routes: 0.0.0.0/0 to the Internet Gateway, Save changes](/images/workshop/runbook/img025.jpg)

**3.3 — Associate the public subnet.** Open **Subnet associations → Edit subnet associations**, tick `fitness-assistant-dev-public-a` and click **Save associations**.

![Edit subnet associations: tick public-a, Save associations](/images/workshop/runbook/img026.jpg)

#### Step 4 — Create the NAT Gateway

**4.1 — Fill in the gateway.** Open **VPC → NAT gateways → Create NAT gateway** and enter: name `fitness-assistant-dev-nat-a`, availability mode **Zonal**, subnet `fitness-assistant-dev-public-a`, connectivity type **Public**, and an Elastic IP (click **Allocate Elastic IP** to get one). Then click **Create NAT gateway**.

![Create NAT gateway: name, Zonal, subnet public-a, Public, Elastic IP, Create](/images/workshop/runbook/img027.jpg)

Wait for the state to change from *Pending* to *Available* before touching the private route table.

#### Step 5 — Route the private app subnets through the NAT Gateway

**5.1 — Add the NAT route.** Open **VPC → Route tables → `fitness-assistant-dev-private-app-rt` → Routes → Edit routes → Add route**, enter the destination `0.0.0.0/0`, choose the target **NAT Gateway** `fitness-assistant-dev-nat-a`, then click **Save changes**.

![Private app route table: 0.0.0.0/0 to the NAT Gateway, Save changes](/images/workshop/runbook/img028.jpg)

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

An internet-facing Application Load Balancer needs subnets in at least two Availability Zones. When the Chat Service was deployed, a second public subnet was added.

**6.1 — Create the subnet.** Open **VPC → Subnets → Create subnet** and enter: VPC `fitness-assistant-dev-vpc`, subnet name `fitness-assistant-dev-public-b`, Availability Zone `ap-southeast-1b`, IPv4 subnet CIDR block `10.0.2.0/24`. Then click **Create subnet**.

![Create subnet: VPC, name public-b, ap-southeast-1b, CIDR 10.0.2.0/24, Create subnet](/images/workshop/runbook/img305.jpg)

**6.2 — Open the route table association.** Select the new subnet and choose **Actions → Edit route table association**.

![Subnets list: Actions menu, Edit route table association](/images/workshop/runbook/img306.jpg)

**6.3 — Use the public route table.** Choose `fitness-assistant-dev-public-rt`, the same table used by `public-a` (local + `0.0.0.0/0` → IGW), and click **Save**.

![Edit route table association: fitness-assistant-dev-public-rt, Save](/images/workshop/runbook/img307.jpg)

#### Result

| Subnet | CIDR | AZ | Route table | Hosts |
|---|---|---|---|---|
| `public-a` | 10.0.1.0/24 | 1a | `public-rt` (→ IGW) | NAT Gateway, Chat ALB |
| `public-b` | 10.0.2.0/24 | 1b | `public-rt` (→ IGW) | Chat ALB |
| `private-app-a` | 10.0.10.0/24 | 1a | `private-app-rt` (→ NAT) | Lambda, Fargate tasks |
| `private-app-b` | 10.0.11.0/24 | 1b | `private-app-rt` (→ NAT) | Lambda, Fargate tasks |
| private DB subnets | — | 1a/1b | `private-db-rt` (no internet) | Aurora |
