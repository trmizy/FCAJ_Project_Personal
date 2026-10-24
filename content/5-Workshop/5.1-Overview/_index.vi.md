---
title: "5.1 Tổng quan"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.1. </b> "
---

### Vấn đề

Fitness Assistant là một ứng dụng open-source thật, đang được phát triển tích cực, nhưng chỉ được build và test cho local development qua Docker Compose. Source code không có sẵn bất kỳ AWS deployment, CI/CD pipeline hay cloud infrastructure nào. Workshop này lấp khoảng trống đó bằng cách triển khai một phiên bản production-shaped, serverless-first của ứng dụng lên AWS.

{{% notice note %}}
Phiên bản trước của báo cáo này lên kế hoạch một MVP đơn giản hơn: EC2 + Docker Compose. Kế hoạch đó đã được thay bằng kiến trúc serverless mô tả từ đây trở đi — microservices chạy trên Lambda phía sau API Gateway, Aurora PostgreSQL Serverless, Amazon Bedrock và OpenSearch Serverless cho AI, và ECS Fargate cho thành phần duy nhất (Chat) thực sự cần kết nối sống lâu dài. [Proposal](../../2-Proposal/) và mọi trang Workshop đều mô tả đúng những gì đã thực sự được triển khai.
{{% /notice %}}

### Đối tượng sử dụng

- Thành viên phòng gym / người dùng app fitness theo dõi workout, mục tiêu và nhận gợi ý từ AI coach.
- Chủ phòng gym, huấn luyện viên cá nhân (PT) và quản trị viên quản lý phòng tập, hợp đồng và thanh toán.
- Mentor/reviewer FCAJ đánh giá kết quả thực tập.

### Tính năng ứng dụng (đúng như đã triển khai)

- Đăng ký và đăng nhập dựa trên JWT (`auth-service`, Lambda).
- Hồ sơ, onboarding, InBody, hồ sơ ứng tuyển PT và hợp đồng, file lưu trong S3 bucket private qua presigned URL (`user-service`, Lambda + jobs Lambda).
- Danh mục bài tập, kế hoạch tập, ghi nhận workout, dinh dưỡng và nhắc lịch (`fitness-service`, Lambda + jobs Lambda).
- AI coaching và tạo kế hoạch trên Amazon Bedrock — Nova Pro cho chat/vision, Cohere multilingual embedding cùng vector store OpenSearch Serverless cho retrieval (`ai-service`: HTTP Lambda, Worker chạy theo SQS, Jobs theo lịch).
- Danh sách phòng gym/PT và QR check-in có chữ ký (`gym-service`, Lambda + jobs Lambda), thanh toán ví/hợp đồng PT qua VNPAY, code hỗ trợ thêm MoMo/PayOS/ZaloPay (`payment-service`, Lambda + job reconciliation).
- Chat real-time (`chat-service`) trên Amazon ECS Fargate phía sau Application Load Balancer — Socket.IO cần kết nối sống lâu dài mà Lambda request/response không giữ được.

{{% notice note %}}
Tính năng AI coaching ban đầu chạy trên LLM self-host (Ollama) kèm vector store Qdrant, như đã mô tả ở [Tuần 8](../../1-Worklog/1.8-Week8/) của Worklog. Trên AWS, nó chuyển sang Amazon Bedrock (`apac.amazon.nova-pro-v1:0`, `cohere.embed-multilingual-v3`) và OpenSearch Serverless, bỏ được việc sizing và vá lỗi một instance chạy model. Tính năng **trích xuất ảnh** InBody của `user-service` gọi trực tiếp Anthropic API khi chạy local; API key đó cố ý không được cấu hình trên AWS, nên riêng tính năng này chưa bật trong môi trường DEV. Không tính năng AI nào thay thế được tư vấn y tế.
{{% /notice %}}

### Kết quả mong muốn

Một môi trường DEV hoạt động, truy cập được qua internet: frontend tĩnh trên Amazon S3, cổng vào Amazon API Gateway, sáu microservice chạy trên Lambda và một service ECS Fargate phía sau, một cluster Amazon Aurora PostgreSQL Serverless chứa một logical database cho mỗi service, và AI managed trên Bedrock và OpenSearch Serverless — được ghi lại từng bước kèm bằng chứng (screenshot console, policy, environment variable, kết quả kiểm thử), không phải suy đoán.

### Phạm vi

- **Hạ tầng dùng chung:** một VPC, private application subnet cho Lambda và Fargate, private DB subnet (không có route ra internet), public subnet cho NAT Gateway và Chat ALB, cặp NAT + Internet Gateway cho lời gọi outbound.
- **Tám khối triển khai được ghi lại đầy đủ:** Auth, User, Fitness, Gym, Payment, AI (HTTP + Worker + Jobs + vector search), Chat, và lần migration dữ liệu một lần đã restore 7 database PostgreSQL local vào Aurora.
- **Frontend:** bản build tĩnh host trên Amazon S3 và phát qua Amazon CloudFront (Origin Access Control).

### Sản phẩm bàn giao

- [5.2 Mô tả kiến trúc](../5.2-Architecture-Description/) — luồng request, lựa chọn dịch vụ AWS, security/IAM, khả năng mở rộng và chi phí.
- [5.3 Chuẩn bị](../5.3-Prerequisites/) — account, region và công cụ local.
- [5.4 Hướng dẫn triển khai](../5.4-Deployment-Guide/) — từng service, từng bước, kèm screenshot console gốc và IAM policy chính xác.
- [5.5 Kiểm thử & xác nhận](../5.5-Test-Validation/) — các bài kiểm tra và kết quả mong đợi.
- [5.6 Demo](../5.6-Demo/) và [5.7 Dọn dẹp tài nguyên](../5.7-Cleanup/).

### Định nghĩa hoàn thành

- Mọi dịch vụ AWS được ghi là "Deployed" trong báo cáo đều có screenshot, log excerpt hoặc command output tương ứng trong Workshop này.
- Không bước nào được coi là thành công nếu thiếu bằng chứng.
