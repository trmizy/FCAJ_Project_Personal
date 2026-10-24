---
title: "5.2.5 Bảo mật và IAM"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.2.5. </b> "
---

### Cô lập network

- Lambda function và Chat Fargate task chỉ chạy trong hai private application subnet; resource duy nhất ở public subnet là NAT Gateway và Chat ALB internet-facing.
- Aurora nằm trong private DB subnet với route table **không có** route NAT hay internet, nên tầng database không thể ra internet cũng như không thể bị truy cập từ internet.
- Security group tham chiếu lẫn nhau thay vì dải IP:

| Security group | Inbound |
|---|---|
| `fitness-assistant-dev-aurora-sg` | 5432 chỉ từ `lambda-sg` và `chat-sg` |
| `fitness-assistant-dev-chat-sg` | 3005 chỉ từ `chat-alb-sg` |
| `fitness-assistant-dev-chat-alb-sg` | 80 từ internet (DEV, HTTP) |
| `fitness-assistant-dev-vpce-sg` | 443 từ `lambda-sg` (endpoint Secrets Manager và OpenSearch) |
| `fitness-assistant-dev-lambda-sg` | không có |

- OpenSearch Serverless chỉ truy cập được qua VPC endpoint (đã tắt public access).
- Chat ALB trả 404 cố định cho `/internal/*` và `/metrics`, và API Gateway không có route `/internal/*`, `/metrics` hay catch-all, nên các endpoint service-to-service hoàn toàn không truy cập được từ internet.

### IAM — least privilege theo từng function

Mỗi function và task có role riêng. Role của Lambda bắt đầu từ `AWSLambdaBasicExecutionRole` (log) và `AWSLambdaVPCAccessExecutionRole` (network VPC), rồi thêm inline policy chỉ đích danh từng resource:

| Nhu cầu | Cách giới hạn |
|---|---|
| Credential database | `secretsmanager:GetSecretValue` chỉ trên ARN secret của chính service đó |
| Gọi service khác | `lambda:InvokeFunction` trên đúng ARN function đích (ví dụ Payment → Auth, User, Gym, AI), không bao giờ `lambda:*` |
| Upload private | `s3:PutObject/GetObject/DeleteObject` chỉ trên ba prefix của bucket upload (`profile-photos/`, `pt-applications/`, `contracts/`), không có `s3:ListBucket` |
| Hàng đợi AI | HTTP Lambda: `sqs:SendMessage`; Worker: `ReceiveMessage`, `DeleteMessage`, `GetQueueAttributes` — trên đúng một queue |
| Bedrock | `bedrock:InvokeModel` trên APAC Nova Pro inference profile, trên foundation model Nova Pro **chỉ khi gọi qua profile đó** (IAM condition), và trên Cohere Embed Multilingual v3 — không có `AmazonBedrockFullAccess`, không có quyền streaming |
| OpenSearch | `aoss:APIAccessAll` trên đúng ARN collection, cộng data access policy cấp quyền đọc/ghi/tạo index cho ba AI role nhưng không có `DeleteIndex` |
| Schedule | Mỗi service một scheduler role, trust `scheduler.amazonaws.com`, chỉ được invoke function jobs của service đó |
| ECS | Execution role (pull image, ghi log, inject hai secret của Chat) tách khỏi task role (chỉ invoke Auth/User) |
| Task migration | Chỉ đọc prefix dumps của bucket migration và credential database |

Subscription Marketplace cho Cohere được admin chấp nhận một lần; role runtime không có quyền `aws-marketplace:*`.

### Secret

- Mọi credential database nằm trong AWS Secrets Manager, mỗi database của service một secret (`fitness-assistant/dev/<service>-database`); function chỉ giữ `DATABASE_SECRET_ID`. Chat task nhận database URL và internal secret dưới dạng ECS secret (`valueFrom`), không bao giờ là giá trị thường.
- Lời gọi service-to-service mang `INTERNAL_SERVICE_SECRET` dùng chung, tách biệt với JWT của người dùng. Gym Service ký mã QR check-in bằng `CHECKIN_TOKEN_SECRET` riêng, cố ý khác với internal secret.
- Key của payment provider chỉ được nhập khi có credential sandbox thật và không bao giờ được sao chép vào chat, tài liệu hay source control.
- Bedrock không cần API key — mọi lời gọi model đều được ủy quyền bằng IAM role của function.

### Bảo vệ khỏi lạm dụng và chi phí

- Throttling theo route trên API Gateway cho các route AI (1 request/giây, burst 3; 3/6 cho marketplace) giới hạn tốc độ một client có thể tạo lời gọi Bedrock tính phí; frontend hiển thị thông báo "quá nhiều yêu cầu" khi gặp HTTP 429.
- SQS dead-letter queue (2 lần thử) ngăn một AI job lỗi bị retry mãi mãi.
