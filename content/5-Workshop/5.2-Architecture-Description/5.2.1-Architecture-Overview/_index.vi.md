---
title: "5.2.1 Tổng quan kiến trúc"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.2.1. </b> "
---

### Tóm tắt trạng thái Deployment

Snapshot trạng thái AWS deployment, migration, và end-to-end (E2E) test hiện tại, ghi lại trong runbook deployment nội bộ. Trạng thái chỉ phản ánh những gì được chứng minh ở đó.

| Thành phần | AWS Deployment | Migration | E2E | Trạng thái |
|---|---|---|---|---|
| Shared Infrastructure (VPC/Subnets/SGs/NAT/IGW) | Complete | N/A | N/A | **COMPLETE** |
| Aurora PostgreSQL | Complete | Complete — 7/7 service DB đã restore | Verified | **COMPLETE** |
| Auth Service | Deployed | Complete | Passed (kèm fix transaction-atomicity) | **COMPLETE** |
| User Service | Deployed | Complete | Passed | **COMPLETE** |
| Fitness Service | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| Gym Service | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| Payment Service | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| AI / Worker / Jobs | Deployed | Complete | Chờ E2E | NEEDS VERIFICATION |
| Chat Service (REST + Socket.IO) | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| Frontend (S3) | Deployed | N/A | Chờ full integration E2E | NEEDS VERIFICATION |
| CI/CD | Incomplete | N/A | N/A | **INCOMPLETE** |

Verification database migration: 23/23 foreign key đã audit, áp dụng và xác nhận. Việc xoay vòng credential ADMIN và xử lý nốt seed account còn lại được cố ý hoãn lại (xem Những phần chưa hoàn thiện).

### Các thành phần

**Hạ tầng dùng chung**

- Một VPC (`fitness-assistant-dev-vpc`, `10.0.0.0/16`, `ap-southeast-1`).
- Hai private application subnet (đặt Lambda), một public subnet (chỉ đặt NAT Gateway — không có Lambda hay DB nào ở đây), và private DB subnet hoàn toàn không có route ra internet.
- Một security group dùng chung cho Lambda, áp dụng cho mọi service chạy trên Lambda.
- Một Internet Gateway và một NAT Gateway, để Lambda trong private subnet gọi được ra ngoài (API Gateway, Bedrock, Secrets Manager).

**Sáu microservice chạy trên Lambda:** Auth, User, Fitness, Gym, Payment, và AI (một HTTP Lambda cộng một Worker chạy nền và một Jobs Lambda cho việc scheduled/async), tất cả nằm phía sau một Amazon API Gateway HTTP API và dùng chung VPC/security group ở trên.

**Một service chạy trên ECS Fargate:** Chat, xử lý cả REST API và kết nối real-time Socket.IO. Socket.IO cần một kết nối sống suốt phiên chat — hình dạng mà model request/response của Lambda không phù hợp — nên Chat chạy như một container trên Fargate phía sau Application Load Balancer riêng của nó thay vì dùng Lambda.

**Một cluster Amazon Aurora PostgreSQL Serverless** (`fitness-assistant-dev-aurora`), chứa một logical database cho mỗi service thay vì một database cho cả cluster:

```
fitness-assistant-dev-aurora
├── fitness_assistant          → Auth
├── fitness_assistant_user     → User
├── fitness_assistant_fitness  → Fitness
├── fitness_assistant_gym      → Gym
├── fitness_assistant_payment  → Payment
├── fitness_assistant_ai       → AI
└── fitness_assistant_chat     → Chat
```

Lambda (hoặc Chat Fargate task) của mỗi service chỉ đọc/ghi database của chính nó, resolve từ `DATABASE_SECRET_ID` riêng trong Secrets Manager — không service nào được cấu hình để truy cập trực tiếp database của service khác.

**Một frontend tĩnh** trên Amazon S3 (website hosting, hiện tại qua HTTP — xem [5.2.7](../5.2.7-Cost-Optimization-Cleanup/) để biết tại sao CloudFront chưa đứng phía trước nó).

### Khác biệt so với kế hoạch MVP ban đầu

Phiên bản trước đây của Workshop này (xem [Worklog](../../../1-Worklog/) Tuần 5–9) lên kế hoạch một EC2 host duy nhất chạy toàn bộ Docker Compose stack, một instance Amazon RDS, và một cặp Ollama + Qdrant self-hosted cho AI. Mục "Future Architecture" của kế hoạch đó đã gọi tên đúng hướng đi sau này: ECS/Fargate thay vì một host duy nhất, và Amazon Bedrock thay vì Ollama self-hosted. Cả hai dự đoán đó đều trở thành kiến trúc thật mô tả ở trang này, sớm hơn cả mục "Future" trong lịch trình 12 tuần ban đầu.

Những gì thay đổi trong thực tế, theo từng service, được mô tả chi tiết ở phần deployment log của từng service trong báo cáo; các phần tiếp theo ([5.2.2](../5.2.2-Architecture-Diagram/) trở đi) mô tả hệ thống ở trạng thái hiện tại, không phải lịch sử của nó.
