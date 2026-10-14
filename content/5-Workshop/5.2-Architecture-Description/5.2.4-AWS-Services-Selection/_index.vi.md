---
title: "5.2.4 Dịch vụ AWS và lý do lựa chọn"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.2.4. </b> "
---

| Dịch vụ AWS | Dùng cho | Vì sao chọn cái này, không phải phương án khác |
|---|---|---|
| **AWS Lambda** | Auth, User, Fitness, Gym, Payment, AI (HTTP + Worker + Jobs) — tổng 10 function | Sáu trong tám service là request/response ngắn hoặc công việc theo lịch, không cần giữ kết nối mở. Lambda scale về 0 giữa các request, quan trọng với môi trường DEV phần lớn thời gian idle, và loại bỏ vấn đề sizing instance mà project này đã từng gặp một lần với container Ollama self-host trên EC2 (xem [Tuần 8](../../../1-Worklog/1.8-Week8/)). |
| **Amazon ECS trên Fargate** | Chat Service (REST + Socket.IO) | Service duy nhất thực sự không dùng Lambda được: Socket.IO giữ một kết nối sống theo từng phiên, không khớp với model billing/execution theo từng lần gọi của Lambda. Fargate được chọn thay vì tự quản lý EC2+ECS để không phải vá hay sizing server ngoài CPU/RAM của task (dev sizing: 0.5 vCPU / 1 GB). |
| **Amazon API Gateway (HTTP API)** | Một điểm vào duy nhất cho sáu service chạy trên Lambda | Một lớp routing đứng trước mọi Lambda ở luồng request, thay vì mỗi service có endpoint công khai riêng. HTTP API (không phải REST API) đủ cho nhu cầu routing của project này với chi phí thấp hơn. |
| **Application Load Balancer** | Cửa ngõ cho Chat Fargate task | API Gateway không proxy WebSocket upgrade theo cách project này cần; ALB thì có, và đây là cách ghép chuẩn cho một service ECS/Fargate. |
| **Amazon Aurora PostgreSQL (Serverless v2)** | Một cluster dùng chung, một logical database cho mỗi service | Một cluster Postgres managed, tự scale, loại bỏ việc capacity planning thủ công của một RDS instance tự quản lý. Khả năng scale xuống một ACU floor thấp của Serverless v2 (hiện tại 0.5 ACU, xem [5.2.7](../5.2.7-Cost-Optimization-Cleanup/)) quan trọng đặc biệt vì đây là môi trường DEV phần lớn thời gian idle. Một cluster với bảy logical database (thay vì bảy cluster) giữ chi phí và bề mặt vận hành thấp trong khi mỗi service vẫn có schema và `DATABASE_SECRET_ID` riêng. |
| **Amazon Bedrock** | AI coaching chat/vision (Nova Pro) và embeddings cho retrieval (Cohere multilingual) | Thay thế cặp Ollama + Qdrant self-host trước đây (xem [Tuần 8](../../../1-Worklog/1.8-Week8/)) khi chi phí vận hành của việc sizing và chạy LLM trên EC2 vượt quá khoản tiết kiệm từ self-host. Bedrock được gọi như một AWS API call thông thường từ trong VPC qua NAT Gateway, không cần hạ tầng hosting model riêng. |
| **Amazon S3** | Host frontend tĩnh; một bucket riêng cho artifact database migration | Frontend là một static build không cần server-side rendering, nên S3 website hosting là cách host đơn giản nhất. Bucket migration cố ý tách riêng khỏi bucket frontend và bất kỳ bucket upload người dùng nào, để một dump migration không bao giờ truy cập được qua đường dẫn dành cho asset frontend công khai. |
| **Amazon EventBridge + Amazon SQS** | Job theo lịch (reconciliation, reminder) và queue việc AI bất đồng bộ | Tách công việc chậm/theo lịch khỏi luồng request đồng bộ, để một API call user-facing không bao giờ phải chờ một job reconciliation hay một AI completion dài. EventBridge Scheduler xử lý trường hợp "chạy định kỳ" cho từng service; SQS xử lý trường hợp "xếp hàng cho worker" cho job AI. |
| **AWS Secrets Manager** | Mọi credential database, cộng internal-service secret dùng chung và secret ký QR check-in của Gym | Tập trung lưu credential để không environment variable nào của Lambda chứa password thô — mỗi Lambda chỉ giữ một secret *ID* (`DATABASE_SECRET_ID`) và resolve giá trị lúc runtime. |
| **AWS IAM** | Một execution role cho mỗi Lambda, scope đúng những secret và cross-service invoke mà Lambda đó thực sự cần | Least-privilege theo từng service, không phải một role dùng chung "làm được mọi thứ" — xem [5.2.5](../5.2.5-Security-IAM/). |
| **Amazon VPC, NAT Gateway, Internet Gateway** | Cô lập network cho Lambda và Aurora; đường ra internet chỉ outbound cho Lambda | Lambda và Aurora nằm trong private subnet không có route internet inbound; NAT Gateway tồn tại thuần để Lambda gọi được ra các AWS API outbound (Bedrock, Secrets Manager) và API Gateway. DB subnet không có route NAT/internet nào cả. |
| **Amazon CloudWatch** | Log cho mọi Lambda và Fargate task | Đích log mặc định, không cần setup gì thêm cho cả hai loại compute dùng trong project này; dùng để troubleshoot lúc deploy chứ chưa dùng để alert (chưa cấu hình alarm nào — xem [5.2.6](../5.2.6-Scalability-Operations/)). |

### Cố ý chưa dùng (chưa phải bây giờ)

- **Amazon CloudFront** — lên kế hoạch dùng khi frontend không còn chạy trực tiếp qua S3 website endpoint nữa, để bucket chuyển về private phía sau Origin Access Control. Chưa dùng được trong môi trường này.
- **AWS WAF** — hiện chưa có component public-facing nào đứng sau một CloudFront distribution hay một ALB internet-facing dùng HTTPS, nên chưa có gì để gắn web ACL của WAF vào.
- **CI/CD (CodePipeline/CodeBuild, hoặc tương đương bên thứ ba)** — mọi deployment cho tới giờ đều là thao tác thủ công qua console/CLI, ghi lại đúng lúc thực hiện. Theo dõi là khoảng trống lớn nhất còn lại trong [5.1 Overview](../../5.1-Overview/).
