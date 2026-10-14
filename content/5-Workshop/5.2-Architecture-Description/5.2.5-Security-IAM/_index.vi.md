---
title: "5.2.5 Bảo mật và IAM"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.2.5. </b> "
---

### Cô lập Network

- Mọi service chạy trên Lambda và Aurora đều nằm trong một VPC (`fitness-assistant-dev-vpc`), không resource nào đặt ở public subnet ngoại trừ chính NAT Gateway.
- Lambda chạy trong hai private application subnet, chỉ ra internet gián tiếp qua NAT Gateway và Internet Gateway — không có đường inbound trực tiếp nào tới ENI của Lambda từ internet.
- Aurora nằm trong private DB subnet riêng, gắn với route table **không có** route NAT hay internet nào cả — tầng database không thể truy cập internet, hay bị truy cập từ internet, dù route table khác có bị cấu hình sai.
- Một security group dùng chung (`fitness-assistant-dev-lambda-sg`) phủ outbound rule cho mọi service chạy trên Lambda; security group của Aurora chỉ chấp nhận kết nối inbound ở port 5432 từ security group Lambda đó (và riêng, từ security group của Chat Fargate task).
- Chat Fargate task có security group riêng, chỉ truy cập được từ security group của Chat ALB ở container port — không phải từ internet trực tiếp, và không phải từ security group Lambda.

### IAM — Least Privilege theo từng Service

Mỗi Lambda có execution role riêng, thay vì một role dùng chung cho mọi service. Mỗi role được xây từ cùng một bộ AWS managed policy nhỏ (`AWSLambdaBasicExecutionRole` cho CloudWatch Logs, `AWSLambdaVPCAccessExecutionRole` để chạy trong VPC) cộng một inline policy scope đúng những gì service đó cần, ví dụ:

- Inline policy của một migration Lambda chỉ cấp `secretsmanager:GetSecretValue` trên đúng ARN secret database của service đó — không phải mọi secret trong account.
- Một service cần gọi trực tiếp service khác (ví dụ Payment invoke Auth hoặc User) có inline policy scope `lambda:InvokeFunction` chỉ trên đúng ARN function đích mà nó gọi, không phải `lambda:*` wildcard.
- Role của AI Worker và Jobs Lambda scope đúng secret database AI và đúng SQS queue / EventBridge schedule mà chúng tiêu thụ — không phải quyền SQS hay EventBridge toàn account.
- Quyền Bedrock được thêm vào role của AI HTTP Lambda bằng cách thêm có chọn lọc các statement Bedrock vào policy sẵn có, không phải thay bằng một managed policy rộng như `AmazonBedrockFullAccess`.

### Quản lý Secret

- Mọi credential database nằm trong AWS Secrets Manager, một secret cho mỗi database của service (`fitness-assistant/dev/<service>-database`). Không environment variable nào của Lambda chứa password thô — mỗi Lambda chỉ giữ `DATABASE_SECRET_ID` và resolve giá trị từ Secrets Manager lúc runtime.
- Các lời gọi service-to-service (ví dụ Payment invoke Auth) xác thực bằng `INTERNAL_SERVICE_SECRET` dùng chung, tách biệt khỏi bất kỳ JWT end-user nào, để một lời gọi nội bộ không thể bị replay như thể đến từ một user đã đăng nhập.
- Một secret riêng, `CHECKIN_TOKEN_SECRET`, ký token QR check-in của Gym Service — cố ý khác giá trị với `INTERNAL_SERVICE_SECRET`, để lộ một cái không kéo theo lộ cái kia.
- Credential của payment provider (VNPAY, và MoMo/PayOS/ZaloPay khi thêm dần) theo cùng pattern: lưu dưới dạng secret, tham chiếu bằng ID, không bao giờ dán vào chat, tài liệu, hay source control.

### Khoảng trống bảo mật đã biết (mở, không giấu)

Nhất quán với [Definition of Done](../../5.1-Overview/) của báo cáo này, các mục dưới đây được theo dõi công khai thay vì ngầm bỏ qua:

- **Xoay vòng credential ADMIN** — hoãn lại. Không phải blocker cho môi trường DEV hiện tại, nhưng bắt buộc trước khi release rộng hơn.
- **Xử lý nốt seed account còn lại** — 12 seed account từ lần load dữ liệu ban đầu vẫn cần xử lý.
- **HTTPS** — cả frontend (S3 website endpoint) và Chat ALB hiện đang chạy HTTP thuần ở DEV. Chuyển sang HTTPS phụ thuộc vào domain name và chứng chỉ ACM, hiện chưa có.
- **Chưa có WAF** — xem [5.2.4](../5.2.4-AWS-Services-Selection/) để biết lý do; chưa có CloudFront distribution hay ALB listener HTTPS nào để gắn web ACL vào ở giai đoạn này.

### Xử lý bằng chứng screenshot chứa secret

Trong lúc tổng hợp bằng chứng deployment cho báo cáo này, một số ít screenshot console (màn hình "Store a new secret" của Secrets Manager và màn hình "Environment variables" của Lambda) được phát hiện chứa giá trị secret thật dạng plaintext. Mỗi cái đã được redact ở mức pixel (giá trị secret bị bôi đen ngay trong dữ liệu ảnh, không phải crop hay blur, vì crop/blur có thể để lại pixel gốc khôi phục được) trước khi được cân nhắc đưa vào báo cáo này. Ghi chú ở đây để minh bạch về cách bằng chứng ở các phần Workshop sau được làm sạch, không phải khẳng định rằng mọi screenshot trong số hàng trăm cái đã chụp đều đã được rà soát lại riêng lẻ.
