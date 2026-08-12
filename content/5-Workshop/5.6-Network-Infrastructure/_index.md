---
title: "5.6 Network Infrastructure"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.6. </b> "
---

{{% notice warning %}}
The CIDR ranges below are a **design placeholder** and must be confirmed before real provisioning. They do not represent an already-created VPC.
{{% /notice %}}

### VPC and Subnet Design

```
VPC:                  10.0.0.0/16
Public subnet (EC2):  10.0.1.0/24   (Availability Zone A)
Private DB subnet A:  10.0.11.0/24  (Availability Zone A)
Private DB subnet B:  10.0.12.0/24  (Availability Zone B)
```

Two private subnets, in two different Availability Zones, are required because Amazon RDS DB subnet groups require at least two AZs, even for a single-AZ database instance.

### Internet Gateway and Route Tables

- One Internet Gateway attached to the VPC.
- **Public route table:** `0.0.0.0/0` → Internet Gateway; associated with the public subnet.
- **Private route table(s):** no `0.0.0.0/0` route; associated with the private DB subnets. RDS does not need outbound internet access for this MVP.

### NAT Gateway

**Not used in the MVP.** Since the private subnets only host RDS (which does not need outbound internet access), a NAT Gateway is not required and is intentionally excluded to avoid its hourly and per-GB data-processing cost. If a future service in a private subnet needs outbound internet access, a NAT Gateway would need to be added and its cost accounted for — see the cost warning in [5.14 Security and Cost Optimization](../5.14-Security-Cost/).

### DB Subnet Group

An RDS DB subnet group spanning the two private subnets (`10.0.11.0/24`, `10.0.12.0/24`) across two Availability Zones.

### Security Group Matrix

| Resource | Port | Source | Purpose |
| --- | --- | --- | --- |
| EC2 (application) | 80 | `0.0.0.0/0` | HTTP access to the frontend/reverse proxy |
| EC2 (application) | 443 | `0.0.0.0/0` | HTTPS access (once TLS is configured) |
| EC2 (application) | 22 | `[TODO_ADMIN_IP]/32` | SSH administration — a specific IP only, **never** `0.0.0.0/0` |
| RDS PostgreSQL | 5432 | EC2 application Security Group (by reference, not CIDR) | Database access from the application tier only |

{{% notice warning %}}
Port 22 (SSH) must never be open to `0.0.0.0/0` in this design. Port 5432 (PostgreSQL) on RDS must only accept traffic from the EC2 application Security Group, referenced by Security Group ID, not by CIDR block.
{{% /notice %}}

### Inbound / Outbound Flow Summary

- **Inbound to EC2:** only 80/443 from the internet, and 22 from the administrator's IP.
- **Outbound from EC2:** allowed (needed to pull images from ECR, call the Anthropic API, send logs to CloudWatch, and publish to SNS).
- **Inbound to RDS:** only 5432 from the EC2 Security Group.
- **Outbound from RDS:** not applicable / not required for this MVP.

### Principle of Least Privilege

Every rule above is scoped to the narrowest source that still lets the application function: RDS is reachable only from the application's own Security Group, never from the public internet or from an arbitrary CIDR; SSH is scoped to a single administrator IP, not a broad range.

### Provisioning Commands

Shell variables used throughout (fill in real values — `AWS_REGION` should match the region chosen in [Proposal §21](../../2-Proposal/#21-cost-estimate)):

```bash
export AWS_REGION=<YOUR_AWS_REGION>
export MY_IP=$(curl -s https://checkip.amazonaws.com)/32
```

**1. Create the VPC:**

```bash
export VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=fitness-assistant-vpc}]' \
  --region "$AWS_REGION" --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":true}" --region "$AWS_REGION"
```

**2. Create the three subnets** (one public, two private in different AZs — required for the RDS DB subnet group):

```bash
export AZ_A="${AWS_REGION}a"
export AZ_B="${AWS_REGION}b"

export PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone "$AZ_A" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fitness-assistant-public-a}]' \
  --region "$AWS_REGION" --query 'Subnet.SubnetId' --output text)

export PRIVATE_SUBNET_A_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.11.0/24 --availability-zone "$AZ_A" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fitness-assistant-private-a}]' \
  --region "$AWS_REGION" --query 'Subnet.SubnetId' --output text)

export PRIVATE_SUBNET_B_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.12.0/24 --availability-zone "$AZ_B" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fitness-assistant-private-b}]' \
  --region "$AWS_REGION" --query 'Subnet.SubnetId' --output text)

# Public subnet must auto-assign public IPs for the EC2 instance to be reachable
aws ec2 modify-subnet-attribute --subnet-id "$PUBLIC_SUBNET_ID" --map-public-ip-on-launch --region "$AWS_REGION"
```

**3. Internet Gateway and public route table:**

```bash
export IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=fitness-assistant-igw}]' \
  --region "$AWS_REGION" --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION"

export PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=fitness-assistant-public-rt}]' \
  --region "$AWS_REGION" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$PUBLIC_RT_ID" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID" --region "$AWS_REGION"
aws ec2 associate-route-table --route-table-id "$PUBLIC_RT_ID" --subnet-id "$PUBLIC_SUBNET_ID" --region "$AWS_REGION"
```

Private subnets keep the VPC's implicit "local" route only — no explicit route table or NAT Gateway is created for them (see the NAT Gateway section above).

**4. Security groups:**

```bash
export EC2_SG_ID=$(aws ec2 create-security-group \
  --group-name fitness-assistant-ec2-sg --description "Fitness Assistant app server" \
  --vpc-id "$VPC_ID" --region "$AWS_REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$EC2_SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$AWS_REGION"
aws ec2 authorize-security-group-ingress --group-id "$EC2_SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$AWS_REGION"
aws ec2 authorize-security-group-ingress --group-id "$EC2_SG_ID" --protocol tcp --port 22 --cidr "$MY_IP" --region "$AWS_REGION"

export RDS_SG_ID=$(aws ec2 create-security-group \
  --group-name fitness-assistant-rds-sg --description "RDS PostgreSQL" \
  --vpc-id "$VPC_ID" --region "$AWS_REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$RDS_SG_ID" --protocol tcp --port 5432 \
  --source-group "$EC2_SG_ID" --region "$AWS_REGION"
```

### Verify

```bash
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$AWS_REGION" --query 'Vpcs[0].State'
aws ec2 describe-route-tables --route-table-ids "$PUBLIC_RT_ID" --region "$AWS_REGION"
```

TODO: attach real console screenshots confirming the VPC, subnets, route tables and Security Groups once created.
