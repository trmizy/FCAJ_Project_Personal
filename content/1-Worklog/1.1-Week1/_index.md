---
title: "Week 1 Worklog"
date: 2026-08-03
weight: 1
chapter: false
pre: " <b> 1.1. </b> "
---

### Week 1 Objectives:

- Register AWS account for practice, research Free Tier and cost management.
- Learn and practice the first 5 labs: IAM, VPC, EC2, RDS to master foundational services.
- Prepare environment to start analyzing Fitness Assistant source code next week.

### Tasks for This Week:

| Task | Start Date | Completion Date | Workshop / Reference Materials |
|------|------------|----------------|--------------------------------|
| - Register AWS Free Tier account <br/> - Configure IAM user, enable MFA <br/> - Learn and practice first 5 labs | 08-03-2026 | 08-08-2026 | 1: https://000001.awsstudygroup.com/ <br/> 2: https://000002.awsstudygroup.com/ <br/> 3: https://000003.awsstudygroup.com/ <br/> 4: https://000004.awsstudygroup.com/ <br/> 5: https://000005.awsstudygroup.com/ |
| - Office registration | 08-04-2026 | 08-04-2026 | - |
| - Practice additional lab 10 | 08-04-2026 | 08-04-2026 | - |

### Week 1 Results:

**Overview:**

This week I successfully set up the AWS environment to start learning. The main focus was getting familiar with the most basic services like IAM, EC2, and RDS through 5 labs on AWS Study Group. Initially overwhelming due to many new concepts, but following step by step made things clearer.

**Knowledge Learned:**

- **AWS Account & Free Tier:** How to register an account, understand what's free in Free Tier (EC2 750h/month, RDS 750h/month, S3 5GB). Important to set up Budget alerts from the start to avoid unexpected charges.

- **IAM (Identity and Access Management):** Learned how to create Users, Groups, Policies. Understood why Root account shouldn't be used for daily work. Enabled MFA for both Root and IAM user for security.

- **Amazon VPC:** Learned about virtual networks on AWS, how to create VPC, Subnet, Security Group. This part was a bit difficult requiring understanding of CIDR, routing tables, but necessary for safe app deployment later.

- **Amazon EC2:** Created first instance (t2.micro in Free Tier), SSH into server, installed nginx as test. EC2 feels like renting a VPS but much more flexible.

- **Amazon RDS:** Initialized PostgreSQL database on RDS, connected from EC2. Understood that RDS automatically backs up, Multi-AZ for high availability but more expensive than self-managed DB.

**Hands-on Practice:**

- Successfully created AWS account, verified with visa card
- Completed all 5 labs on AWS Study Group from 000001 to 000005
- Installed AWS CLI on local machine (Windows), tested basic commands like `aws s3 ls`, `aws ec2 describe-instances`
- Created EC2 instance + RDS PostgreSQL, connected 2 services via Security Group
- Attempted additional lab 10 but blocked due to Free Tier account and outdated lab (service no longer supported)

**Difficulties Encountered:**

1. **Account verification pending:** After registration, account was pending verification for nearly 1 day. CloudShell couldn't be used due to "Your account verification is in progress" error. Had to use AWS CLI as workaround.

2. **IAM Policy JSON syntax:** First time writing custom policy in JSON was confusing with many fields: Effect, Action, Resource, Condition. Easy to confuse `*` wildcard with specific ARN.

3. **Security Group configuration:** Inbound/Outbound rules concept was confusing. Especially understanding when to use 0.0.0.0/0 (anywhere) and when to restrict by specific IP.

4. **RDS connection string:** Initially couldn't connect from EC2 to RDS because forgot to config Security Group to allow EC2 security group ID. Had to research security group chaining.

5. **Lab 10 blocked:** When trying additional lab 10, encountered errors because lab was outdated (using old service that was updated) and Free Tier account had limited access to some new services. Need to wait for account upgrade or redo lab with new service.

**Solutions:**

- **Account verify:** Waited 24h for automatic verification, no need to create support case. While waiting, used AWS CLI instead of CloudShell.

- **IAM Policy:** Used AWS Policy Generator UI instead of writing JSON manually. Referenced AWS Managed Policies (AdministratorAccess, PowerUserAccess) to learn structure.

- **Security Group:** Drew diagram to understand traffic flow: Internet → ALB → EC2 → RDS. Each step needs separate security group rule. Practice principle of least privilege.

- **RDS connection:** Instead of using 0.0.0.0/0 for RDS, configured security group rule to allow source as EC2's security group ID. More secure and follows best practice.

- **Lab 10:** Found new documentation from AWS Documentation or practiced similar services via Console to understand operational principles instead of following old lab.
