---
title: "5.3.1 Tài khoản AWS và quyền truy cập"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.3.1. </b> "
---

#### Tài khoản AWS

Mọi resource nằm trong một AWS account chỉ dùng cho môi trường DEV của dự án. Tên resource đều bắt đầu bằng `fitness-assistant-dev-` (và được gắn tag `project=fitness-assistant`, `environment=dev` khi console cho phép), nhờ vậy việc dọn dẹp ở [5.7](../../5.7-Cleanup/) chỉ cần lọc theo tên.

#### Identity dùng trên console

Việc triển khai được thực hiện trên AWS Management Console bằng một IAM user (không dùng root user). Identity này cần quyền tạo và cấu hình các dịch vụ dùng trong workshop:

| Nhóm | Dịch vụ |
|---|---|
| Compute | AWS Lambda, Amazon ECS (Fargate), Amazon ECR |
| API và network | Amazon API Gateway (HTTP API), Elastic Load Balancing (ALB), Amazon VPC (subnet, route table, NAT/Internet Gateway, security group, VPC endpoint) |
| Dữ liệu | Amazon Aurora PostgreSQL, Amazon S3, AWS Secrets Manager, Amazon OpenSearch Serverless |
| Hàng đợi và lịch | Amazon SQS, Amazon EventBridge Scheduler |
| AI | Amazon Bedrock |
| Bảo mật và quan sát | AWS IAM (role và inline policy), Amazon CloudWatch Logs |

{{% notice note %}}
Bản thân ứng dụng không bao giờ chạy với quyền console này. Mỗi Lambda function và ECS task có execution role riêng với inline policy giới hạn đúng secret, queue và function mà nó dùng — xem [5.2.5 Bảo mật và IAM](../../5.2-Architecture-Description/5.2.5-Security-IAM/).
{{% /notice %}}

#### Quyền truy cập model Amazon Bedrock (một lần)

AI service dùng hai model Bedrock:

| Mục đích | Model | Model ID trong code |
|---|---|---|
| Chat và vision | Amazon Nova Pro (APAC cross-region inference profile) | `apac.amazon.nova-pro-v1:0` |
| Embedding (1024 chiều) | Cohere Embed Multilingual v3 | `cohere.embed-multilingual-v3` |

Cohere là model bên thứ ba cung cấp qua AWS Marketplace, nên subscription/EULA phải được admin chấp nhận một lần trên console. Role runtime của Lambda cố ý **không** được cấp quyền `aws-marketplace:*` để tự làm việc này. Cả hai model đều không cần API key — Lambda gọi Bedrock bằng IAM role của nó.

#### Credential của payment provider

Payment service được cấu hình `PAYMENT_PROVIDER=VNPAY`. Credential của provider (terminal code và hash secret của VNPAY, và key MoMo / PayOS / ZaloPay khi bổ sung) chỉ được nhập khi có credential sandbox thật, và không bao giờ được sao chép vào chat, tài liệu hay source control.
