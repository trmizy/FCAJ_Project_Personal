---
title: "5.2.1 Tổng quan kiến trúc"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.2.1. </b> "
---

### Tóm tắt trạng thái triển khai

Snapshot trạng thái AWS deployment, migration và kiểm thử end-to-end (E2E) hiện tại, ghi trong runbook triển khai. Trạng thái chỉ phản ánh những gì có bằng chứng ở đó.

| Thành phần | AWS Deployment | Migration | E2E | Trạng thái |
|---|---|---|---|---|
| Hạ tầng dùng chung (VPC/Subnet/SG/NAT/IGW) | Complete | N/A | N/A | **COMPLETE** |
| Aurora PostgreSQL | Complete | Complete — 7/7 database đã restore | Verified | **COMPLETE** |
| Auth Service | Deployed | Complete | Passed (kèm fix transaction-atomicity) | **COMPLETE** |
| User Service | Deployed | Complete | Passed | **COMPLETE** |
| Fitness Service | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| Gym Service | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| Payment Service | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| AI / Worker / Jobs | Deployed | Complete | Chờ E2E | NEEDS VERIFICATION |
| Chat Service (REST + Socket.IO) | Deployed | Complete | Chờ full E2E | NEEDS VERIFICATION |
| Frontend (S3) | Deployed | N/A | Chờ full integration E2E | NEEDS VERIFICATION |
| CI/CD | Incomplete | N/A | N/A | **INCOMPLETE** |

Verification migration database: 23/23 foreign key đã audit được áp dụng và xác nhận. Việc xoay vòng credential ADMIN và xử lý nốt seed account được cố ý hoãn lại (không phải blocker hiện tại nhưng vẫn được theo dõi).

### Các thành phần

**Hạ tầng dùng chung**

- Một VPC (`fitness-assistant-dev-vpc`, `10.0.0.0/16`, `ap-southeast-1`).
- Hai private application subnet (Lambda function và Chat Fargate task), hai public subnet (chỉ có NAT Gateway và Chat ALB), và private DB subnet hoàn toàn không có route ra internet.
- Một security group dùng chung cho mọi service chạy trên Lambda, cộng các security group riêng cho Aurora, VPC endpoint, Chat task và Chat ALB.
- Một Internet Gateway và một NAT Gateway để Lambda trong private subnet gọi được Amazon Bedrock và các AWS API khác; interface VPC endpoint giữ traffic tới Secrets Manager và OpenSearch Serverless ở trong mạng private.

**Sáu microservice chạy trên Lambda:** Auth, User, Fitness, Gym, Payment và AI, tất cả nằm sau một Amazon API Gateway HTTP API và dùng chung VPC, security group ở trên. Tổng cộng có 12 function chạy lâu dài — mỗi service một function HTTP, User/Fitness/Gym/Payment/AI có thêm function jobs chạy theo lịch, và AI có thêm Worker nhận việc từ Amazon SQS — cộng một migration function cho mỗi service. Công việc theo lịch được kích hoạt bởi 13 schedule Amazon EventBridge Scheduler.

**Một service ECS Fargate:** Chat, xử lý cả REST API và kết nối real-time Socket.IO. Socket.IO cần một kết nối sống suốt phiên chat — hình dạng mà model request/response của Lambda không phù hợp — nên Chat chạy như một container trên Fargate trong private subnet, phía sau Application Load Balancer internet-facing riêng. Lời gọi REST đi qua API Gateway (`/chat/{proxy+}`), Socket.IO kết nối thẳng tới ALB.

**Một cluster Aurora PostgreSQL Serverless** (`fitness-assistant-dev-aurora`), chứa một logical database cho mỗi service thay vì một database cho mỗi cluster:

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

**AI managed:** Amazon Bedrock (Nova Pro cho chat và vision, Cohere Embed Multilingual v3 cho embedding 1024 chiều) và một vector collection Amazon OpenSearch Serverless (`fitness-assistant-dev-ai-vectors`, NextGen, scale trong khoảng 0–2 OCU), truy cập private qua VPC endpoint.

**Một frontend tĩnh** trên Amazon S3 (website hosting, hiện tại qua HTTP — xem [5.2.7](../5.2.7-Cost-Optimization-Cleanup/) để biết vì sao CloudFront chưa đứng trước nó).

### Khác biệt so với kế hoạch MVP ban đầu

Phiên bản trước của Workshop (xem [Worklog](../../../1-Worklog/) tuần 5–9) lên kế hoạch một EC2 host chạy toàn bộ Docker Compose stack, một instance Amazon RDS và cặp Ollama + Qdrant self-host cho AI. Mục "Future Architecture" của kế hoạch đó đã gọi tên đúng hướng đi sau này: ECS/Fargate thay cho một host duy nhất, Amazon Bedrock thay cho Ollama self-host. Kiến trúc thật còn đi xa hơn: Lambda cho sáu trong bảy service, Aurora Serverless thay cho một RDS instance, và OpenSearch Serverless thay cho Qdrant.

Cách từng service được xây dựng thực tế nằm trong [Hướng dẫn triển khai](../../5.4-Deployment-Guide/); các trang từ [5.2.2](../5.2.2-Architecture-Diagram/) trở đi mô tả hệ thống ở trạng thái hiện tại.
