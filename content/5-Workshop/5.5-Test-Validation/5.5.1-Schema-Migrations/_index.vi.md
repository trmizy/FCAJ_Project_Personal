---
title: "5.5.1 Schema migration"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.5.1. </b> "
---

#### Kiểm tra gì

Mỗi service sở hữu một logical database trên cluster Aurora dùng chung, được tạo và migrate bằng migration Lambda của chính nó. Một lần chạy migration chỉ pass khi response có đủ:

- `"status": "ok"` và đúng tên `database` mong đợi (handler từ chối mọi tên khác);
- `"migrateExitCode": 0`;
- `All migrations have been successfully applied.` trong output của Prisma.

#### Kết quả

| Service | Logical database | Migration | Bằng chứng |
|---|---|---|---|
| Auth | `fitness_assistant` | 7 | Kết quả test bên dưới; migration Lambda tạm đã được xoá sau đó |
| User | `fitness_assistant_user` | đã áp dụng | Migration Lambda `fitness-assistant-dev-user-migrate` ([5.4.4](../../5.4-Deployment-Guide/5.4.4-User-Service/)) |
| Fitness | `fitness_assistant_fitness` | 48 | Chạy từ artifact trên S3, sau đó migration Lambda được xoá ([5.4.5](../../5.4-Deployment-Guide/5.4.5-Fitness-Service/)) |
| Gym | `fitness_assistant_gym` | 9 | `fitness-assistant-dev-gym-migrate` (có trong danh sách function ở [5.4.10](../../5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)) |
| Payment | `fitness_assistant_payment` | 11 | Kết quả test bên dưới |
| AI | `fitness_assistant_ai` | 22 (không có `DROP` / `TRUNCATE`) | Kết quả test bên dưới |
| Chat | `fitness_assistant_chat` | 3 | Kết quả test bên dưới |

**Auth**

![Kết quả migration của Auth](/images/workshop/runbook/img001.jpg)

![Auth: migration áp dụng thành công](/images/workshop/runbook/img002.jpg)

**Payment**

![Migration Payment: status ok, fitness_assistant_payment, migration đã áp dụng](/images/workshop/runbook/img132.jpg)

**AI**

![Migration AI: databaseCreated true, migrateExitCode 0](/images/workshop/runbook/img158.jpg)

**Chat**

![Migration Chat: đã tạo database, áp dụng 3 migration](/images/workshop/runbook/img262.jpg)

#### Restore dữ liệu

Dữ liệu của 7 database local được restore bằng Fargate task chạy một lần ở [5.4.11](../../5.4-Deployment-Guide/5.4.11-Data-Migration/). Tiêu chí pass và kết quả ghi nhận:

| Kiểm tra | Mong đợi | Kết quả |
|---|---|---|
| Log preflight | `=== DB MIGRATOR PREFLIGHT OK ===`, mọi dump đọc được, đủ 7 database | Pass trước khi chạy restore |
| Log restore | `=== DONE fitness_assistant_ai ===` rồi `=== FULL RESTORE OK ===` | 7 trên 7 database đã restore |
| Toàn vẹn tham chiếu | Mọi foreign key đã audit được áp dụng và hợp lệ | 23 trên 23 foreign key đã xác nhận |
| Row count / primary key | Cùng số dòng với nguồn local theo từng bảng | Thuộc phần xác nhận restore; lặp lại sau mỗi lần chạy lại |

{{% notice tip %}}
Cách nhanh để kiểm tra lại một database sau khi restore, từ bất kỳ container hay Lambda nào truy cập được Aurora: chạy `select count(*) from <table>;` cho các bảng lớn nhất, rồi so với cùng câu truy vấn trên database local mà dump được tạo ra.
{{% /notice %}}
