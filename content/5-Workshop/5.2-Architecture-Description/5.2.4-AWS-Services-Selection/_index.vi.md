---
title: "5.2.4 Dịch vụ AWS và lý do lựa chọn"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.2.4. </b> "
---

| Dịch vụ AWS | Dùng cho | Vì sao chọn cái này, không phải phương án khác |
|---|---|---|
| **AWS Lambda** | Auth, User, Fitness, Gym, Payment và AI — 12 function chạy lâu dài (HTTP, jobs, AI Worker) cộng các migration function | Sáu trong bảy service là request/response ngắn hoặc việc theo lịch, không cần giữ kết nối mở. Lambda scale về 0 giữa các request — quan trọng với môi trường DEV phần lớn thời gian idle — và bỏ được bài toán sizing instance mà project từng gặp với model self-host trên EC2 (xem [Tuần 8](../../../1-Worklog/1.8-Week8/)). |
| **Amazon ECS trên AWS Fargate** | Chat Service (REST + Socket.IO) và task migrator database chạy một lần | Service duy nhất không thể dùng Lambda: Socket.IO giữ kết nối liên tục theo từng phiên. Fargate chạy container mà không có server nào phải vá; dev sizing 0.5 vCPU / 1 GB. Cùng cluster này chạy task migration dữ liệu khi cần. |
| **Amazon ECR** | Image cho Chat Service và migrator database | Registry private cùng region, ECS pull qua task execution role — không cần credential Docker Hub, không bị rate limit. |
| **Amazon API Gateway (HTTP API)** | Điểm vào duy nhất cho sáu service Lambda và route REST của Chat | Một lớp routing với route prefix tường minh thay vì mỗi service một endpoint công khai; HTTP API rẻ hơn REST API và hỗ trợ throttling theo route, dùng để bảo vệ chi phí Bedrock. |
| **Elastic Load Balancing (ALB)** | Cửa ngõ cho Chat Fargate task | Xử lý nâng cấp Socket.IO/WebSocket, health check `/health`, stickiness và rule theo path để ẩn `/internal/*` và `/metrics`. |
| **Amazon Aurora PostgreSQL Serverless v2** | Một cluster, bảy logical database | PostgreSQL managed khớp với schema Prisma của ứng dụng, tự scale capacity (ACU) và hạ được xuống floor thấp (0.5 ACU khi đang deploy, 0 khi idle). Một cluster thay vì bảy giúp giảm chi phí và công vận hành trong khi mỗi service vẫn có database và secret riêng. |
| **Amazon Bedrock** | Chat và vision (Nova Pro qua APAC inference profile) và embedding (Cohere Embed Multilingual v3) | Thay model Ollama self-host: không có instance phải sizing, không có API key phải quản lý (chỉ IAM), tính tiền theo token, gọi từ VPC như mọi AWS API khác. |
| **Amazon OpenSearch Serverless** | Vector search cho RAG và truy xuất tri thức (`fitness-assistant-dev-ai-vectors`) | Thay container Qdrant self-host: k-NN (FAISS/HNSW, 1024 chiều) không cần server, private qua VPC endpoint, phân quyền bằng IAM + data access policy, và collection group NextGen scale trong khoảng 0–2 OCU. |
| **Amazon SQS** | Hàng đợi AI task và dead-letter queue | Tách các lần tạo kế hoạch AI dài khỏi đường HTTP 30 giây; Worker xử lý từng message một và message lỗi vào DLQ sau hai lần thử. Thay cho Redis/BullMQ, vốn cần một cluster cache chạy liên tục. |
| **Amazon EventBridge Scheduler** | 13 schedule cho settlement, reminder, payout, reconciliation và AI job | Cron managed theo từng job, có retry, không cần process chạy lâu hay `setInterval` trong function HTTP. |
| **Amazon S3** | Frontend tĩnh; upload private (ảnh hồ sơ, tài liệu PT, hợp đồng); artifact deploy; dump migration | Bốn bucket với bốn mô hình truy cập khác nhau — website public-read, private với presigned URL, artifact private cho Lambda, dump private có versioning — nên dữ liệu không bao giờ chung bucket với asset công khai. |
| **AWS Secrets Manager** | Mọi credential database, database URL của Chat, internal secret dùng chung | Không có mật khẩu trong code, image hay environment variable thường; mỗi function chỉ giữ secret ID và resolve lúc runtime. |
| **AWS IAM** | Mỗi function hoặc task một role, scope đúng secret, queue, model và đích invoke của nó | Least privilege theo từng service thay vì một role rộng dùng chung — xem [5.2.5](../5.2.5-Security-IAM/). |
| **Amazon VPC, NAT Gateway, Internet Gateway, VPC endpoint** | Cô lập network và kiểm soát đường ra | Lambda, Fargate và Aurora nằm trong private subnet; một NAT Gateway cho truy cập outbound (Bedrock); interface endpoint giữ traffic Secrets Manager và OpenSearch trong VPC; DB subnet không có route internet nào. |
| **Amazon CloudWatch Logs** | Log cho mọi Lambda, Chat task và migrator | Đích log mặc định cho cả hai loại compute; dùng để troubleshoot khi deploy. Alarm là việc còn mở ([5.2.6](../5.2.6-Scalability-Operations/)). |
| **Amazon CloudFront** | Cửa HTTPS cho web app và Chat | Một distribution phục vụ frontend qua HTTPS và định tuyến `/socket.io/*` tới Chat ALB, nên trình duyệt không bao giờ gửi request mixed-content. Origin của nó là S3 website endpoint. |
| **Amazon CloudWatch Alarms, Amazon SNS, AWS Budgets, AWS X-Ray** | Cảnh báo, thông báo, kiểm soát chi phí và tracing | 12 alarm (lỗi Lambda của sáu service API, API Gateway 5xx, CPU và capacity của Aurora, sức khoẻ NAT Gateway) gửi tới một SNS topic có subscription e-mail đã xác nhận; một budget hàng tháng cảnh báo chi phí; active tracing bật trên sáu Lambda API. |
| **GitHub Actions với AWS CloudFormation** | CI và CD có cổng duyệt | Kiểm tra PR cùng năm workflow có cổng duyệt deploy code Lambda, image Chat và stack API Gateway ([5.4.12](../../5.4-Deployment-Guide/5.4.12-CICD-Pipeline/), [5.4.13](../../5.4-Deployment-Guide/5.4.13-CD-Pipeline-Activation/)). |

### Thành phần tuỳ chọn (không triển khai ở DEV)

- **Amazon Route 53** — site được truy cập qua tên miền CloudFront; tên miền riêng sẽ cần thêm Route 53 và chứng chỉ ACM.
- **AWS WAF** — tuỳ chọn; CloudFront đã có nên có thể gắn web ACL khi cần.
- **Amazon RDS Proxy** — tuỳ chọn; các Lambda kết nối thẳng tới Aurora.
- **Amazon ElastiCache** — chưa cần: hàng đợi đã chuyển sang SQS và Chat Service chạy một task. Chỉ cần khi muốn chia sẻ trạng thái Socket.IO giữa nhiều Chat task.
