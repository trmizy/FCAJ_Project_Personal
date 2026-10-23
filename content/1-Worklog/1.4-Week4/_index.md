---
title: "Week 4 Worklog"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 1.4. </b> "
---

### Week 4 Objectives:

- Complete self-study of Module 3: Optimizing the system
- Deepen understanding across the Operate, Security, and Reliability pillars of the AWS Well-Architected Framework
- Turn the module's lessons into concrete requirements for the Fitness Assistant's AWS design
- Start the AWS deployment: shared network, Aurora, the Auth service behind API Gateway, the frontend on S3 and the User service

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 3: Optimizing the system | 24-8-2026 | 29-8-2026 | **Operate:** <br>22: https://000022.awsstudygroup.com/ <br>27: https://000027.awsstudygroup.com/ <br>29: https://000029.awsstudygroup.com/ <br>31: https://000031.awsstudygroup.com/ <br>58: https://000058.awsstudygroup.com/ <br>**Security:** <br>18: https://000018.awsstudygroup.com/ <br>26: https://000026.awsstudygroup.com/ <br>30: https://000030.awsstudygroup.com/ <br>33: https://000033.awsstudygroup.com/ <br>44: https://000044.awsstudygroup.com/ <br>**Reliability:** <br>13: https://000013.awsstudygroup.com/ <br>19: https://000019.awsstudygroup.com/ <br>20: https://000020.awsstudygroup.com/ |
| Deploy the shared network (VPC, subnets, NAT Gateway, security groups), Aurora PostgreSQL Serverless v2, the Auth service on Lambda behind API Gateway, and the frontend on S3 | 26-8-2026 | 27-8-2026 | [5.4.1 Shared network](../../5-Workshop/5.4-Deployment-Guide/5.4.1-Shared-Network/) <br>[5.4.2 Auth Service and API Gateway](../../5-Workshop/5.4-Deployment-Guide/5.4.2-Auth-Service-API-Gateway/) <br>[5.4.3 Frontend on S3](../../5-Workshop/5.4-Deployment-Guide/5.4.3-Frontend-S3/) |
| Deploy the User service (database, Lambda functions and schedules) | 27-8-2026 | 27-8-2026 | [5.4.4 User Service](../../5-Workshop/5.4-Deployment-Guide/5.4.4-User-Service/) |

### Week 4 Achievements:

**Overview:**

During this week, I focused on system optimization (Module 3) by exploring three crucial pillars: Operations, Security, and Reliability. Besides the labs, I used each pillar as a checklist for the Fitness Assistant: what its AWS design must guarantee for access control, private networking, secrets, backups and monitoring, and what it would still cost while nobody is using it. The deployment itself also started this week: the shared network, Aurora, the Auth service behind API Gateway and the frontend on S3 on 26–27 August, then the User service on 27 August.

**Learned theory:**

- **Operations (Operate):** Mastered programmatic cost optimization for EC2 instances using AWS Lambda, resource management through Tagging and Resource Groups, system monitoring with Amazon CloudWatch and visualization with Grafana, and centralized server management utilizing AWS Systems Manager.

- **Security:** Deepened my understanding of access restrictions using IAM Permission Boundaries and condition keys. Explored threat detection with AWS Security Hub, web traffic filtering with AWS WAF, and data encryption strategies at rest (AWS KMS).

- **Reliability:** Studied enterprise-grade network interconnectivity using VPC Peering and AWS Transit Gateway, alongside automated data retention utilizing AWS Backup.

**Hands-on labs:**

- **Operate:**
  - Configured Lambda function to automatically start/stop EC2 instances on schedule (reduce costs when dev environment not in use)
  - Set up CloudWatch dashboards for the lab resources
  - Practised resource tagging and Resource Groups to find resources by environment and service
  - Tested Systems Manager Session Manager for EC2 access without SSH keys

- **Security:**
  - Implemented IAM Permission Boundaries to limit developer user permissions
  - Configured Security Groups with least privilege principle (only open necessary ports)
  - Researched AWS WAF rules to protect API endpoints from common attacks (SQL injection, XSS)
  - Studied KMS encryption at rest for databases and S3 buckets

