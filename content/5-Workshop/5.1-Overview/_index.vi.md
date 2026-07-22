---
title: "5.1 Overview"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.1. </b> "
---

### Bài toán

Fitness Assistant là một ứng dụng mã nguồn mở có thật, đang được phát triển tích cực, nhưng chỉ được xây dựng và kiểm thử cho phát triển local qua Docker Compose. Repository nguồn chưa có bất kỳ triển khai AWS, pipeline CI/CD, hay hạ tầng cloud nào. Workshop này giải quyết khoảng trống đó cho một tập con MVP của ứng dụng.

### Người dùng mục tiêu

- Người dùng cuối của ứng dụng thể hình (theo dõi luyện tập, mục tiêu, nhận gợi ý huấn luyện từ AI).
- Mentor/người đánh giá FCAJ xem xét kết quả thực hiện của đợt thực tập.

### Chức năng ứng dụng (đã xác minh trong source)

- Đăng ký và đăng nhập người dùng (`auth-service`, dựa trên JWT).
- Quản lý hồ sơ, bao gồm tải lên bản ghi chỉ số cơ thể InBody với trích xuất hỗ trợ bởi AI (`user-service`).
- Danh mục bài tập, lịch tập, và ghi log tập luyện (`fitness-service`).
- Huấn luyện hỗ trợ AI: một LLM tự host (Ollama, `llama3.2:3b`) kết hợp pipeline Retrieval-Augmented Generation (RAG) dựa trên Qdrant (`ai-service`).
- Chat thời gian thực (`chat-service`), quản lý phòng gym (`gym-service`) và thanh toán (`gym-service`/`payment-service`) cũng tồn tại trong source nhưng **không** thuộc phạm vi MVP này (xem bên dưới).

{{% notice note %}}
Tính năng huấn luyện AI là một hệ thống RAG dựa trên LLM thực sự (Ollama + Qdrant), không phải một recommendation engine thuần rule-based — dù vẫn có các lớp bảo vệ tất định (bộ tính toán dinh dưỡng, kiểm tra an toàn) chạy song song với LLM. Tính năng trích xuất ảnh InBody riêng biệt gọi Anthropic Claude API, là một tích hợp khác với chat huấn luyện dựa trên Ollama. Cả hai tính năng này đều không thay thế cho tư vấn y tế — xem thêm ở [5.17 Conclusion](../5.17-Conclusion/).
{{% /notice %}}

### Kết quả mong muốn

Một MVP hoạt động, truy cập được qua internet, dữ liệu lưu trên Amazon RDS, image container trên Amazon ECR, chạy trên Amazon EC2, có giám sát và cảnh báo cơ bản — được ghi chép từng bước kèm bằng chứng, không phải giả định.

### Phạm vi MVP

Xem đầy đủ ở [Proposal Mục 8](../../2-Proposal/#8-phạm-vi-mvp). Tóm tắt: frontend, application gateway, auth-service, user-service, fitness-service, ai-service (với Ollama và Qdrant dưới dạng container), và PostgreSQL được di chuyển sang Amazon RDS.

### Thành phần loại khỏi MVP

- `chat-service`, `gym-service`, `payment-service` (hai service sau hiện chưa có Dockerfile production trong source).
- Amazon S3 (file upload vẫn lưu trên local disk cho MVP — hiện chưa có S3 client trong source ứng dụng).
- Amazon ElastiCache, Amazon Bedrock, Amazon CloudFront, Amazon Route 53, Application Load Balancer, Auto Scaling, CI/CD, và Infrastructure as Code — tất cả được liệt kê ở phần Optional/Future trong [Proposal](../../2-Proposal/#25-hướng-phát-triển).

### Danh sách deliverables

- Workshop này với các bước đã ghi chép, có thể tái hiện.
- File Dockerfile production mẫu cho các service thuộc MVP.
- File `docker-compose.aws.example.yml` mô tả triển khai trên EC2.
- Sơ đồ kiến trúc (file draw.io nguồn + ảnh PNG export) — TODO, chờ triển khai thực tế hoàn tất.
- Ví dụ IAM policy và Security Group.
- Bảng test case kèm trạng thái bằng chứng.

### Tiêu chí hoàn thành

- Mọi dịch vụ AWS được ghi là "Implemented" ở bất kỳ đâu trong báo cáo này đều có screenshot, trích đoạn log, hoặc output lệnh tương ứng trong Workshop này.
- Không bước nào ở đây khẳng định thành công mà không có mục Bằng chứng tương ứng, kể cả khi mục đó hiện đang ghi `TODO`.
