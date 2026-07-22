---
title: "5.7 RDS PostgreSQL"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.7. </b> "
---

### Vì sao RDS thay thế container `postgres`

`infra/compose/docker-compose.dev.yml` chạy một container `postgres:15-alpine` duy nhất cho phát triển local, mỗi backend service (`auth-service`, `user-service`, `fitness-service`, `ai-service`, `chat-service`, `gym-service`, `payment-service`) trỏ `DATABASE_URL` riêng tới một database logic khác nhau trên cùng instance đó (database-per-service). Amazon RDS for PostgreSQL tái hiện đúng bố cục này trên một instance managed, có backup, thay vì một container local dùng-rồi-bỏ.

### Tạo DB Subnet Group

Dùng hai private subnet từ [5.6 Network Infrastructure](../5.6-Network-Infrastructure/).

```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name fitness-assistant-db-subnet-group \
  --db-subnet-group-description "Private subnets for Fitness Assistant RDS" \
  --subnet-ids subnet-xxxxxxxx subnet-yyyyyyyy
```

### Tạo RDS instance (chỉ private access)

```bash
aws rds create-db-instance \
  --db-instance-identifier fitness-assistant-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15 \
  --master-username [TODO_DATABASE_USER] \
  --master-user-password "DUNG_SECRETS_MANAGER_KHONG_DAN_PASSWORD_THAT" \
  --allocated-storage 20 \
  --db-subnet-group-name fitness-assistant-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxx \
  --no-publicly-accessible \
  --backup-retention-period 7 \
  --storage-encrypted
```

Các thiết lập quan trọng, khớp với [Proposal](../../2-Proposal/#16-bảo-mật): tắt public access, bật encryption at rest, và backup retention period tường minh.

### Security Group

Gắn Security Group của RDS sao cho port 5432 chỉ chấp nhận traffic từ Security Group ứng dụng của EC2, theo [5.6 Network Infrastructure](../5.6-Network-Infrastructure/).

### Credentials

Không bao giờ hard-code master password. Lưu trong AWS Secrets Manager (xem [5.11 IAM and Secrets](../5.11-IAM-Secrets/)) và tham chiếu bằng `[TODO_RDS_ENDPOINT]`, `[TODO_DATABASE_NAME]`, `[TODO_DATABASE_USER]` trong bất kỳ tài liệu chia sẻ nào.

### Tạo database theo từng service

Mỗi backend service cần một database logic riêng trên instance, khớp với phát triển local:

```sql
CREATE DATABASE gymcoach_auth;
CREATE DATABASE gymcoach_user;
CREATE DATABASE gymcoach_fitness;
CREATE DATABASE gymcoach_ai;
-- Chỉ tạo database cho các service thuộc phạm vi MVP.
```

### Chạy migration Prisma

Mỗi service thuộc MVP đã có sẵn `prisma/schema.prisma` và thư mục `prisma/migrations/` riêng — dùng đúng công cụ migration của project, không viết SQL DDL thủ công:

```bash
DATABASE_URL="postgresql://TODO_DATABASE_USER:PASSWORD@TODO_RDS_ENDPOINT:5432/gymcoach_auth" \
  pnpm --filter @gym-coach/auth-service exec prisma migrate deploy
```

{{% notice warning %}}
Dockerfile production của `user-service` không tự động chạy `prisma migrate deploy` khi container khởi động, khác với `auth-service` và `ai-service`. Chạy migration của nó như một bước riêng, tường minh; không giả định nó tự xảy ra chỉ vì container đang chạy.
{{% /notice %}}

### Seed data

Nếu dùng script seed của project (`pnpm db:seed` hoặc service `db-seeder` định nghĩa trong `docker-compose.dev.yml`), trỏ chúng tới endpoint RDS theo cách tương tự. TODO: xác nhận script seed nào phù hợp để chạy trên instance RDS dùng chung/demo so với chỉ dùng cho local.

### Kiểm tra kết nối

Chỉ kết nối từ một EC2 instance trong cùng VPC, không bao giờ từ máy cá nhân qua internet công cộng (RDS đã tắt public access):

```bash
psql "host=TODO_RDS_ENDPOINT port=5432 dbname=gymcoach_auth user=TODO_DATABASE_USER"
```

### Troubleshooting

Xem các dòng liên quan đến RDS ở [5.15 Troubleshooting](../5.15-Troubleshooting/) (connection timeout, password authentication failed, lỗi migration Prisma).

### Kết quả mong đợi

- RDS instance ở trạng thái `available` với public access đã tắt.
- Migration Prisma của từng service thuộc MVP áp dụng thành công lên đúng database của nó.
- Container ứng dụng trên EC2 kết nối được; máy cá nhân ngoài VPC thì không.