- **Reliability:**
  - Designed a backup plan with AWS Backup (daily snapshots, 7-day retention)
  - Researched multi-AZ deployment for production environment (ensuring high availability)
  - Evaluated VPC Peering vs Transit Gateway for future microservices expansion

**Applied to Fitness Assistant:**

- **Cost:** The lab saves money by stopping idle EC2 instances on a schedule. For this project I took the idea one step further: use compute that costs nothing while idle (Lambda for the HTTP services and jobs, Aurora Serverless v2 with a low capacity floor), so there is nothing to stop. What still costs money when idle (NAT Gateway, load balancer, VPC endpoints) became the "sleep mode" in the [budget](../../2-Proposal/#budget).
- **Security requirements (applied from the Auth service onward):** one IAM role per function, scoped to its own secret, queue and model; database credentials in Secrets Manager, one secret per service database; compute and database only in private subnets; security groups that reference each other instead of IP ranges.
- **Reliability requirements:** private subnets in two Availability Zones, Aurora automated backups, load-balancer health checks that replace an unhealthy container, and a dead-letter queue so a failing background job is not retried forever.
- **Monitoring plan:** CloudWatch Logs for every function and task from day one, then alarms on the few signals that matter: function errors and throttles, dead-letter queue depth, database capacity and the chat target's health.

### Difficulties Encountered:

- **IAM Permission Boundaries complexity:** The concept of Permission Boundaries (maximum permission limits) vs inline policies was quite confusing initially. Took considerable time to understand real-world use cases.

- **Cost optimization trade-offs:** When researching Lambda-based EC2 scheduling, realized there are trade-offs between cost savings and developer convenience. Stopping dev instances might cause inconvenience if developers need to work outside regular hours.

- **Monitoring overhead:** Setting up comprehensive monitoring requires upfront effort (define metrics, create dashboards, configure alarms). Need to balance between "monitor everything" vs "monitor what matters".

### How It Was Resolved:

- **Permission Boundaries:** Drew diagrams to visualize relationships between identity-based policies, permission boundaries, and resource-based policies. Practiced with concrete examples in labs.

- **Cost optimization:** Avoided the trade-off instead of tuning a schedule: services that scale to zero need no stop/start at all, and the few fixed-cost resources are paused on purpose between test sessions (see [5.7 Clean-up](../../5-Workshop/5.7-Cleanup/#pause)).

- **Monitoring strategy:** Adopted "start simple, iterate" approach: logs first (Lambda functions and ECS tasks send them to CloudWatch with almost no setup), then a short list of alarms on the signals above. The EC2 host metrics used in the lab (CPU, memory, disk) do not apply, because a serverless design has no host to watch.

### AWS Skills / Services Learned:

**Services:**
- AWS Lambda (event-driven automation)
- Amazon CloudWatch (logs, metrics, alarms)
- AWS Systems Manager (Session Manager, Patch Manager)
- AWS IAM (Permission Boundaries, condition keys)
- AWS Security Hub (security posture management)
- AWS WAF (web application firewall)
- AWS KMS (encryption key management)
- AWS Backup (automated backup orchestration)
- VPC Peering and AWS Transit Gateway (network connectivity)

**Skills:**
- Cost optimization strategies for cloud infrastructure
- Security best practices (least privilege, defense in depth)
- Centralized monitoring and observability
- Infrastructure automation with Lambda
- Backup and disaster recovery planning

### Connection to Fitness Assistant Architecture:

Module 3 insights directly applicable:
- **Operate:** CloudWatch Logs for every Lambda function and the chat task; alarms on errors, throttles, dead-letter queue depth and database capacity (planned)
- **Security:** least-privilege role per function, credentials in Secrets Manager, KMS encryption for user data; AWS WAF cannot be attached to an API Gateway HTTP API directly, so it is planned together with CloudFront
- **Reliability:** private subnets in two AZs, Aurora automated backups, health checks with automatic task replacement, dead-letter queue for failed jobs

### Related Workshop Sections:

- [5.2.5 Security and IAM](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/) - Network isolation, least-privilege roles and secrets
- [5.2.6 Scalability and Operations](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/) - Operations, logging and monitoring
