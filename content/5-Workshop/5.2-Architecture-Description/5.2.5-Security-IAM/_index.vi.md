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

### Khoảng trống đã biết (mở, không giấu)

- **Internal secret nằm trong cấu hình Lambda** — `INTERNAL_SERVICE_SECRET` và `CHECKIN_TOKEN_SECRET` là environment variable của Lambda (được mã hoá khi lưu, nhưng ai có quyền xem cấu hình function đều đọc được). Chat đã đọc internal secret từ Secrets Manager; chuyển bản trên Lambda sang đó là việc hardening tiếp theo.
- **HTTPS** — web app và Chat được phục vụ qua HTTPS bằng CloudFront; bản thân Chat ALB chỉ có HTTP phía sau nó. Tên miền riêng và chứng chỉ ACM là bước tiếp theo tuỳ chọn.
- **Statement public-read cũ trên bucket frontend** — chỉ object (`s3:GetObject`). CloudFront đã đọc bucket qua Origin Access Control, nên có thể gỡ statement này để bucket hoàn toàn private.
- **WAF** — tuỳ chọn và chưa triển khai; CloudFront đã có nên có thể gắn web ACL khi cần.
- **12 seed account còn lại** — hoãn lại, bắt buộc phải xử lý trước khi release rộng hơn.

### Screenshot bằng chứng từng chứa secret

Một số screenshot console trong runbook triển khai (màn hình "Store a new secret" của Secrets Manager và "Environment variables" của Lambda) ban đầu có hiện giá trị secret thật. Mỗi ảnh đã được che ở mức pixel — chính giá trị bị bôi đen trong dữ liệu ảnh, không phải crop hay blur — trước khi đưa vào báo cáo; các ô đen trong [5.4](../../5.4-Deployment-Guide/) là có chủ đích. Toàn bộ screenshot đã được rà soát lại trước khi đăng.
