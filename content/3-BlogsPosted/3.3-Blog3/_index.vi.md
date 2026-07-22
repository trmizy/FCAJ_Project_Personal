---
title: "Blog 3: Giám sát với CloudWatch và SNS"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 3.3. </b> "
---

## Giám sát ứng dụng container trên EC2 bằng CloudWatch và SNS

**Trạng thái:** Draft (bản nháp)

**Ngày đăng:** [TODO_DATE]

**URL bài viết:** [TODO_BLOG_URL]

**Ảnh bìa:** TODO screenshot — chưa chụp.

### Mục tiêu

Giải thích cách bổ sung khả năng quan sát cơ bản cho phần triển khai Fitness Assistant trên EC2: gửi log container tới Amazon CloudWatch Logs, cảnh báo dựa trên metric EC2/RDS, và thông báo qua email bằng Amazon SNS.

### Tóm tắt

Mặc định, EC2 chỉ báo cáo CPU, network và metric status-check cơ bản — không có thông tin về memory hay dung lượng đĩa, và không có log ứng dụng. Bài viết này trình bày cách cài đặt CloudWatch Agent để thu thập thêm metric cấp host và chuyển tiếp log container, xây dựng một CloudWatch Dashboard nhỏ, tạo alarm cho CPU và status check của EC2 cùng CPU/connections/storage của RDS, và gắn các alarm đó với một SNS topic có subscription email.

### Nội dung chính

- Cài đặt và cấu hình CloudWatch Agent (`cloudwatch-agent-config.example.json`) trên EC2.
- Tạo CloudWatch Log Group với retention period tường minh, để tránh chi phí lưu log không giới hạn.
- Tạo CloudWatch Alarm cho mức sử dụng CPU EC2, lỗi status check EC2, và CPU/connections/storage của RDS.
- Tạo SNS topic, đăng ký một địa chỉ email, và xác nhận subscription.
- Kiểm tra toàn bộ chuỗi: **Metric → Alarm → SNS → Email**.
- TODO: Bổ sung screenshot dashboard thật, screenshot alarm đã kích hoạt, và screenshot email thông báo đã nhận được.

### Kiến thức đã học

- Khoảng cách giữa "EC2 trông ổn trên console" và "ứng dụng bên trong container thực sự khỏe mạnh" — log và metric cấp ứng dụng quan trọng không kém metric hạ tầng.
- Cách kiểm tra toàn bộ pipeline cảnh báo đầu-cuối thay vì giả định nó hoạt động ngay khi cấu hình xong.

{{% notice warning %}}
Không đánh dấu pipeline này là "hoạt động" trong bài đăng chính thức cho đến khi một alarm thật sự kích hoạt và một email thông báo thật sự được nhận và ghi lại làm bằng chứng.
{{% /notice %}}
