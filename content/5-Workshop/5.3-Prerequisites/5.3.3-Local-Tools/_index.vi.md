---
title: "5.3.3 Công cụ local"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.3.3. </b> "
---

Việc triển khai được chạy từ một máy Windows dùng PowerShell. Các công cụ dưới đây cần để build artifact mà các bước trên console sẽ upload.

| Công cụ | Dùng để |
|---|---|
| Git | Clone repository ứng dụng (`fitness-assistant`) |
| Node.js 22 + pnpm | Build từng service và tạo Lambda ZIP artifact trong `backend/services/<service>/artifacts/` (runtime Lambda là Node.js 22.x) |
| AWS CLI v2 | `aws ecr get-login-password`, `aws s3 sync` cho frontend, và `aws ecs run-task` cho migration dữ liệu |
| Docker Desktop | Build image Chat Service và image migrator database cho `linux/amd64` rồi push lên Amazon ECR |
| Trình duyệt có developer tools | Kiểm tra lời gọi API từ frontend trên S3 (tab Network, lỗi CORS, response HTTP 401/429) |

#### Artifact build cho mỗi service

Mỗi backend service tạo các artifact riêng cho HTTP handler, background job và schema migration, từ cùng một lần build:

| Artifact | Handler | Mục đích |
|---|---|---|
| `<service>-lambda.zip` | `dist/lambda.handler` | HTTP API (API Gateway payload format 2.0) |
| `<service>-lambda.zip` (cùng ZIP) | `dist/jobs-lambda.handler` | Job theo lịch được EventBridge Scheduler gọi |
| `<service>-migrate-lambda.zip` | `dist/migrate-lambda.handler` | Tạo logical database của service nếu chưa có và chạy `prisma migrate deploy` |
| `ai-worker-lambda.zip` | `dist/worker-lambda.handler` | AI Worker nhận việc từ hàng đợi SQS |

ZIP vượt giới hạn upload trực tiếp (ví dụ artifact migration ~69 MiB) được upload trước lên bucket deployments `fitness-assistant-deployments-dev-<account-id>` rồi gắn vào function bằng **Upload from → Amazon S3 location**. Mọi artifact đều kèm Prisma query engine cho Linux (`rhel-openssl-3.0.x`), nên ZIP build trên Windows vẫn chạy được trên Lambda.

{{% notice warning %}}
Không bao giờ đưa file `.env`, mật khẩu database, `JWT_SECRET`, `INTERNAL_SERVICE_SECRET`, AWS credential hay key của payment provider vào artifact, image hoặc S3 bucket. Tất cả đều được resolve lúc runtime từ AWS Secrets Manager hoặc cấu hình function.
{{% /notice %}}
