---
title: "Worklog Tuần 4"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 1.4. </b> "
---

# WORKLOG TUẦN 4

### Mục tiêu tuần 4:

- Hoàn thành tự học Module 3: Tối ưu hóa hệ thống
- Tìm hiểu sâu hơn về 3 trụ cột của AWS Well-Architected Framework: Operate, Security và Reliability
- Biến những gì học được thành yêu cầu cụ thể cho thiết kế AWS của Fitness Assistant

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Học và hoàn thành Module 3: Tối ưu hóa hệ thống | 10-7-2026 | 16-7-2026 | **Operate:** <br>22: https://000022.awsstudygroup.com/ <br>27: https://000027.awsstudygroup.com/ <br>29: https://000029.awsstudygroup.com/ <br>31: https://000031.awsstudygroup.com/ <br>58: https://000058.awsstudygroup.com/ <br>**Security:** <br>18: https://000018.awsstudygroup.com/ <br>26: https://000026.awsstudygroup.com/ <br>30: https://000030.awsstudygroup.com/ <br>33: https://000033.awsstudygroup.com/ <br>44: https://000044.awsstudygroup.com/ <br>**Reliability:** <br>13: https://000013.awsstudygroup.com/ <br>19: https://000019.awsstudygroup.com/ <br>20: https://000020.awsstudygroup.com/ |

### Kết quả đạt được tuần 4:

**Tổng quan:**

Trong tuần này, mình tập trung vào tối ưu hóa hệ thống (Module 3) thông qua việc khám phá ba trụ cột quan trọng: Operations, Security và Reliability. Ngoài các lab, mình dùng từng trụ cột như một checklist cho Fitness Assistant: thiết kế AWS phải đảm bảo những gì về kiểm soát truy cập, mạng private, secret, backup và giám sát, và hệ thống vẫn tốn bao nhiêu tiền khi không có ai dùng.

**Kiến thức lý thuyết học được:**

- **Operations (Operate):** Nắm vững cách tối ưu chi phí EC2 instances bằng AWS Lambda, quản lý tài nguyên thông qua Tagging và Resource Groups, giám sát hệ thống với Amazon CloudWatch và visualize với Grafana, quản lý server tập trung dùng AWS Systems Manager.

- **Security:** Hiểu sâu hơn về kiểm soát quyền truy cập dùng IAM Permission Boundaries và condition keys. Khám phá phát hiện mối đe dọa với AWS Security Hub, lọc traffic web với AWS WAF, và các chiến lược mã hóa data at rest (AWS KMS).

- **Reliability:** Nghiên cứu kết nối mạng cấp doanh nghiệp sử dụng VPC Peering và AWS Transit Gateway, cùng với tự động hóa data retention dùng AWS Backup.

**Hands-on labs đã thực hiện:**

- **Operate:** 
  - Cấu hình Lambda function để tự động bật/tắt EC2 instances theo schedule (giảm cost khi dev environment không dùng)
  - Setup CloudWatch dashboards cho các resource trong lab
  - Thực hành gắn tag và dùng Resource Groups để tìm resource theo môi trường và service
  - Thử nghiệm Systems Manager Session Manager để access EC2 không cần SSH key

- **Security:**
  - Implement IAM Permission Boundaries để limit quyền của developer users
  - Configure Security Groups với least privilege principle (chỉ mở ports cần thiết)
  - Research AWS WAF rules để protect API endpoints khỏi common attacks (SQL injection, XSS)
  - Tìm hiểu KMS encryption at rest cho database và S3 bucket

- **Reliability:**
  - Thiết kế backup plan với AWS Backup (daily snapshots, 7-day retention)
  - Nghiên cứu multi-AZ deployment cho production environment (đảm bảo high availability)
  - Evaluate VPC Peering vs Transit Gateway cho future microservices expansion

**Áp dụng vào Fitness Assistant:**

