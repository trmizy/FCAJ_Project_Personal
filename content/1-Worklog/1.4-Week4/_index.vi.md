---
title: "Tuần 4"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 1.4. </b> "
draft: true
---

# WORKLOG TUẦN 4

### Mục tiêu tuần 4:

- Hoàn thành tự học Module 3: Tối ưu hóa hệ thống
- Tìm hiểu sâu hơn về 3 trụ cột của AWS Well-Architected Framework: Operate, Security và Reliability
- Áp dụng kiến thức vào việc tối ưu kiến trúc Fitness Assistant

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Học và hoàn thành Module 3: Tối ưu hóa hệ thống | 10-7-2026 | 16-7-2026 | **Operate:** <br>22: https://000022.awsstudygroup.com/ <br>27: https://000027.awsstudygroup.com/ <br>29: https://000029.awsstudygroup.com/ <br>31: https://000031.awsstudygroup.com/ <br>58: https://000058.awsstudygroup.com/ <br>**Security:** <br>18: https://000018.awsstudygroup.com/ <br>26: https://000026.awsstudygroup.com/ <br>30: https://000030.awsstudygroup.com/ <br>33: https://000033.awsstudygroup.com/ <br>44: https://000044.awsstudygroup.com/ <br>**Reliability:** <br>13: https://000013.awsstudygroup.com/ <br>19: https://000019.awsstudygroup.com/ <br>20: https://000020.awsstudygroup.com/ |

### Kết quả đạt được tuần 4:

**Tổng quan:**

Trong tuần này, mình tập trung vào tối ưu hóa hệ thống (Module 3) thông qua việc khám phá ba trụ cột quan trọng: Operations, Security và Reliability. Mình đã thực hành các giải pháp thực tế để giảm chi phí, theo dõi tập trung, kiểm soát truy cập nghiêm ngặt và xây dựng kiến trúc mạng vững chắc cho Fitness Assistant project.

**Kiến thức lý thuyết học được:**

- **Operations (Operate):** Nắm vững cách tối ưu chi phí EC2 instances bằng AWS Lambda, quản lý tài nguyên thông qua Tagging và Resource Groups, giám sát hệ thống với Amazon CloudWatch và visualize với Grafana, quản lý server tập trung dùng AWS Systems Manager.

- **Security:** Hiểu sâu hơn về kiểm soát quyền truy cập dùng IAM Permission Boundaries và condition keys. Khám phá phát hiện mối đe dọa với AWS Security Hub, lọc traffic web với AWS WAF, và các chiến lược mã hóa data at rest (AWS KMS).

- **Reliability:** Nghiên cứu kết nối mạng cấp doanh nghiệp sử dụng VPC Peering và AWS Transit Gateway, cùng với tự động hóa data retention dùng AWS Backup.

**Hands-on labs đã thực hiện:**

- **Operate:** 
  - Cấu hình Lambda function để tự động bật/tắt EC2 instances theo schedule (giảm cost khi dev environment không dùng)
  - Setup CloudWatch dashboards để monitor metrics của Fitness Assistant services
  - Apply resource tags cho các services (Environment: dev/prod, Service: auth/user/fitness/ai)
  - Thử nghiệm Systems Manager Session Manager để access EC2 không cần SSH key

- **Security:**
  - Implement IAM Permission Boundaries để limit quyền của developer users
  - Configure Security Groups với least privilege principle (chỉ mở ports cần thiết)
  - Research AWS WAF rules để protect API endpoints khỏi common attacks (SQL injection, XSS)
  - Tìm hiểu KMS encryption cho RDS database và S3 buckets (nơi lưu user workout data)

- **Reliability:**
  - Design backup policy cho RDS database dùng AWS Backup (daily snapshots, 7-day retention)
  - Nghiên cứu multi-AZ deployment cho production environment (đảm bảo high availability)
  - Evaluate VPC Peering vs Transit Gateway cho future microservices expansion

**Áp dụng vào Fitness Assistant:**

- Thiết kế cost optimization strategy: schedule để tắt dev environment EC2 ngoài giờ làm việc
- Plan monitoring stack: CloudWatch Logs cho centralized logging, custom metrics cho API latency/error rate
- Security hardening checklist: IAM roles với least privilege, Security Groups strict rules, encryption at rest cho sensitive data
- Backup và disaster recovery plan: automated daily backups, cross-region backup cho production (future)

### Khó khăn gặp phải:

- **IAM Permission Boundaries phức tạp:** Khái niệm Permission Boundaries (giới hạn quyền tối đa) vs inline policies khá khó hiểu ban đầu. Mất khá nhiều thời gian để understand use case thực tế.

- **Cost optimization trade-offs:** Khi research Lambda-based EC2 scheduling, nhận ra có trade-off giữa cost savings và developer convenience. Tắt dev instances có thể gây inconvenience nếu dev cần work ngoài giờ.

- **Monitoring overhead:** Setup comprehensive monitoring tốn effort ban đầu (define metrics, create dashboards, configure alarms). Cần balance giữa "monitor everything" vs "monitor what matters".

### Cách giải quyết:

- **Permission Boundaries:** Vẽ diagram để visualize relationship giữa identity-based policies, permission boundaries và resource-based policies. Practice với concrete examples trong lab.

- **Cost optimization:** Quyết định implement "on-demand start" mechanism: dev có thể trigger Lambda function để start instances khi cần, instances tự động stop sau 2 giờ idle.

- **Monitoring strategy:** Adopt "start simple, iterate" approach. Week 4 focus vào critical metrics (CPU, memory, disk, API error rate), sẽ expand monitoring dần theo experience.

### Kỹ năng / Dịch vụ AWS đã học:

**Services:**
- AWS Lambda (event-driven automation)
- Amazon CloudWatch (logs, metrics, alarms)
- AWS Systems Manager (Session Manager, Patch Manager)
- AWS IAM (Permission Boundaries, condition keys)
- AWS Security Hub (security posture management)
- AWS WAF (web application firewall)
- AWS KMS (encryption key management)
- AWS Backup (automated backup orchestration)
- VPC Peering và AWS Transit Gateway (network connectivity)

**Skills:**
- Cost optimization strategies for cloud infrastructure
- Security best practices (least privilege, defense in depth)
- Centralized monitoring và observability
- Infrastructure automation với Lambda
- Backup và disaster recovery planning

### Liên kết với Fitness Assistant Architecture:

Module 3 insights directly applicable:
- **Operate:** CloudWatch monitoring cho microservices health checks, Lambda automation cho routine tasks
- **Security:** IAM roles cho service-to-service communication, WAF protection cho API Gateway, KMS encryption cho user data
- **Reliability:** Multi-AZ RDS deployment, automated backups, health checks với auto-recovery

### Liên kết Workshop tương ứng:

- [5.2 Architecture](../../5-Workshop/5.2-Architecture/) - Security và network design
- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - Systems Manager usage
