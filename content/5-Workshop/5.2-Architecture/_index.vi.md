---
title: "5.2 Architecture"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2. </b> "
---

{{% notice warning %}}
`backend/gateway` là một container Node.js/Express **ở tầng ứng dụng** đi kèm trong source code Fitness Assistant — đây là reverse proxy/router nội bộ riêng của nó, **không phải** dịch vụ **Amazon API Gateway** do AWS quản lý. MVP này không sử dụng Amazon API Gateway. Xem thêm ghi chú tương tự ở [Proposal Mục 12](../../2-Proposal/#12-kiến-trúc-giải-pháp).
{{% /notice %}}

### Sơ đồ kiến trúc

![Kiến trúc AWS của Fitness Assistant — TODO: ảnh PNG này vẫn là placeholder; export từ file .drawio bên dưới](/images/workshop/architecture/fitness-assistant-aws-architecture.png)

File tải xuống: [fitness-assistant-aws-architecture.drawio](/files/architecture/fitness-assistant-aws-architecture.drawio)

{{% notice note %}}
File `.drawio` đã là sơ đồ thật (bộ icon AWS4 — EC2, RDS, Internet Gateway, ECR, IAM Role, Secrets Manager, CloudWatch, SNS — bố trí trên một VPC riêng với public/private subnet, khớp với Request/Data/Log Flow của mục này). **Chỉ còn ảnh PNG export ở trên vẫn là placeholder** — mở file `.drawio` trong draw.io, xác nhận icon hiển thị đúng, điền AWS Region thật, rồi export ra PNG trước khi nộp báo cáo. Xem `static/files/architecture/README.md` và `static/images/workshop/architecture/README.md`.
{{% /notice %}}

### AWS services sử dụng (MVP)

Amazon EC2, Amazon ECR, Amazon RDS for PostgreSQL, Amazon VPC, AWS IAM, AWS Secrets Manager, Amazon CloudWatch, Amazon SNS. Xem đầy đủ bảng kèm lý do ở [Proposal Mục 14](../../2-Proposal/#14-danh-sách-aws-services).

### Luồng request

1. Trình duyệt → reverse proxy Nginx trên EC2.
2. Tài nguyên tĩnh của frontend được phục vụ trực tiếp (ứng dụng React/Vite đã build); API call được proxy tới container `backend/gateway` (port 3000).
3. Gateway gọi endpoint `/auth/verify` của `auth-service` kèm JWT của người gọi, sau đó chuyển tiếp request xuống downstream kèm header `x-user-id` / `x-user-email` / `x-user-role`.
4. Service downstream liên quan (`user-service`, `fitness-service`, `ai-service`, `payment-service`, `gym-service`) xử lý request.

### Luồng dữ liệu

- Mỗi backend service đọc/ghi database logic riêng (`gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, `gymcoach_payment`, `gymcoach_gym`) trên cùng một instance Amazon RDS PostgreSQL, thông qua Prisma.
- `ai-service` truy vấn thêm container Qdrant để lấy ngữ cảnh RAG và gọi endpoint `/api/chat` / `/api/embeddings` của container Ollama.
- `gym-service` gọi `payment-service` cho các thao tác ví/hợp đồng; `payment-service` chạy với `PAYMENT_PROVIDER=MOCK` cho MVP này (chưa có thông tin cổng thanh toán thật).
- `user-service` gọi Anthropic Claude API bên ngoài để trích xuất ảnh InBody (cần truy cập internet outbound và secret `ANTHROPIC_API_KEY`).
- File tải lên (ảnh InBody, ảnh hồ sơ, tài liệu PT) hiện được ghi vào local disk trên EC2 qua `multer` — hiện chưa có tích hợp S3 trong source ứng dụng.

### Luồng triển khai

1. Build image Docker production ở local (hoặc trong CI trong tương lai) từ các Dockerfile multi-stage có sẵn.
2. Push image lên Amazon ECR repository theo từng service.
3. Trên EC2, pull image mới nhất và khởi động lại stack Docker Compose.
4. Chạy `prisma migrate deploy` cho từng service lên endpoint RDS khi schema thay đổi.

### Luồng log và cảnh báo

Log container/ứng dụng → CloudWatch Agent → CloudWatch Logs → CloudWatch Alarm (CPU EC2, status check EC2, CPU/connections/storage RDS) → Amazon SNS topic → email người đăng ký. Chi tiết đầy đủ ở [5.12 Monitoring and Alerting](../5.12-Monitoring-Alerting/).

### Ranh giới mạng

- **Public subnet:** EC2 duy nhất (frontend, gateway, và toàn bộ container ứng dụng), truy cập được từ internet chỉ qua port 80/443 (và SSH, giới hạn theo IP cụ thể).
- **Private subnet:** Amazon RDS for PostgreSQL, trải trên hai Availability Zone cho DB subnet group; không truy cập được từ internet.

### Tài nguyên public và private

| Tài nguyên | Vị trí | Truy cập được từ internet? |
|---|---|---|
| EC2 (frontend, gateway, các service, container Redis, Qdrant, Ollama) | Public subnet | Có, chỉ port 80/443 (SSH giới hạn) |
| Amazon RDS for PostgreSQL | Private subnet (DB subnet group) | Không |

### Luồng Security Group (tóm tắt)

Bảng ma trận đầy đủ ở [5.6 Network Infrastructure](../5.6-Network-Infrastructure/). Tóm tắt: internet chỉ được phép truy cập Security Group của EC2 qua port 80/443 (và một IP SSH giới hạn); Security Group của RDS chỉ chấp nhận port 5432 từ Security Group của EC2; không có đường truy cập inbound nào khác.

### Kiến trúc hiện tại so với tương lai

**Hiện tại (MVP):** một EC2 duy nhất chạy Docker Compose cho toàn bộ container ứng dụng, một instance Amazon RDS, ECR lưu image, CloudWatch/SNS cho khả năng quan sát.

**Tương lai:** service Amazon ECS/Fargate phía sau Application Load Balancer với Auto Scaling; Amazon CloudFront + Route 53 cho frontend; Amazon Bedrock thay thế Ollama tự host; Amazon S3 (kèm thay đổi code ứng dụng) cho file upload; Amazon ElastiCache cho Redis; CI/CD và Infrastructure as Code. Danh sách đầy đủ ở [Proposal Mục 25](../../2-Proposal/#25-hướng-phát-triển).
