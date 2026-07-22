---
title: "Tuần 1"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 1.1. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Đọc và nắm rõ quy định thực tập FCAJ (https://hcm-rules.awsfcaj.com/3-project/) và yêu cầu của template báo cáo.
- Clone và phân tích tổng quan source code [Fitness Assistant](https://github.com/trmizy/fitness-assistant) (cấu trúc thư mục, các service, README).
- Chạy thử project ở local để xác nhận chính xác những service nào thực sự tồn tại và cách chúng khởi động.
- Xác định phạm vi MVP trên AWS dựa trên những gì source code thực sự hỗ trợ, không dựa trên suy đoán.

### Công việc đã thực hiện

- Đọc quy định project FCAJ và cấu trúc template `fcj-workshop-template`.
- Clone `fitness-assistant` và xem xét các thư mục cấp cao, `README.md`, và file `docker-compose.yml` (nếu có).
- Thử chạy ứng dụng ở local theo đúng hướng dẫn của project.
- Ghi chú lại stack công nghệ thực tế (frontend framework, backend, database, cache, auth).
- Soạn danh sách sơ bộ (chưa xác nhận) các dịch vụ AWS có thể phù hợp với stack này.

### Kết quả đạt được

- Hiểu rõ cấu trúc báo cáo FCAJ và quy định nộp bài.
- Có bản kiểm kê sơ bộ cấu trúc repository Fitness Assistant.
- TODO: Xác nhận việc chạy local có thành công toàn bộ hay không và ghi lại đúng các bước đã dùng.

### Khó khăn

- Một số mô tả "microservices điển hình" tìm thấy trên mạng có thể không khớp với những gì thực sự có trong repository — cần kiểm chứng mọi thông tin trực tiếp từ source thay vì suy đoán theo mô hình chung.

### Cách giải quyết

- Đối chiếu từng thông tin về service/port/biến môi trường với các file thực tế (`package.json`, `docker-compose.yml`, `README.md`) thay vì dựa vào quy ước microservices thông thường.

### Kỹ năng / Dịch vụ AWS đã học

- Mô hình tài khoản AWS Free Tier và kiến thức IAM cơ bản.
- Tổng quan các dịch vụ AWS có khả năng liên quan đến project (EC2, ECR, RDS, S3, CloudWatch) — mới ở mức khái niệm, chưa triển khai thực tế.

### Bằng chứng cần bổ sung

- TODO: Screenshot ứng dụng chạy ở local.
- TODO: Output terminal khi build và chạy local.
- TODO: Ghi chú/ảnh chụp xác nhận đã đọc quy định FCAJ và template.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Đọc quy định project FCAJ và template báo cáo | [TODO_DATE] | [TODO_DATE] | https://hcm-rules.awsfcaj.com/3-project/ |
| 2 | Clone và xem xét cấu trúc repository `fitness-assistant` | [TODO_DATE] | [TODO_DATE] | https://github.com/trmizy/fitness-assistant |
| 3 | Chạy thử project ở local theo README của project | [TODO_DATE] | [TODO_DATE] | README của project |
| 4 | Soạn thảo phạm vi MVP ban đầu (bản nháp) | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã đọc quy định và template FCAJ
- [ ] Đã clone `fitness-assistant` và ghi lại cấu trúc
- [ ] Ứng dụng chạy được ở local kèm bằng chứng
- [ ] Đã soạn thảo phạm vi MVP ban đầu

### Liên kết Workshop tương ứng

- [5.1 Overview](../../5-Workshop/5.1-Overview/)
- [5.3 Prerequisites](../../5-Workshop/5.3-Prerequisites/)
