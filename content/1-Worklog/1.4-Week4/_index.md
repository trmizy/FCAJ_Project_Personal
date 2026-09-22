---
title: "Week 4 Worklog"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 1.4. </b> "
---

# WEEK 4 WORKLOG

### Week 4 Objectives:

- Complete self-study of Module 3: Optimizing the system
- Deepen understanding across the Operate, Security, and Reliability pillars of the AWS Well-Architected Framework
- Apply knowledge to optimize Fitness Assistant architecture

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 3: Optimizing the system | 10-7-2026 | 16-7-2026 | **Operate:** <br>22: https://000022.awsstudygroup.com/ <br>27: https://000027.awsstudygroup.com/ <br>29: https://000029.awsstudygroup.com/ <br>31: https://000031.awsstudygroup.com/ <br>58: https://000058.awsstudygroup.com/ <br>**Security:** <br>18: https://000018.awsstudygroup.com/ <br>26: https://000026.awsstudygroup.com/ <br>30: https://000030.awsstudygroup.com/ <br>33: https://000033.awsstudygroup.com/ <br>44: https://000044.awsstudygroup.com/ <br>**Reliability:** <br>13: https://000013.awsstudygroup.com/ <br>19: https://000019.awsstudygroup.com/ <br>20: https://000020.awsstudygroup.com/ |

### Week 4 Achievements:

**Overview:**

During this week, I focused on system optimization (Module 3) by exploring three crucial pillars: Operations, Security, and Reliability. I implemented practical solutions for cost reduction, centralized monitoring, strict access controls, and robust network architectures for the Fitness Assistant project.

**Learned theory:**

- **Operations (Operate):** Mastered programmatic cost optimization for EC2 instances using AWS Lambda, resource management through Tagging and Resource Groups, system monitoring with Amazon CloudWatch and visualization with Grafana, and centralized server management utilizing AWS Systems Manager.

- **Security:** Deepened my understanding of access restrictions using IAM Permission Boundaries and condition keys. Explored threat detection with AWS Security Hub, web traffic filtering with AWS WAF, and data encryption strategies at rest (AWS KMS).

- **Reliability:** Studied enterprise-grade network interconnectivity using VPC Peering and AWS Transit Gateway, alongside automated data retention utilizing AWS Backup.

**Hands-on labs:**

- **Operate:**
  - Configured Lambda function to automatically start/stop EC2 instances on schedule (reduce costs when dev environment not in use)
  - Set up CloudWatch dashboards to monitor Fitness Assistant services metrics
  - Applied resource tags for services (Environment: dev/prod, Service: auth/user/fitness/ai)
  - Tested Systems Manager Session Manager for EC2 access without SSH keys

- **Security:**
  - Implemented IAM Permission Boundaries to limit developer user permissions
  - Configured Security Groups with least privilege principle (only open necessary ports)
  - Researched AWS WAF rules to protect API endpoints from common attacks (SQL injection, XSS)
  - Studied KMS encryption for RDS database and S3 buckets (storing user workout data)

- **Reliability:**
  - Designed backup policy for RDS database using AWS Backup (daily snapshots, 7-day retention)
  - Researched multi-AZ deployment for production environment (ensuring high availability)
  - Evaluated VPC Peering vs Transit Gateway for future microservices expansion

**Applied to Fitness Assistant:**

- Designed cost optimization strategy: schedule to stop dev environment EC2 outside working hours
- Planned monitoring stack: CloudWatch Logs for centralized logging, custom metrics for API latency/error rate
- Security hardening checklist: IAM roles with least privilege, strict Security Groups rules, encryption at rest for sensitive data
- Backup and disaster recovery plan: automated daily backups, cross-region backup for production (future)

### Difficulties Encountered:

- **IAM Permission Boundaries complexity:** The concept of Permission Boundaries (maximum permission limits) vs inline policies was quite confusing initially. Took considerable time to understand real-world use cases.

- **Cost optimization trade-offs:** When researching Lambda-based EC2 scheduling, realized there are trade-offs between cost savings and developer convenience. Stopping dev instances might cause inconvenience if developers need to work outside regular hours.

- **Monitoring overhead:** Setting up comprehensive monitoring requires upfront effort (define metrics, create dashboards, configure alarms). Need to balance between "monitor everything" vs "monitor what matters".

### How It Was Resolved:

- **Permission Boundaries:** Drew diagrams to visualize relationships between identity-based policies, permission boundaries, and resource-based policies. Practiced with concrete examples in labs.

- **Cost optimization:** Decided to implement "on-demand start" mechanism: developers can trigger Lambda function to start instances when needed, instances automatically stop after 2 hours idle.

- **Monitoring strategy:** Adopted "start simple, iterate" approach. Week 4 focused on critical metrics (CPU, memory, disk, API error rate), will expand monitoring gradually based on experience.

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
- **Operate:** CloudWatch monitoring for microservices health checks, Lambda automation for routine tasks
- **Security:** IAM roles for service-to-service communication, WAF protection for API Gateway, KMS encryption for user data
- **Reliability:** Multi-AZ RDS deployment, automated backups, health checks with auto-recovery

### Related Workshop Sections:

- [5.2 Architecture](../../5-Workshop/5.2-Architecture/) - Security and network design
- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - Systems Manager usage
