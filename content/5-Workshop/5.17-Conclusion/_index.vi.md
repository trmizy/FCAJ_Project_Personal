---
title: "5.17 Conclusion"
date: 2026-07-15
weight: 17
chapter: false
pre: " <b> 5.17. </b> "
---

### Kết quả đạt được

TODO: điền trung thực sau khi việc triển khai thực tế được thực hiện. Không tóm tắt mục này cho đến khi mọi bước Workshop được tham chiếu đều có bằng chứng thật. Cấu trúc gợi ý để điền:

- Những service nào thuộc MVP thực sự đã được triển khai và xác minh đầu-cuối.
- Những test case nào ở [5.13 Testing and Validation](../5.13-Testing-Validation/) thực sự đã pass.
- Những chuỗi giám sát/cảnh báo nào thực sự đã được xác nhận hoạt động.

### So sánh trước và sau khi chuyển lên AWS

| Khía cạnh | Trước (Docker Compose local) | Sau (MVP trên AWS) |
|---|---|---|
| Database | Một container `postgres` duy nhất, không backup | Amazon RDS, automated backup, mạng private — TODO xác nhận |
| Phân phối image | Chỉ `docker build` ở local | Amazon ECR, image có phiên bản — TODO xác nhận |
| Secret | File `.env` ở thư mục gốc | AWS Secrets Manager — TODO xác nhận |
| Khả năng quan sát | Chỉ `docker compose logs` | CloudWatch Logs/Alarms + SNS — TODO xác nhận |
| Tính sẵn sàng | Một máy duy nhất, restart thủ công | Một EC2 duy nhất — vẫn là điểm lỗi đơn đã biết, chưa được giải quyết |

### Kiến thức đã học

- Đọc một codebase có sẵn, không đơn giản, đủ cẩn thận để mô tả chính xác kiến trúc thực sự của nó, thay vì giả định theo mô hình chung.
- Sự khác biệt thực tế giữa một container gateway ở tầng ứng dụng và một dịch vụ AWS managed có tên tương tự (Amazon API Gateway).
- Kiến thức nền tảng thiết kế VPC/subnet/Security Group, áp dụng cho một ứng dụng nhiều service thực tế.
- Di chuyển mô hình database-per-service từ một container Docker duy nhất sang một instance RDS managed dùng chung.
- Khả năng quan sát AWS cơ bản: CloudWatch Logs/Metrics/Alarms và chuỗi thông báo SNS.
- Thiết kế IAM policy least-privilege trong thực tế, không chỉ trên lý thuyết.

### Khó khăn

TODO: liệt kê những khó khăn thực sự gặp phải trong quá trình triển khai thực tế (kỹ thuật và phi kỹ thuật). Xem [Worklog](../../1-Worklog/) để biết khó khăn đã được ghi lại theo từng tuần.

### Cách xử lý

TODO: tóm tắt cách giải quyết cho từng khó khăn ở trên, tham chiếu tới đúng tuần Worklog liên quan.

### Hạn chế

- Một EC2 duy nhất: không có redundancy, không có Auto Scaling.
- `gym-service`, `payment-service`, `chat-service` không thuộc phạm vi triển khai này.
- Amazon S3 chưa được tích hợp — file upload vẫn nằm trên local disk.
- TLS/HTTPS chưa được cấu hình cho frontend.
- Chưa tự động hóa xoay vòng secret.
- Chưa có pipeline CI/CD; các bước triển khai vẫn thủ công.

### Đóng góp cá nhân

TODO: mô tả cụ thể những gì đã tự thực hiện so với những gì có sự hướng dẫn (từ mentor, tài liệu có sẵn, công cụ hỗ trợ AI, v.v.). Cần chính xác và trung thực — những khẳng định mơ hồ ("tôi đã làm tất cả") không phải bằng chứng hữu ích cho việc đánh giá.

### Hướng phát triển

- Amazon ECS/Fargate kèm Application Load Balancer và Auto Scaling, thay thế cho một EC2 duy nhất.
- Amazon CloudFront và Amazon Route 53 cho CDN và domain tùy chỉnh.
- Amazon Bedrock như lựa chọn managed thay thế hoặc bổ sung cho Ollama tự host.
- Amazon S3 (kèm thay đổi code thực sự trong `user-service`) thay thế lưu trữ local disk.
- Amazon ElastiCache for Redis, thay thế container Redis.
- Pipeline CI/CD (GitHub Actions) để tự động hóa build, test và deploy.
- Infrastructure as Code (Terraform hoặc AWS CDK) thay vì thao tác thủ công trên console/CLI.
- RDS Multi-AZ để tăng tính sẵn sàng.
- Dockerfile production và triển khai cho `gym-service`, `payment-service`, và `chat-service`.

{{% notice warning %}}
**Lưu ý về sức khỏe:** Các tính năng huấn luyện AI và dinh dưỡng của Fitness Assistant (chat RAG dựa trên Ollama, bộ tính toán tất định) chỉ cung cấp thông tin và gợi ý thể hình mang tính tổng quát. Chúng không chẩn đoán tình trạng y tế, và việc triển khai này không làm thay đổi điều đó. Fitness Assistant không thay thế cho tư vấn của bác sĩ có chuyên môn, chuyên gia dinh dưỡng, hoặc huấn luyện viên thể hình được chứng nhận — điều này áp dụng cho cả tính năng huấn luyện AI lẫn tính năng trích xuất ảnh InBody riêng biệt dựa trên Anthropic Claude Vision, vốn chỉ đọc các giá trị số từ ảnh chứ không cấu thành một diễn giải y tế.
{{% /notice %}}

### Reflection cá nhân

TODO: viết một reflection thật, ở góc nhìn cá nhân, sau khi hoàn thành đợt thực tập — điều gì khiến bạn bất ngờ, bạn sẽ làm khác đi điều gì, trải nghiệm này đã thay đổi cách bạn nghĩ về triển khai cloud như thế nào.
