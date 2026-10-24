---
title: "5.4 Hướng dẫn triển khai"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.4. </b> "
---

Các service được triển khai lần lượt theo thứ tự phụ thuộc: một service chỉ được đưa lên khi mọi service mà nó gọi đã chạy. Các trang dưới đây đi theo đúng thứ tự đó và giữ lại screenshot chụp trong quá trình triển khai thật.

1. [5.4.1 Hạ tầng mạng dùng chung](5.4.1-Shared-Network/) — Internet Gateway, public subnet, NAT Gateway và route table.
2. [5.4.2 Auth Service và API Gateway](5.4.2-Auth-Service-API-Gateway/) — Lambda đầu tiên, HTTP API và các route public tường minh.
3. [5.4.3 Frontend trên Amazon S3](5.4.3-Frontend-S3/) — static website hosting và quy trình deploy lại.
4. [5.4.4 User Service](5.4.4-User-Service/) — gọi Lambda-tới-Lambda, upload S3 private và các scheduled job đầu tiên.
5. [5.4.5 Fitness Service](5.4.5-Fitness-Service/) — migration từ artifact trên S3 và hai schedule nhắc lịch.
6. [5.4.6 Gym Service](5.4.6-Gym-Service/) — secret cho QR check-in và job payout/referral.
7. [5.4.7 Payment Service](5.4.7-Payment-Service/) — cấu hình VNPAY, reconciliation và nối Gym ↔ Payment.
8. [5.4.8 AI Service — database, queue và Bedrock](5.4.8-AI-Service-Core/) — HTTP Lambda, SQS worker và jobs Lambda trên Nova Pro / Cohere.
9. [5.4.9 AI Service — vector search, lịch chạy và API](5.4.9-AI-Service-Vector-Search/) — OpenSearch Serverless, nạp tri thức, route và rate limit.
10. [5.4.10 Chat Service trên ECS Fargate](5.4.10-Chat-Service-ECS/) — container image, task definition, ALB và Socket.IO.
11. [5.4.11 Migration dữ liệu lên Aurora](5.4.11-Data-Migration/) — restore 7 database local bằng một Fargate task chạy một lần.
12. [5.4.12 Kích hoạt pipeline CI/CD](5.4.12-CICD-Pipeline/) — validate PR bằng GitHub Actions qua OIDC, cùng bằng chứng liên kết OIDC → STS thật.
13. [5.4.13 Kích hoạt pipeline CD](5.4.13-CD-Pipeline-Activation/) — kích hoạt từng gate một các workflow deploy thật lên AWS, bắt đầu từ cổng duyệt-bởi-con-người ở GitHub Environment.
14. [5.4.14 CloudFront, Aurora reader và CloudWatch alarm](5.4.14-Edge-Database-Monitoring/) — cửa vào HTTPS, reader của database và một alarm có thông báo email, mỗi phần kèm form tạo.
15. [5.4.15 Hạ tầng dưới dạng code với CloudFormation](5.4.15-CloudFormation-IaC/) — các stack, file template để tải và cách deploy một stack.
16. [5.4.16 Workflow GitHub Actions](5.4.16-GitHub-Actions-Workflows/) — sáu workflow kèm file để tải, các cổng phê duyệt và cách chạy.

#### Khuôn mẫu chung cho mọi service chạy trên Lambda {#common-pattern}

Khi hạ tầng mạng dùng chung đã có, mỗi service (Auth, User, Fitness, Gym, Payment, AI) được triển khai theo cùng một trình tự. Các trang service chỉ nêu những điểm khác biệt.

| # | Bước | Chi tiết |
|---|---|---|
| 1 | Database secret | Secrets Manager → *Other type of secret* với `username`, `password`, `host`, `port`, `database = fitness_assistant_<service>`, đặt tên `fitness-assistant/dev/<service>-database`. Tắt rotation cho DEV. |
| 2 | Migration role | IAM role trust Lambda với `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole`, cộng inline policy cho phép `secretsmanager:GetSecretValue` **chỉ** trên ARN secret của service đó. |
| 3 | Migration Lambda | `fitness-assistant-dev-<service>-migrate`, Node.js 22.x, x86_64, 1024 MB, handler `dist/migrate-lambda.handler`, env `DATABASE_SECRET_ID`, gắn vào hai private app subnet và `fitness-assistant-dev-lambda-sg`. Invoke một lần với `{}`: tạo logical database nếu chưa có và chạy `prisma migrate deploy`, từ chối chạy trên bất kỳ tên database nào khác. |
| 4 | Runtime role | Cùng hai managed policy, cộng inline policy cho secret của service và `lambda:InvokeFunction` trên đúng các function mà nó gọi. |
| 5 | HTTP Lambda | `fitness-assistant-dev-<service>`, 1024 MB, timeout 30 giây, handler `dist/lambda.handler`, cấu hình VPC như trên. |
| 6 | API Gateway | Lambda integration (payload format 2.0) và các route prefix tường minh. **Không bao giờ** tạo `/internal/*` hay `ANY /{proxy+}`. |
| 7 | Jobs Lambda | `fitness-assistant-dev-<service>-jobs`, cùng ZIP, handler `dist/jobs-lambda.handler`, timeout 1 phút. |
| 8 | Scheduler | Một role riêng trust `scheduler.amazonaws.com`, chỉ được invoke đúng jobs Lambda đó, và mỗi job một schedule EventBridge với payload `{"job": "<name>"}`. |

{{% notice info %}}
Mọi screenshot trong các trang này lấy từ runbook triển khai. Những màn hình ban đầu có hiện giá trị secret (mật khẩu master của database, `INTERNAL_SERVICE_SECRET`, `CHECKIN_TOKEN_SECRET`) đã được che ở mức pixel trước khi đưa vào — các ô đen là có chủ đích.
{{% /notice %}}
