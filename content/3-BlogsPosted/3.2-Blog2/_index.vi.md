---
title: "Blog 2: Chuyển PostgreSQL sang Amazon RDS"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 3.2. </b> "
---

## Chuyển PostgreSQL từ Docker sang Amazon RDS

**Trạng thái:** Draft (bản nháp)

**Ngày đăng:** [TODO_DATE]

**URL bài viết:** [TODO_BLOG_URL]

**Ảnh bìa:** TODO screenshot — chưa chụp.

### Mục tiêu

Ghi lại quá trình chuyển từ một container Docker `postgres:15-alpine` duy nhất (được toàn bộ backend service dùng khi phát triển local) sang Amazon RDS for PostgreSQL, đồng thời giữ nguyên thiết kế **database-per-service** sẵn có của ứng dụng (mỗi trong bảy backend service có database logic và schema/migration Prisma riêng).

### Tóm tắt

`fitness-assistant` đã mô hình hóa dữ liệu bằng Prisma, mỗi service có một `schema.prisma` và một thư mục `migrations/` riêng, tất cả trỏ tới các database khác nhau trên cùng một instance Postgres khi phát triển local (`gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, v.v.). Bài viết này giải thích cách tái hiện đúng bố cục nhiều database đó trên một instance Amazon RDS private duy nhất, và cách chạy `prisma migrate deploy` cho từng service lên đó.

### Nội dung chính

- Tạo DB subnet group trên hai private subnet và khởi tạo RDS instance với public access bị tắt.
- Tạo mỗi database logic cho từng service thuộc MVP trên instance RDS.
- Chạy `prisma migrate deploy` cho từng service lên endpoint RDS, và lưu ý rằng Dockerfile production của `user-service` **không** tự động chạy bước này khi container khởi động (khác với `auth-service`/`ai-service`), nên phải chạy như một bước tường minh riêng.
- Xác minh kết nối chỉ từ bên trong VPC, không bao giờ mở RDS ra internet công cộng.
- TODO: Bổ sung output lệnh migration thật và screenshot kiểm tra kết nối đã được che thông tin nhạy cảm.

### Kiến thức đã học

- Cách giữ nguyên thiết kế "database-per-service" khi chuyển từ một container Docker duy nhất sang một instance RDS managed duy nhất chứa nhiều database.
- Vì sao cần kiểm tra dòng `CMD` của Dockerfile production theo từng service thay vì giả định tất cả hành xử giống nhau.

{{% notice warning %}}
Không bao giờ đăng endpoint RDS thật, username hay password master trong bài viết này. Dùng placeholder `[TODO_RDS_ENDPOINT]`, `[TODO_DATABASE_NAME]`, `[TODO_DATABASE_USER]` cho đến khi credential được che chắn an toàn cho độc giả công khai.
{{% /notice %}}
