---
title: "Blog 1: Đóng gói Microservices và ECR"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 3.1. </b> "
---

## Đóng gói Microservices và lưu Docker image trên Amazon ECR

**Trạng thái:** Draft (bản nháp)

**Ngày đăng:** [TODO_DATE]

**URL bài viết:** [TODO_BLOG_URL]

**Ảnh bìa:** TODO screenshot — chưa chụp.

### Mục tiêu

Giải thích cách các microservice của Fitness Assistant — vốn đã có sẵn Dockerfile multi-stage cho hầu hết service (`frontend/web`, `backend/gateway`, `auth-service`, `user-service`, `fitness-service`, `chat-service`) — được điều chỉnh để triển khai trên AWS, và cách các image này được push lên Amazon ECR.

### Tóm tắt

Hầu hết service trong monorepo `fitness-assistant` đã có sẵn Dockerfile multi-stage hướng production (`base` → `deps` → `builder` → `runner`, dùng `node:20-alpine` và pnpm workspaces). Bài viết này trình bày cách kiểm tra lại các Dockerfile có sẵn đó, viết Dockerfile production cho hai service chỉ có `Dockerfile.dev` (`gym-service`, `payment-service`) nếu cần trong phạm vi triển khai, và push các image kết quả lên Amazon ECR repository theo từng service.

### Nội dung chính

- Xem lại mẫu Dockerfile multi-stage được dùng xuyên suốt monorepo và xác nhận service nào đã có bản build production.
- Build từng image ở local bằng `docker build` và kiểm tra kích thước image cuối cùng.
- Tạo một Amazon ECR repository cho mỗi service, theo đúng quy ước đặt tên ở [Workshop 5.8](../../5-Workshop/5.8-ECR/).
- Đăng nhập Docker vào ECR và push từng image với tag rõ ràng (không chỉ dùng `latest`).
- TODO: Bổ sung output lệnh thật, số liệu kích thước image, và screenshot sau khi build và xác minh thực tế.

### Kiến thức đã học

- Sự khác biệt giữa Dockerfile development (mount source code, hot reload) và Dockerfile production (chỉ chứa artifact đã build, image nhỏ hơn, không cần source code lúc runtime).
- Vì sao chỉ dựa vào tag `latest` khiến việc rollback khó khăn hơn, và cách thiết kế một chiến lược tagging đơn giản hơn.

{{% notice warning %}}
Bài viết này không được khẳng định kích thước image, thời gian build, hay URL ECR repository cụ thể cho đến khi các số liệu đó được ghi lại từ một lần build thực tế. Hãy thay toàn bộ TODO trước khi đăng bài.
{{% /notice %}}
