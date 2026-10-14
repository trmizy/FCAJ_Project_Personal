---
title: "5.4.4 User Service"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.4.4. </b> "
---

Sau khi đăng nhập, frontend cần ngay hồ sơ người dùng, onboarding và body profile, nên User Service được triển khai tiếp theo. Service này mở đầu ba pattern được các service sau dùng lại: gọi Lambda khác trực tiếp thay vì qua API public, upload S3 private bằng presigned URL, và scheduled job trên EventBridge Scheduler.

| Mục | Giá trị |
|---|---|
| Logical database | `fitness_assistant_user` |
| Secret | `fitness-assistant/dev/user-database` |
| Function | `fitness-assistant-dev-user` (HTTP), `fitness-assistant-dev-user-jobs` (jobs) |
| Bucket upload | `fitness-assistant-uploads-dev-<account-id>` (private) |

#### Bước 1 — Tạo database secret

**Secrets Manager → Store a new secret → Other type of secret** với `username`, `password` (mật khẩu master của Aurora, lấy trực tiếp từ Secrets Manager), `host` (cluster endpoint của Aurora), `port = 5432` và `database = fitness_assistant_user`. Đặt tên `fitness-assistant/dev/user-database`, tắt rotation.

![Secret fitness-assistant/dev/user-database (mật khẩu đã che)](/images/workshop/runbook/img018.jpg)

#### Bước 2 — Tạo execution role

**IAM → Roles → Create role**, trusted entity **AWS service → Lambda**, chỉ gắn managed policy `AWSLambdaBasicExecutionRole` và `AWSLambdaVPCAccessExecutionRole` — không dùng `AdministratorAccess`, `AmazonRDSFullAccess`, `SecretsManagerReadWrite` hay `AmazonS3FullAccess`. Tên: `fitness-assistant-dev-user-lambda-role`.

![Role fitness-assistant-dev-user-lambda-role với hai managed policy](/images/workshop/runbook/img019.jpg)

#### Bước 3 — Chỉ cho role đọc đúng secret của nó

**Role → Permissions → Add permissions → Create inline policy → JSON**, thay `SECRET_ARN` bằng ARN đầy đủ copy từ trang của secret. Không chấp nhận `"Resource": "*"`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": "SECRET_ARN"
    }
  ]
}
```

![Inline policy JSON giới hạn trong secret database của User](/images/workshop/runbook/img020.jpg)

![Tên policy fitness-assistant-dev-user-read-database-secret](/images/workshop/runbook/img021.jpg)

![Role lúc này có hai managed policy và một inline policy](/images/workshop/runbook/img022.jpg)

Sau đó schema được migrate bằng Lambda tạm `fitness-assistant-dev-user-migrate` theo [khuôn mẫu chung](../#common-pattern). Hạ tầng mạng outbound mà User Lambda cần cũng được thêm ở thời điểm này — xem [5.4.1](../5.4.1-Shared-Network/).

#### Bước 4 — Tạo User Lambda

**Lambda → Create function → Author from scratch**: tên `fitness-assistant-dev-user`, Node.js 22.x, x86_64, existing role `fitness-assistant-dev-user-lambda-role`.

![Create function fitness-assistant-dev-user](/images/workshop/runbook/img029.jpg)

Sau đó cấu hình:

| Thiết lập | Giá trị |
|---|---|
| VPC | `fitness-assistant-dev-vpc`, subnet `private-app-a` + `private-app-b`, SG `fitness-assistant-dev-lambda-sg` |
| Memory / timeout | 1024 MB / 30 giây |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/user-database` |
| `NODE_ENV` | `production` |
| `AUTH_SERVICE_URL` | invoke URL của API Gateway |
| `USER_UPLOAD_BUCKET` | `fitness-assistant-uploads-dev-<account-id>` |
| `INTERNAL_SERVICE_SECRET` | **cùng** giá trị với Auth Lambda (một secret dùng chung, không tạo mới) |

![Environment variable của User Lambda (INTERNAL_SERVICE_SECRET đã che)](/images/workshop/runbook/img030.jpg)

Biến của các service chưa deploy (`GYM_SERVICE_URL`, `PAYMENT_SERVICE_URL`, `AI_SERVICE_URL`, `CHAT_SERVICE_URL`) để trống cho tới khi các service đó tồn tại.

#### Bước 5 — Cho phép upload ảnh hồ sơ vào một prefix S3

Tạo inline policy `fitness-assistant-dev-user-profile-upload` cấp `s3:PutObject` chỉ trên `arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/profile-photos/*` — không dùng `AmazonS3FullAccess`.

