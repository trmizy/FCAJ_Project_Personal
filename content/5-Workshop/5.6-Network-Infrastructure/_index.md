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
