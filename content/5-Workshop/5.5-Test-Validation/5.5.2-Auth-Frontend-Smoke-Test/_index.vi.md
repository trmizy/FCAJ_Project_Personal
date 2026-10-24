---
title: "Frontend, API Gateway và Auth"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.5.2. </b> "
---

Các bài kiểm tra này đi qua đường request chính từng lớp một, để khi lỗi thì chỉ thẳng vào lớp bị hỏng.

| # | Kiểm tra | Cách làm | Kết quả mong đợi | Trạng thái |
|---|---|---|---|---|
| T1 | Lambda → Aurora | Test event `auth-login-db-smoke` trên Lambda console (`POST /auth/login`, email không tồn tại) | `statusCode: 401` "invalid credentials", **không có** `P1000`, `P1001`, `PrismaClientInitializationError`, `Can't reach database` hay `relation "users" does not exist` | Pass |
| T2 | Static hosting + SPA fallback | Mở trực tiếp `http://<frontend-bucket>.s3-website-ap-southeast-1.amazonaws.com/login` | Trang đăng nhập hiển thị (không phải 404 của S3) | Pass |
| T3 | Browser → API Gateway → Lambda → Aurora | Trên `/login`, mở DevTools → Network và đăng nhập bằng email không tồn tại | `POST /auth/login` → `401 {"error":"Invalid credentials"}`, không có lỗi CORS | Pass |
| T4 | Mọi route đều có integration | API Gateway → *Integrations → Attach integrations to routes* | Mỗi route hiện target Lambda/HTTP; không route nào trả `{"message":"Not Found"}` | Đã kiểm tra cho từng service khi deploy |
| T5 | Endpoint nội bộ không public | `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/internal/anything` và `/auth/internal/users/batch` | `404 Not Found` từ API Gateway (không có route này) | Đưa vào lượt E2E cuối |
| T6 | Route AI bị rate limit | Gửi nhiều `POST /ai/ask` trong một giây | Một số trả `429 Too Many Requests`; frontend hiện thông báo "quá nhiều yêu cầu" thay vì retry liên tục | Đưa vào lượt E2E cuối |
| T7 | Đăng nhập thật và hồ sơ | Đăng ký, xác minh, đăng nhập, mở profile/onboarding | Các route `/auth/*` và User trả 200, dữ liệu lưu trong Aurora | Đưa vào lượt E2E cuối |

#### Bằng chứng

T1 — test event dùng để smoke test Auth Lambda:

![Test event auth-login-db-smoke](/images/workshop/runbook/img008.jpg)

T2 — bản build frontend đã publish lên website bucket (sau đó route `/login` tải trực tiếp từ website endpoint):

![Bản build frontend đã upload lên S3 website bucket](/images/workshop/runbook/img016.jpg)

T4 — các route đã gắn integration, ví dụ route của Fitness, Payment và AI:

![Route Fitness gắn vào fitness-assistant-dev-fitness](/images/workshop/runbook/img087.jpg)

![Route Payment gắn vào fitness-assistant-dev-payment](/images/workshop/runbook/img140.jpg)

![Route AI gắn vào fitness-assistant-dev-ai](/images/workshop/runbook/img234.jpg)

T6 — bundle production đã có sẵn thông báo cho người dùng khi bị throttling và timeout (HTTP 408/504 "AI phản hồi quá lâu", 429 "AI Coach đang nhận quá nhiều yêu cầu", 502/503 "chưa sẵn sàng"):

![Kiểm tra bundle: có URL API và thông báo xử lý 429](/images/workshop/runbook/img334.jpg)

#### Đọc lỗi thế nào

| Triệu chứng | Lớp cần kiểm tra |
|---|---|
| Lỗi CORS trên browser | CORS origin của API Gateway phải đúng chính xác URL `http://` của S3 website |
| `{"message":"Not Found"}` | Thiếu route, hoặc route chưa gắn integration |
| `{"message":"Internal Server Error"}` / 500 | CloudWatch log của Lambda `/aws/lambda/fitness-assistant-dev-<service>` |
| Prisma `P1001` / timeout | Lambda không nằm trong private app subnet, hoặc Aurora SG thiếu Lambda SG ở port 5432 |
| `AccessDeniedException` trong log | Role của function thiếu đúng quyền secret / invoke / Bedrock |
