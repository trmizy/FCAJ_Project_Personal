---
title: "5.4 Run Local"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.4. </b> "
---

{{% notice note %}}
Các bước bên dưới tuân theo đúng `README.md` và `infra/compose/docker-compose.dev.yml` của project. Không chạy lệnh nào không có trong tài liệu của repository nguồn.
{{% /notice %}}

### Clone repository

```bash
git clone https://github.com/trmizy/fitness-assistant.git
cd fitness-assistant
```

### Tạo file môi trường

Project dùng một file `.env` duy nhất ở thư mục gốc (không phải mỗi service một file), được mọi service tham chiếu qua `env_file` trong file Docker Compose dev.

```bash
cp .env.example .env
```

{{% notice warning %}}
Không bao giờ commit file `.env` kết quả. File này đã được liệt kê trong `.gitignore` của repository.
{{% /notice %}}

### Danh sách service thực tế (theo `docker-compose.dev.yml`)

| Service | Port | Vai trò |
| --- | --- | --- |
| `web` (frontend) | 5173 | Frontend React + Vite |
| `api-gateway` | 3000 | Gateway ở tầng ứng dụng: routing, xác thực JWT, rate limiting |
| `auth-service` | 3001 | Đăng ký, đăng nhập, cấp/xác thực JWT |
| `fitness-service` | 3002 | Bài tập, lịch tập, log tập luyện |
| `ai-service` | 3003 | RAG dựa trên Ollama + Qdrant, huấn luyện AI |
| `user-service` | 3004 | Hồ sơ, bản ghi InBody |
| `chat-service` | 3005 | Chat và nhắn tin thời gian thực (không thuộc phạm vi MVP) |
| `gym-service` | 3006 | Danh sách phòng gym/PT (thuộc phạm vi MVP) |
| `payment-service` | 3007 | Thanh toán/ví (thuộc phạm vi MVP, `PAYMENT_PROVIDER=MOCK`) |
| `postgres` | 5433→5432 | PostgreSQL 15 (database-per-service) |
| `redis` | 6379 | Cache và queue BullMQ |
| `qdrant` | 6333/6334 | Vector database cho RAG |
| `ollama` | 11434 | Runtime LLM tự host |

{{% notice note %}}
Bảng service này đầy đủ hơn bảng hiện có trong README của project (README bỏ sót `gym-service` và `payment-service`). Cả hai đều đã được xác nhận tồn tại và kết nối trong `infra/compose/docker-compose.dev.yml`.
{{% /notice %}}

### Chạy bằng Docker Compose

```bash
docker compose -f infra/compose/docker-compose.dev.yml up -d
```

Trên máy cấu hình thấp hơn, có sẵn file override:

```bash
docker compose -f infra/compose/docker-compose.dev.yml -f infra/compose/docker-compose.low-resource.yml up -d
```

### Kiểm tra container

```bash
docker compose -f infra/compose/docker-compose.dev.yml ps
```

Kết quả mong đợi: toàn bộ service cốt lõi (`web`, `api-gateway`, `auth-service`, `user-service`, `fitness-service`, `ai-service`, `postgres`, `redis`, `qdrant`, `ollama`) ở trạng thái healthy/running. TODO: đính kèm screenshot thật sau khi xác minh.

### Kiểm tra log

```bash
docker compose -f infra/compose/docker-compose.dev.yml logs -f api-gateway
```

### Kiểm tra frontend

Mở `http://localhost:5173` trên trình duyệt. Tài khoản seed đã được ghi trong README của project: `john.doe@example.com` / `password123`.

{{% notice warning %}}
Đây là **credential seed/demo cho phát triển local**, đã được ghi trong tài liệu. Không dùng lại cho bất kỳ tài khoản thật nào, và tuyệt đối không dùng trong môi trường production hoặc công khai.
{{% /notice %}}

### Kiểm tra API

```bash
curl http://localhost:3000/health
```

TODO: Xác nhận đúng path health-check mà gateway expose và ghi lại response thực tế.

### Kết quả mong đợi

- Frontend load được tại `http://localhost:5173` và đăng nhập được bằng tài khoản seed.
- API Gateway phản hồi trên port 3000.
- Các backend service báo trạng thái healthy trong `docker compose ps`.

### Các lệnh hữu ích của project

Từ `package.json` gốc của project (pnpm workspace):

```bash
pnpm install
pnpm test
pnpm run build
```

### Troubleshooting cơ bản

- Nếu container thoát ngay lập tức, kiểm tra log trước: `docker compose -f infra/compose/docker-compose.dev.yml logs <service>`.
- Nếu `ollama-model-puller` chưa pull xong `llama3.2:3b` và `nomic-embed-text`, `ai-service` có thể chưa trả lời được chat request — chờ hoàn tất trước khi kiểm thử tính năng AI.
- Xem [5.15 Troubleshooting](../5.15-Troubleshooting/) để có bảng lỗi thường gặp đầy đủ hơn.
