---
title: "Week 5"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 1.5. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Build the network foundation for the MVP: VPC, public and private subnets, route tables, Internet Gateway and Security Groups.
- Apply the principle of least privilege from the very first network resource created.

### Tasks Performed

- Created a VPC with the CIDR block planned in Week 4.
- Created one public subnet (for the EC2 host) and two private subnets across two Availability Zones (for the RDS DB subnet group).
- Created and attached an Internet Gateway, and configured route tables (public route table → Internet Gateway; private route tables with no direct internet route).
- Created Security Groups: one for the EC2 application host, one for RDS, following the matrix drafted in [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/).

### Results Achieved

- A working VPC with the planned subnet layout.
- TODO: Confirm final CIDR ranges used and record them (they may differ from the design placeholders).

### Difficulties

- Deciding whether a NAT Gateway was justified for this MVP, given its ongoing hourly + data-processing cost, versus keeping the private subnets fully isolated (no outbound internet) for the database tier.

### How It Was Resolved

- For the MVP, the private DB subnets do not require outbound internet access (RDS does not need to call out), so a NAT Gateway was treated as optional/future rather than a default MVP component, to keep costs predictable.

### AWS Skills / Services Learned

- Amazon VPC, subnets, route tables, Internet Gateway.
- Security Group design as a stateful allow-list, mapped directly to the real ports used by the application (see [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) for the exact port table).

### Evidence Still Required

- TODO: Screenshot of the VPC console showing the created VPC and subnets.
- TODO: Screenshot of route tables.
- TODO: Screenshot of Security Group rules.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Create VPC and subnets | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 2 | Create and attach Internet Gateway, configure route tables | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 3 | Create Security Groups for EC2 and RDS | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 4 | Validate network layout end to end | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] VPC and subnets created
- [ ] Internet Gateway attached and route tables configured
- [ ] Security Groups created following least privilege
- [ ] Network layout documented with evidence

### Related Workshop Section

- [5.6 Network Infrastructure](../../5-Workshop/5.6-Network-Infrastructure/)
