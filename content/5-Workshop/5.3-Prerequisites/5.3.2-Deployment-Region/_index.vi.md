---
title: "Region triển khai"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.3.2. </b> "
---

Mọi resource trong workshop được tạo ở **Asia Pacific (Singapore) — `ap-southeast-1`**. Hãy kiểm tra ô chọn region ở góc trên bên phải console trước mỗi bước; nhiều resource (secret, queue, Lambda function) không hiện ở region khác và rất dễ bị tạo nhầm ở region sai.

| Yêu cầu | `ap-southeast-1` đáp ứng thế nào |
|---|---|
| Độ trễ thấp cho người dùng ở Việt Nam | Region thương mại gần nhất có đủ các dịch vụ dùng ở đây |
| Amazon Bedrock — Nova Pro | Gọi qua **APAC** cross-region inference profile `apac.amazon.nova-pro-v1:0` từ Singapore |
| Amazon Bedrock — Cohere Embed Multilingual v3 | Có sẵn dạng foundation model ở `ap-southeast-1` |
| Amazon OpenSearch Serverless | Thế hệ **NextGen** (có scale-to-zero) có ở Singapore |
| Aurora PostgreSQL Serverless v2, ECS Fargate, API Gateway HTTP API | Đều có trong region |

#### Các Availability Zone sử dụng

| AZ | Subnet |
|---|---|
| `ap-southeast-1a` | `fitness-assistant-dev-private-app-a` (10.0.10.0/24), `fitness-assistant-dev-public-a` (10.0.1.0/24) |
| `ap-southeast-1b` | `fitness-assistant-dev-private-app-b` (10.0.11.0/24), `fitness-assistant-dev-public-b` (10.0.2.0/24) |

Lambda function và Chat Fargate task chạy ở cả hai private application subnet. Public subnet thứ hai tồn tại vì Application Load Balancer internet-facing cần subnet ở ít nhất hai Availability Zone.
