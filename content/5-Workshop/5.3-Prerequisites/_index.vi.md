---
title: "5.3 Prerequisites"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.3. </b> "
---

### Tài khoản và quyền truy cập

- Một **tài khoản AWS** (tài khoản Free Tier là đủ để bắt đầu, nhưng xem cảnh báo chi phí bên dưới về AI stack).
- **AWS Region:** `[TODO_AWS_REGION]` — chọn một Region và dùng nhất quán xuyên suốt Workshop này.
- Một IAM user hoặc role có đủ quyền tạo tài nguyên VPC, EC2, RDS, ECR, IAM, Secrets Manager, CloudWatch và SNS. Không dùng credential của tài khoản root cho công việc hàng ngày.

### Công cụ local

| Công cụ | Mục đích | Lệnh kiểm tra |
| --- | --- | --- |
| AWS CLI v2 | Tương tác với AWS từ terminal | `aws --version` |
| Git | Clone ứng dụng và repository của báo cáo này | `git --version` |
| Docker | Build và chạy container ở local | `docker --version` |
| Docker Compose plugin | Chạy stack nhiều container của ứng dụng | `docker compose version` |
| Hugo (Extended) | Build và xem trước website báo cáo này | `hugo version` |

{{% notice note %}}
Chạy từng lệnh kiểm tra và xác nhận có version được in ra trước khi tiếp tục. Không dán AWS access key thật vào bất kỳ file nào trong repository này.
{{% /notice %}}

### Quyền IAM cần thiết (tóm tắt)

Tối thiểu, IAM identity dùng cho Workshop này cần quyền quản lý: tài nguyên mạng VPC/EC2, EC2 instance, Amazon ECR repository, Amazon RDS instance, IAM role/policy (cho instance role của EC2), secret trong AWS Secrets Manager, CloudWatch Logs/Metrics/Alarms, và SNS topic. Xem [5.11 IAM and Secrets](../5.11-IAM-Secrets/) để có ví dụ policy least-privilege.

### Domain

Không bắt buộc cho MVP. Ứng dụng có thể truy cập qua public IP/DNS name của EC2 instance cho workshop này; domain tùy chỉnh qua Amazon Route 53 được liệt kê ở phần hướng phát triển trong [Proposal](../../2-Proposal/#25-hướng-phát-triển).

### Kiến thức nền tảng giả định

- Sử dụng dòng lệnh Linux cơ bản.
- Khái niệm Docker và Docker Compose cơ bản.
- Hiểu biết cơ bản về HTTP, REST API, và database quan hệ.

### Thời gian ước tính

TODO: Ghi lại thời gian thực tế dành cho từng mục Workshop khi hoàn thành (xem [Worklog](../../1-Worklog/) để biết chi tiết theo từng tuần).

### Cảnh báo chi phí ước tính

{{% notice warning %}}
Giá AWS thay đổi theo Region và thời điểm. Trước khi tạo bất kỳ tài nguyên nào, hãy kiểm tra [AWS Pricing Calculator](https://calculator.aws/). Không giả định Free Tier bao phủ toàn bộ workload này — AI service phụ thuộc vào một LLM tự host (Ollama) và một vector database (Qdrant), thường cần nhiều compute hơn instance thuộc Free Tier. Xem [5.9 EC2 Deployment](../5.9-EC2-Deployment/) và [5.14 Security and Cost Optimization](../5.14-Security-Cost/) để biết hướng dẫn về kích thước và chi phí.
{{% /notice %}}
