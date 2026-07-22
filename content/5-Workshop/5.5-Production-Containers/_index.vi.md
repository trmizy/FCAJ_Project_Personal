---
title: "5.5 Production Containers"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.5. </b> "
---

### Phân tích Dockerfile hiện có

Hầu hết service trong `fitness-assistant` đã có sẵn **Dockerfile multi-stage hướng production** bên cạnh một `Dockerfile.dev` riêng:

| Service | Có Dockerfile production? | Ghi chú |
| --- | --- | --- |
| `frontend/web` | Có | Multi-stage: `pnpm build` → thư mục `dist/` tĩnh được phục vụ bởi `nginx:1.25-alpine` trên port 80. Nhúng cứng `VITE_API_URL`, `VITE_SOCKET_URL`, `VITE_CHAT_WS_URL` dưới dạng build ARG. |
| `backend/gateway` | Có | Multi-stage (`base`/`deps`/`builder`/`runner`), `node:20-alpine`, build bằng `tsc`, `EXPOSE 3000`. |
| `backend/services/auth-service` | Có | Multi-stage; `CMD sh -c "prisma migrate deploy && node dist/server.js"` (tự chạy migration khi khởi động). |
| `backend/services/ai-service` | Có | Cùng mẫu với `auth-service`, `EXPOSE 3003`. |
| `backend/services/user-service` | Có | Base image `node:20-slim` (cài `openssl`, `fonts-dejavu-core` để tạo PDF). `CMD node dist/server.js` — **không** tự chạy `prisma migrate deploy`, khác với `auth-service`/`ai-service`. |
| `backend/services/fitness-service` | Có | Cùng mẫu multi-stage với các service khác. |
| `backend/services/chat-service` | Có | Cùng mẫu multi-stage (không thuộc phạm vi MVP). |
| `backend/services/gym-service` | **Không** — chỉ có `Dockerfile.dev` | Không thuộc phạm vi MVP; cần viết Dockerfile production trước khi triển khai. |
| `backend/services/payment-service` | **Không** — chỉ có `Dockerfile.dev` | Không thuộc phạm vi MVP; cùng khoảng trống với `gym-service`. |

{{% notice warning %}}
Không khẳng định `gym-service` hoặc `payment-service` đã sẵn sàng container production — thực tế chưa, tính đến thời điểm viết Workshop này. Nếu được thêm vào một triển khai tương lai, cần viết và kiểm thử Dockerfile production trước.
{{% /notice %}}

### "Production" ở đây nghĩa là gì

- Multi-stage build: giai đoạn `deps`/`builder` cài dependency và compile TypeScript; giai đoạn `runner` chỉ copy artifact đã build và `node_modules` production.
- Không chạy dev file-watcher (`nodemon`, `vite dev`, v.v.) — frontend phục vụ bản build tĩnh qua Nginx; backend service chạy trực tiếp `dist/server.js` đã compile.
- File `.env` không bao giờ được copy vào image; cấu hình runtime đến từ biến môi trường được inject bởi Docker Compose / môi trường triển khai.
- File `.dockerignore` loại trừ `node_modules`, `.env`, và các artifact local khác khỏi build context.

### Ví dụ: `.dockerignore`

Xem [`/files/docker/.dockerignore.example`](/files/docker/.dockerignore.example) để có `.dockerignore` mẫu bao gồm `node_modules`, `.env*`, `dist`, và file editor local.

### Ví dụ: mẫu Dockerfile production

Xem [`/files/docker/Dockerfile.production.example`](/files/docker/Dockerfile.production.example) để có Dockerfile multi-stage mẫu khớp với mẫu đã dùng bởi `auth-service`/`ai-service`/`fitness-service` trong repository nguồn (đây là **ví dụ tham khảo**, không phải bản copy nguyên văn file nguồn — luôn kiểm tra script build thật trong `package.json` của service trước khi tùy chỉnh).

### Non-root user

Các Dockerfile hiện có trong `fitness-assistant` chạy bằng user mặc định của image. TODO: xác nhận directive `USER` non-root có tương thích với từng service hay không (đặc biệt `user-service`, service ghi vào thư mục `uploads/` local) trước khi thêm, và ghi lại kết quả tại đây.

### Health check

TODO: xác nhận từng Dockerfile của service có định nghĩa `HEALTHCHECK` hay không (các image multi-stage có `apk add wget`, gợi ý ít nhất một số service dùng healthcheck dựa trên wget) — kiểm tra theo từng service và ghi lại kết quả thay vì giả định.

### Build image

```bash
docker build -t fitness-assistant/auth-service:local -f backend/services/auth-service/Dockerfile .
docker build -t fitness-assistant/frontend:local \
  --build-arg VITE_API_URL=http://localhost:3000 \
  -f frontend/web/Dockerfile .
```

{{% notice note %}}
Xác nhận đúng build context path cho từng service trước khi chạy các lệnh này — một số Dockerfile multi-stage trong pnpm workspace yêu cầu build context là **thư mục gốc repository**, không phải thư mục con của service, vì cần truy cập `backend/shared` và `pnpm-lock.yaml` gốc.
{{% /notice %}}

### Kiểm tra image

```bash
docker images | grep fitness-assistant
```

TODO: ghi lại kích thước image thực tế sau khi build.

### Scan image

TODO: nếu dùng công cụ scan (ví dụ `docker scout`, `trivy`, hoặc tính năng scan cơ bản có sẵn của Amazon ECR), ghi lại công cụ và kết quả tại đây. Chưa thực hiện.

### Chiến lược tagging

Khuyến nghị: gắn mỗi image với cả tag theo semantic/ngày và `latest`, ví dụ `service:2026-07-15` và `service:latest`, để luôn xác định được phiên bản đã triển khai cụ thể và có thể rollback. Xem [5.8 ECR](../5.8-ECR/) để biết quy ước tagging đầy đủ khi push lên Amazon ECR.