![Inline policy cho upload profile-photos/*](/images/workshop/runbook/img031.jpg)

![Quyền của role sau khi thêm policy upload](/images/workshop/runbook/img032.jpg)

#### Bước 6 — Upload code

**Code → Upload from → .zip file**: `backend/services/user-service/artifacts/user-lambda.zip`, sau đó **Runtime settings → Edit → Handler** `dist/lambda.handler`.

![Code User Lambda đã upload với handler dist/lambda.handler](/images/workshop/runbook/img033.jpg)

#### Bước 7 — Thêm API Gateway integration

**API Gateway → `fitness-assistant-dev-api` → Integrations → Manage integrations → Create**: Lambda function `fitness-assistant-dev-user`, payload format 2.0. API Gateway tự thêm quyền invoke lên function khi console hỏi xác nhận.

![Tạo Lambda integration cho fitness-assistant-dev-user](/images/workshop/runbook/img034.jpg)

![API lúc này có integration cho Auth và User](/images/workshop/runbook/img035.jpg)

#### Bước 8 — Tạo greedy route theo từng prefix

User Service có hơn 100 endpoint, nên thay vì tạo từng route bằng tay, mỗi prefix public được tạo một greedy route gắn vào User integration:

```
GET  /health
ANY  /profile/{proxy+}
ANY  /inbody/{proxy+}
ANY  /pt-applications/{proxy+}
ANY  /contracts/{proxy+}
ANY  /notifications/{proxy+}
ANY  /sessions/{proxy+}
ANY  /availability/{proxy+}
ANY  /admin/{proxy+}
ANY  /locations/{proxy+}
ANY  /pt/{proxy+}
ANY  /me/{proxy+}
```

![Tạo route của User Service](/images/workshop/runbook/img036.jpg)

Không bao giờ tạo `ANY /{proxy+}` và `ANY /internal/{proxy+}` — `/internal/*` chỉ dành cho service-to-service. `/webhooks/dropbox-sign` cũng bỏ qua vì đang tắt khi `REQUIRE_CONTRACT_ESIGN=false`.

{{% notice warning %}}
Một route đã tồn tại nhưng chưa gắn integration sẽ trả `{"message":"Not Found"}`. Sau khi tạo route, luôn mở **Integrations → Attach integrations to routes** và kiểm tra mọi route đều có target.
{{% /notice %}}

#### Bước 9 — Gọi Auth trực tiếp bằng Lambda Invoke

Một số luồng của User gọi `/auth/internal/*`, vốn cố ý không public. Thay vì public nó, User Lambda invoke trực tiếp Auth Lambda. Thêm inline policy `fitness-assistant-dev-user-invoke-auth`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "InvokeAuthLambda",
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth"
    }
  ]
}
```

![Inline policy chỉ cho phép lambda:InvokeFunction trên Auth Lambda](/images/workshop/runbook/img037.jpg)

![Tên policy fitness-assistant-dev-user-invoke-auth](/images/workshop/runbook/img038.jpg)

Sau đó thêm `AUTH_LAMBDA_NAME = fitness-assistant-dev-auth` vào environment của User Lambda (tạm giữ `AUTH_SERVICE_URL`).

![Đã thêm AUTH_LAMBDA_NAME (giá trị secret đã che)](/images/workshop/runbook/img039.jpg)

![Environment của User Lambda sau khi sửa (giá trị secret đã che)](/images/workshop/runbook/img040.jpg)

#### Bước 10 — Quyền S3 cuối cùng và CORS cho presigned upload

Ảnh hồ sơ, tài liệu ứng tuyển PT và PDF hợp đồng đều nằm trong bucket upload private. Inline policy `fitness-assistant-dev-user-profile-upload` được thay bằng ba statement, mỗi statement giới hạn trong một prefix:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UserProfilePhotos",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/profile-photos/*"
    },
    {
      "Sid": "PTApplicationDocuments",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/pt-applications/*"
    },
    {
      "Sid": "ContractDocuments",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/contracts/*"
    }
  ]
}
```

Không có `s3:*`, không có `s3:ListBucket`. Trình duyệt upload thẳng lên S3 bằng presigned URL, nên bucket upload có thêm rule CORS (**Permissions → Cross-origin resource sharing**) trong khi vẫn giữ private:

```json
[
  {
    "AllowedOrigins": ["http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com"],
    "AllowedMethods": ["PUT", "GET", "HEAD"],
    "AllowedHeaders": ["content-type", "x-amz-*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 300
  }
]
```

![Rule CORS trên bucket upload private](/images/workshop/runbook/img041.jpg)

#### Bước 11 — Tạo jobs Lambda

Background job chạy trong function riêng để HTTP Lambda không bao giờ chạy timer. Tạo `fitness-assistant-dev-user-jobs` (Node.js 22.x, x86_64, role `fitness-assistant-dev-user-lambda-role`), cùng cấu hình VPC, 1024 MB và timeout 1 phút.

![Create function fitness-assistant-dev-user-jobs](/images/workshop/runbook/img042.jpg)

![Cấu hình VPC của jobs Lambda](/images/workshop/runbook/img043.jpg)

![Memory và timeout của jobs Lambda](/images/workshop/runbook/img044.jpg)

Upload cùng `user-lambda.zip` và đặt handler `dist/jobs-lambda.handler`.

![Cùng artifact upload cho jobs Lambda](/images/workshop/runbook/img045.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img046.jpg)

Environment: `DATABASE_SECRET_ID`, `NODE_ENV`, `AUTH_LAMBDA_NAME`, `USER_UPLOAD_BUCKET`, `REQUIRE_CONTRACT_ESIGN=false` và `INTERNAL_SERVICE_SECRET` dùng chung.

![Environment variable của jobs Lambda (secret đã che)](/images/workshop/runbook/img047.jpg)

#### Bước 12 — Tạo scheduler role

**IAM → Roles → Create role** với custom trust policy cho EventBridge Scheduler:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "scheduler.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
```

Đặt tên `fitness-assistant-dev-user-jobs-scheduler-role` và thêm inline policy `fitness-assistant-dev-invoke-user-jobs` cho phép `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-user-jobs`. Scheduler không bao giờ dùng lại execution role của Lambda và không bao giờ có `lambda:*`.

![Custom trust policy cho scheduler.amazonaws.com](/images/workshop/runbook/img048.jpg)

![Inline policy chỉ cho phép lambda:InvokeFunction trên User jobs Lambda](/images/workshop/runbook/img049.jpg)

![Tên policy fitness-assistant-dev-invoke-user-jobs](/images/workshop/runbook/img050.jpg)

#### Bước 13 — Tạo ba schedule

**Amazon EventBridge → Scheduler → Schedules → Create schedule**, mỗi job một schedule, mỗi schedule gửi `{"job": "<name>"}` tới `fitness-assistant-dev-user-jobs`:

| Schedule | Tần suất | Payload |
|---|---|---|
| `fitness-assistant-dev-user-session-settlement` | `rate(5 minutes)` | `{"job": "session-settlement"}` |
| `fitness-assistant-dev-user-session-auto-confirm` | `rate(10 minutes)` | `{"job": "session-auto-confirm"}` |
| `fitness-assistant-dev-user-reschedule-expiry` | `rate(10 minutes)` | `{"job": "reschedule-expiry"}` |

Thiết lập chung: recurring rate-based schedule theo time zone `Asia/Saigon` (UTC+07:00), tắt flexible time window, state enabled, action after completion **NONE**, bật retry với maximum event age 5 phút và 2 lần thử lại, không dùng DLQ ở DEV, key mã hoá do AWS sở hữu, và **Use existing role → `fitness-assistant-dev-user-jobs-scheduler-role`** (không chọn *Create new role*).

![EventBridge Scheduler → Schedules → Create schedule](/images/workshop/runbook/img051.jpg)

![Tên schedule fitness-assistant-dev-user-session-settlement trong group default](/images/workshop/runbook/img052.jpg)

![Recurring rate-based schedule: rate(5 minutes), Asia/Saigon, tắt flexible window](/images/workshop/runbook/img053.jpg)

![Timeframe để trống (chạy vô thời hạn)](/images/workshop/runbook/img054.jpg)

![Target: AWS Lambda Invoke](/images/workshop/runbook/img055.jpg)

![Target fitness-assistant-dev-user-jobs với payload {"job": "session-settlement"}](/images/workshop/runbook/img056.jpg)

![Settings: enabled, action NONE, retry 5 phút / 2 lần, không DLQ, dùng scheduler role có sẵn](/images/workshop/runbook/img057.jpg)

![Đã tạo schedule fitness-assistant-dev-user-session-settlement](/images/workshop/runbook/img058.jpg)

![Schedule thứ hai fitness-assistant-dev-user-session-auto-confirm với rate(10 minutes)](/images/workshop/runbook/img059.jpg)
