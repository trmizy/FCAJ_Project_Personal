---
title: "Tổng quan kiến trúc"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.2.1. </b> "
---

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

**Một frontend tĩnh** trên Amazon S3 phát qua Amazon CloudFront (Origin Access Control).

### Khác biệt so với kế hoạch MVP ban đầu

Phiên bản trước của Workshop lên kế hoạch một EC2 host chạy toàn bộ Docker Compose stack, một instance Amazon RDS và cặp Ollama + Qdrant self-host cho AI ([Tuần 6](../../../1-Worklog/1.6-Week6/) trong Worklog so sánh kế hoạch đó với thiết kế được chọn). Mục "Future Architecture" của kế hoạch đó đã gọi tên đúng hướng đi sau này: ECS/Fargate thay cho một host duy nhất, Amazon Bedrock thay cho Ollama self-host. Kiến trúc thật còn đi xa hơn: Lambda cho sáu trong bảy service, Aurora Serverless thay cho một RDS instance, và OpenSearch Serverless thay cho Qdrant.

Cách từng service được xây dựng thực tế nằm trong [Hướng dẫn triển khai](../../5.4-Deployment-Guide/); các trang từ [5.2.2](../5.2.2-Architecture-Diagram/) trở đi mô tả hệ thống ở trạng thái hiện tại.
