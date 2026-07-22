---
title: "Tuần 6"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 1.6. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Khởi tạo Amazon RDS for PostgreSQL để thay thế container `postgres:15-alpine` dùng khi phát triển local.
- Chạy migration Prisma lên RDS cho từng service sở hữu database riêng.
- Xác minh kết nối chỉ từ tầng ứng dụng (private access).

### Công việc đã thực hiện

- Tạo DB subnet group trên hai private subnet từ Tuần 5.
- Khởi tạo RDS PostgreSQL với **public access bị tắt**, bật encryption at rest, và cấu hình automated backup.
- Gắn Security Group cho RDS sao cho port 5432 chỉ được phép truy cập từ Security Group của EC2 chạy ứng dụng, đúng theo mô hình database-per-service thực tế mà `fitness-assistant` sử dụng (mỗi service — auth, user, fitness, ai, chat — có database logic và schema/migration Prisma riêng).
- Chạy `prisma migrate deploy` cho từng service lên endpoint RDS mới, sử dụng đúng schema Prisma của project (không viết SQL DDL thủ công).
- Chạy script seed data của project (nếu có) để nạp dữ liệu cơ bản.
- Xác minh kết nối từ một EC2 trong cùng VPC (không phải từ máy cá nhân qua internet công cộng, vì RDS là private).

### Kết quả đạt được

- Đã áp dụng migration cho các service thuộc phạm vi MVP.
- TODO: Xác nhận danh sách database cuối cùng đã tạo (`gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, và các database khác trong phạm vi MVP) và ghi lại bằng chứng.

### Khó khăn

- Dockerfile production của `user-service` không tự động chạy `prisma migrate deploy` khi khởi động (khác với `auth-service` và `ai-service`), nên migration cho service này cần được kích hoạt tường minh thay vì giả định container tự chạy.

### Cách giải quyết

- Ghi chú rõ sự không nhất quán này ở [Workshop 5.7](../../5-Workshop/5.7-RDS-PostgreSQL/) và chạy migration của `user-service` như một bước thủ công/tường minh thay vì giả định container tự xử lý.

### Kỹ năng / Dịch vụ AWS đã học

- Khởi tạo Amazon RDS, DB subnet group, automated backup, encryption at rest.
- Chạy migration Prisma trên database managed thay vì container local.

### Bằng chứng cần bổ sung

- TODO: Screenshot cấu hình RDS instance (đã che thông tin đăng nhập).
- TODO: Output terminal chạy `prisma migrate deploy` thành công theo từng service.
- TODO: Screenshot/log kiểm tra kết nối thành công từ EC2.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Tạo DB subnet group và RDS instance | [TODO_DATE] | [TODO_DATE] | [Workshop 5.7](../../5-Workshop/5.7-RDS-PostgreSQL/) |
| 2 | Cấu hình Security Group chỉ cho phép truy cập private | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 3 | Chạy migration Prisma theo từng service | [TODO_DATE] | [TODO_DATE] | `prisma/schema.prisma` từng service |
| 4 | Xác minh kết nối và seed dữ liệu | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã tạo RDS PostgreSQL (chỉ cho phép truy cập private)
- [ ] Đã cấu hình DB subnet group và Security Group
- [ ] Đã áp dụng migration Prisma theo từng service
- [ ] Đã xác minh kết nối từ EC2, không phải từ internet công cộng

### Liên kết Workshop tương ứng

- [5.7 RDS PostgreSQL](../../5-Workshop/5.7-RDS-PostgreSQL/)
