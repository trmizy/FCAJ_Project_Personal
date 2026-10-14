---
title: "5.4.2 Auth Service và API Gateway"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.4.2. </b> "
---

Auth là service mà mọi luồng người dùng phụ thuộc vào, nên được triển khai đầu tiên, cùng với HTTP API mà mọi Lambda service khác sau này gắn vào. Logical database của nó là `fitness_assistant` và secret là `fitness-assistant/dev/database`.

#### Bước 1 — Chạy migration schema cho Auth

Một migration Lambda tạm thời được tạo theo [khuôn mẫu chung](../#common-pattern) (1024 MB, timeout 5 phút, gắn VPC, `DATABASE_SECRET_ID = fitness-assistant/dev/database`) và được invoke một lần. Toàn bộ 7 Prisma migration đã được áp dụng.

![Auth migration Lambda — kết quả invoke thử](/images/workshop/runbook/img001.jpg)

![Auth migration — 7 migration áp dụng thành công](/images/workshop/runbook/img002.jpg)

![Basic settings của migration Lambda (memory và timeout)](/images/workshop/runbook/img003.jpg)

![Migration Lambda gắn vào VPC](/images/workshop/runbook/img004.jpg)

![Cấu hình VPC: hai private app subnet và fitness-assistant-dev-lambda-sg](/images/workshop/runbook/img005.jpg)

![Environment variable DATABASE_SECRET_ID = fitness-assistant/dev/database](/images/workshop/runbook/img006.jpg)

Sau khi Lambda chính của Auth đã được verify với Aurora (Bước 3), migration Lambda tạm thời được xoá.

#### Bước 2 — Buộc Auth Lambda đọc credential mới

Auth Lambda cache database secret theo từng execution environment. Sau khi mật khẩu Aurora được đổi trong Secrets Manager, các container còn warm vẫn có thể giữ credential cũ. Để buộc tạo execution environment mới, thêm một biến vô hại ở **Lambda → `fitness-assistant-dev-auth` → Configuration → Environment variables → Edit**:

```
DEPLOY_REVISION = 20260827-1
```

Code không bao giờ đọc biến này; chỉ cần đổi cấu hình là các environment được làm mới.

![Thêm DEPLOY_REVISION để làm mới execution environment](/images/workshop/runbook/img007.jpg)

#### Bước 3 — Smoke test một route thật sự truy vấn database

Trong **`fitness-assistant-dev-auth` → Test → Create new event** (`auth-login-db-smoke`), gửi một event API Gateway v2.0 cho `POST /auth/login` với email không tồn tại:

```json
{
  "version": "2.0",
  "routeKey": "POST /auth/login",
  "rawPath": "/auth/login",
  "rawQueryString": "",
  "headers": {
    "content-type": "application/json",
    "accept": "application/json",
    "host": "example.execute-api.ap-southeast-1.amazonaws.com"
  },
  "requestContext": {
    "accountId": "123456789012",
    "apiId": "test",
    "domainName": "example.execute-api.ap-southeast-1.amazonaws.com",
    "domainPrefix": "example",
    "http": {
      "method": "POST",
      "path": "/auth/login",
      "protocol": "HTTP/1.1",
      "sourceIp": "127.0.0.1",
      "userAgent": "AWS-Lambda-Test"
    },
    "requestId": "auth-db-smoke",
    "routeKey": "POST /auth/login",
    "stage": "$default",
    "time": "27/Aug/2026:09:30:00 +0700",
    "timeEpoch": 1787797800000
  },
  "body": "{\"email\":\"aws-smoke-nonexistent@example.com\",\"password\":\"NotARealPassword123!\"}",
  "isBase64Encoded": false
}
```

![Test event auth-login-db-smoke](/images/workshop/runbook/img008.jpg)

**Kết quả mong đợi:** `statusCode: 401` (sai thông tin đăng nhập). Đây là PASS: nó chứng minh chuỗi `Auth Lambda → Secrets Manager → Prisma Linux engine → Aurora → bảng users` hoạt động. Response **không được** chứa `P1000`, `P1001`, `PrismaClientInitializationError`, `Can't reach database` hay `relation "users" does not exist`. Lỗi 400 nghĩa là payload sai cấu trúc; lỗi 500 nghĩa là phải đọc CloudWatch log trước khi thay đổi gì.

{{% notice tip %}}
Giữ capacity tối thiểu của Aurora ở **0.5 ACU** trong lúc còn đang deploy các service. Với 0 ACU, cluster tự pause sau vài phút idle, và độ trễ khi resume khiến smoke test tiếp theo trông như bị lỗi.
{{% /notice %}}

#### Bước 4 — Tạo HTTP API với Auth integration

**API Gateway → Create API → HTTP API**:

1. API name: `fitness-assistant-dev-api`, IP address type IPv4.
2. **Add integration** → type **Lambda**, region `ap-southeast-1`, function `fitness-assistant-dev-auth`, payload format version **2.0**. (Không bao giờ chọn migration Lambda.)

![Tạo HTTP API fitness-assistant-dev-api với Auth Lambda integration](/images/workshop/runbook/img009.jpg)

#### Bước 5 — Tạo các route public tường minh

Ở màn hình **Configure routes**, thêm mỗi endpoint public một route, tất cả trỏ tới `fitness-assistant-dev-auth`:

```
POST   /auth/register
POST   /auth/register/verify
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
POST   /auth/verify
PATCH  /auth/me
GET    /auth/users
PATCH  /auth/users/{userId}/role
PATCH  /auth/users/{userId}/disable
PATCH  /auth/users/{userId}/enable
GET    /health
```

![12 route Auth tường minh](/images/workshop/runbook/img010.jpg)

Các route **không** được tạo: `/auth/internal/*` (endpoint service-to-service được bảo vệ bằng `INTERNAL_SERVICE_SECRET`, các Lambda khác gọi qua direct invoke) và `GET /metrics` (counter Prometheus lưu trong memory không có ý nghĩa khi mỗi execution environment của Lambda giữ counter riêng). Một route catch-all `ANY /auth/{proxy+}` sẽ nhanh hơn, nhưng đồng thời public luôn `/auth/internal/*` ra internet — route tường minh giữ đúng ranh giới bảo mật.

#### Bước 6 — Giữ stage `$default` với auto-deploy

Giữ stage mặc định `$default` với **Auto-deploy** bật, để thay đổi route có hiệu lực ngay mà không cần deploy thủ công, và invoke URL ngắn gọn.

![Stage $default với auto-deploy](/images/workshop/runbook/img011.jpg)

![Review và tạo: 12 route → fitness-assistant-dev-auth, stage $default](/images/workshop/runbook/img012.jpg)

Invoke URL của API (`https://<api-id>.execute-api.ap-southeast-1.amazonaws.com`) là địa chỉ mà frontend và các biến `PAYMENT_PUBLIC_URL` / `AUTH_SERVICE_URL` dùng từ đây trở đi.

#### Bước 7 — Cho phép frontend trên S3 gọi API (CORS) {#cors}

Sau khi frontend được publish ([5.4.3](../5.4.3-Frontend-S3/)), cấu hình **API Gateway → `fitness-assistant-dev-api` → CORS → Configure**:

| Thiết lập | Giá trị |
|---|---|
| Access-Control-Allow-Origin | `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com` (HTTP, vì S3 website endpoint không có HTTPS) |
| Allow headers | `authorization`, `content-type` |
| Allow methods | `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` |
| Max age | `300` |
| Allow credentials | Off — frontend gửi `Authorization: Bearer <token>`, không dựa vào cookie cross-site |

![Cấu hình CORS cho origin S3 website](/images/workshop/runbook/img017.jpg)

**Verification:** mở `/login` trên frontend, bật tab Network của trình duyệt và đăng nhập bằng một email không tồn tại. Nhận `401 {"error":"Invalid credentials"}` từ API Gateway chứng minh toàn bộ đường đi `S3 website → API Gateway → Auth Lambda → Prisma → Aurora`. Lỗi CORS, 404 hoặc 500 lần lượt nghĩa là cần kiểm tra giá trị origin, danh sách route và log của Lambda.