- **Chi phí:** Lab tiết kiệm tiền bằng cách tắt EC2 instance idle theo lịch. Với dự án này, mình đi xa hơn một bước: dùng loại compute không tốn tiền khi idle (Lambda cho các HTTP service và job, Aurora Serverless v2 với capacity tối thiểu thấp), nên không có gì cần tắt. Những thứ vẫn tốn tiền khi idle (NAT Gateway, load balancer, VPC endpoint) trở thành "chế độ ngủ" trong [ngân sách](../../2-Proposal/#budget).
- **Yêu cầu bảo mật:** mỗi function một IAM role, chỉ có quyền trên secret, queue và model của chính nó; credential database nằm trong Secrets Manager, mỗi database của service một secret; compute và database chỉ nằm trong private subnet; security group tham chiếu lẫn nhau thay vì mở theo dải IP.
- **Yêu cầu về độ tin cậy:** private subnet trải trên hai Availability Zone, automated backup của Aurora, health check của load balancer để thay container bị lỗi, và dead-letter queue để job nền bị lỗi không bị retry mãi.
- **Kế hoạch giám sát:** CloudWatch Logs cho mọi function và task ngay từ đầu, sau đó đặt alarm cho vài tín hiệu quan trọng: lỗi và throttle của function, độ sâu dead-letter queue, capacity của database và health của Chat target.

### Khó khăn gặp phải:

- **IAM Permission Boundaries phức tạp:** Khái niệm Permission Boundaries (giới hạn quyền tối đa) vs inline policies khá khó hiểu ban đầu. Mất khá nhiều thời gian để understand use case thực tế.

- **Cost optimization trade-offs:** Khi research Lambda-based EC2 scheduling, nhận ra có trade-off giữa cost savings và developer convenience. Tắt dev instances có thể gây inconvenience nếu dev cần work ngoài giờ.

- **Monitoring overhead:** Setup comprehensive monitoring tốn effort ban đầu (define metrics, create dashboards, configure alarms). Cần balance giữa "monitor everything" vs "monitor what matters".

### Cách giải quyết:

- **Permission Boundaries:** Vẽ diagram để visualize relationship giữa identity-based policies, permission boundaries và resource-based policies. Practice với concrete examples trong lab.

- **Cost optimization:** Tránh hẳn trade-off thay vì tinh chỉnh lịch bật/tắt: service scale về 0 thì không cần bật/tắt, còn vài resource có chi phí cố định thì được chủ động tạm dừng giữa các đợt kiểm thử (xem [5.7 Dọn dẹp tài nguyên](../../5-Workshop/5.7-Cleanup/#pause)).

- **Monitoring strategy:** Áp dụng cách "start simple, iterate": có log trước (Lambda function và ECS task gửi log lên CloudWatch gần như không cần cấu hình), rồi mới đặt một danh sách ngắn alarm cho các tín hiệu ở trên. Các metric host của EC2 dùng trong lab (CPU, memory, disk) không áp dụng được, vì thiết kế serverless không có host nào để theo dõi.

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
- **Operate:** CloudWatch Logs cho mọi Lambda function và Chat task; alarm cho lỗi, throttle, độ sâu dead-letter queue và capacity của database (dự kiến)
- **Security:** mỗi function một role với quyền tối thiểu, credential trong Secrets Manager, KMS encryption cho dữ liệu người dùng; AWS WAF không gắn trực tiếp được vào API Gateway HTTP API nên được lên kế hoạch cùng CloudFront
- **Reliability:** private subnet trên hai AZ, automated backup của Aurora, health check tự thay task bị lỗi, dead-letter queue cho job lỗi

### Liên kết Workshop tương ứng:

- [5.2.5 Bảo mật và IAM](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/) - Cô lập mạng, role quyền tối thiểu và secret
- [5.2.6 Khả năng mở rộng và vận hành](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/) - Vận hành, logging và monitoring
