---
title: "5.4.2 Auth Service và API Gateway"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.4.2. </b> "
---

Auth là service mà mọi luồng người dùng phụ thuộc vào, nên được triển khai đầu tiên, cùng với HTTP API mà mọi Lambda service khác sau này gắn vào. Logical database của nó là `fitness_assistant` và secret là `fitness-assistant/dev/database`.

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của thao tác được viết ngay phía trên ảnh.

#### Bước 1 — Chạy migration schema cho Auth

Một migration Lambda tạm thời, `fitness-assistant-dev-auth-migrate`, được tạo theo [khuôn mẫu chung](../#common-pattern) và được invoke một lần. Các thao tác dưới đây cấu hình và chạy nó.

**1.1 — Đặt memory và timeout.** Mở **Lambda → Functions → `fitness-assistant-dev-auth-migrate` → Configuration → General configuration → Edit**. Nhập các giá trị sau, rồi bấm **Save**:

```text
Memory:  1024 MB
Timeout: 5 min 0 sec
```

![Edit basic settings: memory 1024 MB, timeout 5 phút, Save](/images/workshop/runbook/img003.jpg)

**1.2 — Mở cấu hình VPC.** Trong **Configuration → VPC**, bấm **Edit**.

![Configuration → VPC, nút Edit được khoanh đỏ](/images/workshop/runbook/img004.jpg)

**1.3 — Gắn function vào các private subnet.** Ở màn hình **Edit VPC**, chọn VPC `10.0.0.0/16`, cả hai private app subnet (`fitness-assistant-dev-private-app-a` và `-b`) và security group `fitness-assistant-dev-lambda-sg`, rồi bấm **Save**.

![Edit VPC: VPC, hai private app subnet và Lambda security group, rồi Save](/images/workshop/runbook/img005.jpg)

**1.4 — Đặt tên secret.** Trong **Configuration → Environment variables → Edit**, thêm key và giá trị sau rồi bấm **Save**:

```text
Key:   DATABASE_SECRET_ID
Value: fitness-assistant/dev/database
```

Biến này sẽ xuất hiện trong danh sách.

![Environment variable DATABASE_SECRET_ID = fitness-assistant/dev/database](/images/workshop/runbook/img006.jpg)

**1.5 — Invoke migration.** Mở tab **Test**, tạo một test event có body như sau, rồi bấm **Test**:

```json
{}
```

![Tab Test: nút Test ở cuối trang](/images/workshop/runbook/img002.jpg)

**1.6 — Đọc kết quả.** Function phải kết thúc với **Executing function: succeeded**, và response phải chứa `"status":"ok"`, `"exitCode":0` cùng dòng nói về 7 migration trong `prisma/migrations`. Toàn bộ 7 Prisma migration của database Auth đã được áp dụng.

![Kết quả: succeeded, status ok, exitCode 0, 7 migration](/images/workshop/runbook/img001.jpg)

Sau khi Lambda chính của Auth đã được verify với Aurora (Bước 3), migration Lambda tạm thời được xoá.

#### Bước 2 — Buộc Auth Lambda đọc credential mới

Auth Lambda cache database secret theo từng execution environment. Sau khi mật khẩu Aurora được đổi trong Secrets Manager, các container còn warm vẫn có thể giữ credential cũ. Để buộc tạo execution environment mới, thêm một biến vô hại:

**2.1 — Thêm `DEPLOY_REVISION`.** Trong **Lambda → `fitness-assistant-dev-auth` → Configuration → Environment variables → Edit**, bấm **Add environment variable**, nhập key và giá trị bên dưới, rồi bấm **Save**:

```text
Key:   DEPLOY_REVISION
Value: 20260827-1
```

```
DEPLOY_REVISION = 20260827-1
```

![Thêm DEPLOY_REVISION: Add environment variable, key và value mới, Save](/images/workshop/runbook/img007.jpg)

Code không bao giờ đọc biến này; chỉ cần đổi cấu hình là các environment được làm mới.

#### Bước 3 — Smoke test một route thật sự truy vấn database

**3.1 — Tạo test event.** Trong **`fitness-assistant-dev-auth` → Test**, chọn **Create new event** và đặt tên:

```text
auth-login-db-smoke
```

Dán event API Gateway v2.0 bên dưới cho `POST /auth/login` với email không tồn tại, rồi bấm **Test**:

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

![Test event auth-login-db-smoke: Create new event, event name, Test](/images/workshop/runbook/img008.jpg)

**Kết quả mong đợi:** `statusCode: 401` (sai thông tin đăng nhập). Đây là PASS: nó chứng minh chuỗi `Auth Lambda → Secrets Manager → Prisma Linux engine → Aurora → bảng users` hoạt động. Response **không được** chứa `P1000`, `P1001`, `PrismaClientInitializationError`, `Can't reach database` hay `relation "users" does not exist`. Lỗi 400 nghĩa là payload sai cấu trúc; lỗi 500 nghĩa là phải đọc CloudWatch log trước khi thay đổi gì.

{{% notice tip %}}
Giữ capacity tối thiểu của Aurora ở **0.5 ACU** trong lúc còn đang deploy các service. Với 0 ACU, cluster tự pause sau vài phút idle, và độ trễ khi resume khiến smoke test tiếp theo trông như bị lỗi.
{{% /notice %}}

#### Bước 4 — Tạo HTTP API với Auth integration

**4.1 — Đặt tên API và thêm Lambda integration.** Trong **API Gateway → Create API → HTTP API → Build**, nhập API name sau và giữ IP address type **IPv4**:

```text
fitness-assistant-dev-api
```

Ở mục **Integrations**, chọn type **Lambda**, region `ap-southeast-1`, function `fitness-assistant-dev-auth` (không bao giờ chọn migration Lambda) và payload format version **2.0**. Sau đó bấm **Next**.

![Configure API: API name, IPv4, Lambda integration và function, Next](/images/workshop/runbook/img009.jpg)

#### Bước 5 — Tạo các route public tường minh

**5.1 — Thêm mỗi endpoint public một route.** Ở màn hình **Configure routes**, thêm các route dưới đây, mỗi route có integration target `fitness-assistant-dev-auth`. Ảnh hiển thị đủ 12 dòng.

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

![12 route Auth tường minh, tất cả trỏ tới fitness-assistant-dev-auth](/images/workshop/runbook/img010.jpg)

Các route **không** được tạo: `/auth/internal/*` (endpoint service-to-service được bảo vệ bằng `INTERNAL_SERVICE_SECRET`, các Lambda khác gọi qua direct invoke) và `GET /metrics` (counter Prometheus lưu trong memory không có ý nghĩa khi mỗi execution environment của Lambda giữ counter riêng). Một route catch-all `ANY /auth/{proxy+}` sẽ nhanh hơn, nhưng đồng thời public luôn `/auth/internal/*` ra internet — route tường minh giữ đúng ranh giới bảo mật.

#### Bước 6 — Giữ stage `$default` với auto-deploy

**6.1 — Định nghĩa stage.** Bấm **Next** để sang **Define stages**. Giữ tên stage sau với **Auto-deploy** bật, để thay đổi route có hiệu lực ngay mà không cần deploy thủ công, và invoke URL ngắn gọn:

```text
$default
```

Sau đó bấm **Next**.

![Define stages: $default, Auto-deploy bật, Next](/images/workshop/runbook/img011.jpg)

**6.2 — Review và tạo.** Kiểm tra 12 route trỏ tới `fitness-assistant-dev-auth` và stage là `$default (Auto-deploy: enabled)`, rồi cuộn xuống và bấm **Create**.

![Review and create: 12 route và stage $default](/images/workshop/runbook/img012.jpg)

Invoke URL của API (`https://<api-id>.execute-api.ap-southeast-1.amazonaws.com`) là địa chỉ mà frontend và các biến `PAYMENT_PUBLIC_URL` / `AUTH_SERVICE_URL` dùng từ đây trở đi.

#### Bước 7 — Cho phép frontend trên S3 gọi API (CORS) {#cors}

**7.1 — Cấu hình CORS.** Sau khi frontend được publish ([5.4.3](../5.4.3-Frontend-S3/)), mở **API Gateway → `fitness-assistant-dev-api` → CORS → Configure**, điền các trường dưới đây rồi bấm **Save**.

| Thiết lập | Giá trị |
|---|---|
| Access-Control-Allow-Origin | `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com` (HTTP, vì S3 website endpoint không có HTTPS) |
| Allow headers | `authorization`, `content-type` |
| Allow methods | `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` (ảnh còn hiển thị thêm `HEAD` và `*`) |
| Max age | `300` |
| Allow credentials | Off — frontend gửi `Authorization: Bearer <token>`, không dựa vào cookie cross-site |

![CORS: origin, headers, methods, max age, credentials tắt, Save](/images/workshop/runbook/img017.jpg)

**Verification:** mở `/login` trên frontend, bật tab Network của trình duyệt và đăng nhập bằng một email không tồn tại. Nhận `401 {"error":"Invalid credentials"}` từ API Gateway chứng minh toàn bộ đường đi `S3 website → API Gateway → Auth Lambda → Prisma → Aurora`. Lỗi CORS, 404 hoặc 500 lần lượt nghĩa là cần kiểm tra giá trị origin, danh sách route và log của Lambda.
