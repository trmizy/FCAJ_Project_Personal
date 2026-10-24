---
title: "User Service"
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

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của thao tác được viết ngay phía trên ảnh. Với thao tác mà runbook không có ảnh chụp, phần văn bản sẽ ghi rõ.

#### Bước 1 — Tạo database secret

**1.1 — Nhập thông tin kết nối.** Mở **Secrets Manager → Store a new secret**, chọn **Other type of secret** và thêm các dòng key/value: `username`, `password` (mật khẩu master của Aurora, lấy trực tiếp từ Secrets Manager — đã che trong ảnh), `host` (cluster endpoint của Aurora), `port = 5432` và `database = fitness_assistant_user`. Giữ encryption key mặc định và bấm **Next**.

![Store a new secret: Other type of secret và năm dòng key/value (password đã che)](/images/workshop/runbook/img018.jpg)

**1.2 — Đặt tên secret.** Ở trang tiếp theo nhập tên `fitness-assistant/dev/user-database`, tắt rotation và lưu secret. *Runbook không có ảnh chụp các trang cuối này.*

#### Bước 2 — Tạo execution role

**2.1 — Tạo role.** Mở **IAM → Roles → Create role**, chọn trusted entity **AWS service → Lambda**, và chỉ gắn managed policy `AWSLambdaBasicExecutionRole` và `AWSLambdaVPCAccessExecutionRole` — không dùng `AdministratorAccess`, `AmazonRDSFullAccess`, `SecretsManagerReadWrite` hay `AmazonS3FullAccess`. Ở trang cuối nhập tên role `fitness-assistant-dev-user-lambda-role`, kiểm tra hai policy rồi bấm **Create role**.

![Name, review and create: tên role, hai managed policy, Create role](/images/workshop/runbook/img019.jpg)

#### Bước 3 — Chỉ cho role đọc đúng secret của nó

**3.1 — Mở JSON editor.** Trong role, mở **Permissions → Add permissions → Create inline policy**, chuyển sang tab **JSON** và dán policy bên dưới. Thay `SECRET_ARN` bằng ARN đầy đủ copy từ trang của secret (placeholder được khoanh đỏ). Không chấp nhận `"Resource": "*"`. Sau đó bấm **Next**.

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

![Policy editor, tab JSON: dòng Resource cần thay bằng ARN của secret](/images/workshop/runbook/img020.jpg)

**3.2 — Đặt tên policy.** Nhập tên policy `fitness-assistant-dev-user-read-database-secret` và bấm **Create policy**.

![Review and create: tên policy, Create policy](/images/workshop/runbook/img021.jpg)

**3.3 — Kiểm tra role.** Role lúc này có hai managed policy và một inline policy.

![Các permission policy của role: hai managed và một inline](/images/workshop/runbook/img022.jpg)

Sau đó schema được migrate bằng Lambda tạm `fitness-assistant-dev-user-migrate` theo [khuôn mẫu chung](../#common-pattern). Hạ tầng mạng outbound mà User Lambda cần cũng được thêm ở thời điểm này — xem [5.4.1](../5.4.1-Shared-Network/).

#### Bước 4 — Tạo User Lambda

**4.1 — Tạo function.** Mở **Lambda → Create function**, chọn **Author from scratch**, nhập tên `fitness-assistant-dev-user`, runtime **Node.js 22.x**, architecture x86_64, và ở **Additional settings → Custom execution role** chọn role có sẵn `fitness-assistant-dev-user-lambda-role`. Sau đó bấm **Create function**.

![Create function: Author from scratch, tên, Node.js 22.x, execution role có sẵn](/images/workshop/runbook/img029.jpg)

**4.2 — Cấu hình function.** Đặt các giá trị dưới đây. *Runbook không có ảnh chụp phần VPC và memory; chúng dùng cùng màn hình như ở [5.4.2, bước 1.1 và 1.3](../5.4.2-Auth-Service-API-Gateway/).*

| Thiết lập | Giá trị |
|---|---|
| VPC | `fitness-assistant-dev-vpc`, subnet `private-app-a` + `private-app-b`, SG `fitness-assistant-dev-lambda-sg` |
| Memory / timeout | 1024 MB / 30 giây |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/user-database` |
| `NODE_ENV` | `production` |
| `AUTH_SERVICE_URL` | invoke URL của API Gateway |
| `USER_UPLOAD_BUCKET` | `fitness-assistant-uploads-dev-<account-id>` |
| `INTERNAL_SERVICE_SECRET` | **cùng** giá trị với Auth Lambda (một secret dùng chung, không tạo mới) |

**4.3 — Thêm environment variable.** Trong **Configuration → Environment variables → Edit**, thêm năm biến trong bảng rồi bấm **Save**. Danh sách khi đó giống ảnh (giá trị secret đã che).

![Environment variable của User Lambda: nút Edit và năm biến](/images/workshop/runbook/img030.jpg)

Biến của các service chưa deploy (`GYM_SERVICE_URL`, `PAYMENT_SERVICE_URL`, `AI_SERVICE_URL`, `CHAT_SERVICE_URL`) để trống cho tới khi các service đó tồn tại.

#### Bước 5 — Cho phép upload ảnh hồ sơ vào một prefix S3

Thêm một inline policy cấp `s3:PutObject` chỉ trên `arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/profile-photos/*` — không dùng `AmazonS3FullAccess`.

**5.1 — Viết policy.** Trong role, mở **Add permissions → Create inline policy → JSON** và nhập một statement với `Action: s3:PutObject` và resource `profile-photos/*`, rồi bấm **Next**.

![Policy editor, tab JSON: s3:PutObject trên prefix profile-photos](/images/workshop/runbook/img032.jpg)

**5.2 — Đặt tên policy.** Nhập tên policy `fitness-assistant-dev-user-profile-upload` và bấm **Create policy**. Phần tóm tắt cho thấy một quyền ghi S3 duy nhất, giới hạn ở `profile-photos/*`.

![Review and create: tên policy fitness-assistant-dev-user-profile-upload](/images/workshop/runbook/img031.jpg)

#### Bước 6 — Upload code

**6.1 — Upload file ZIP.** Trong function, mở **Code → Upload from → .zip file**, bấm **Choose file**, chọn `backend/services/user-service/artifacts/user-lambda.zip` rồi bấm **Update**.

![Update from a .zip file: Choose file, user-lambda.zip, Update](/images/workshop/runbook/img033.jpg)

**6.2 — Đặt handler.** Mở **Runtime settings → Edit** và đặt **Handler** là `dist/lambda.handler`. *Runbook không có ảnh chụp cho function HTTP; cùng màn hình đó của jobs function xuất hiện ở bước 11.5.*

#### Bước 7 — Thêm API Gateway integration

**7.1 — Tạo integration.** Mở **API Gateway → `fitness-assistant-dev-api` → Integrations → Manage integrations → Create**. Chọn **Integration type: Lambda function**, region `ap-southeast-1`, function `fitness-assistant-dev-user`, timeout `30000`, payload format version **2.0**, giữ bật **Grant API Gateway permission to invoke your Lambda function** (API Gateway tự thêm quyền invoke lên function), rồi bấm **Create**.

![Create an integration: Lambda function, region, function, timeout 30000, payload 2.0, quyền invoke, Create](/images/workshop/runbook/img034.jpg)

**7.2 — Kiểm tra danh sách.** API lúc này có các integration của Auth và integration mới `fitness-assistant-dev-user`.

![Danh sách Integrations: integration fitness-assistant-dev-user mới được chọn](/images/workshop/runbook/img035.jpg)

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

**8.1 — Tạo một route cho mỗi dòng.** Mở **Routes → Create**, chọn method (`ANY`, hoặc `GET` cho `/health`), nhập path, ví dụ `/me/{proxy+}`, rồi bấm **Create**. Lặp lại cho từng dòng. Banner xanh ở đầu ảnh xác nhận route trước đó đã được tạo.

![Create a route: method ANY, path, Create](/images/workshop/runbook/img036.jpg)

**8.2 — Gắn integration.** Mở **Integrations → Attach integrations to routes** và gắn `fitness-assistant-dev-user` vào mọi route mới. *Runbook không có ảnh chụp màn hình này.*

Không bao giờ tạo `ANY /{proxy+}` và `ANY /internal/{proxy+}` — `/internal/*` chỉ dành cho service-to-service. `/webhooks/dropbox-sign` cũng bỏ qua vì đang tắt khi `REQUIRE_CONTRACT_ESIGN=false`.

{{% notice warning %}}
Một route đã tồn tại nhưng chưa gắn integration sẽ trả `{"message":"Not Found"}`. Sau khi tạo route, luôn mở **Integrations → Attach integrations to routes** và kiểm tra mọi route đều có target.
{{% /notice %}}

#### Bước 9 — Gọi Auth trực tiếp bằng Lambda Invoke

Một số luồng của User gọi `/auth/internal/*`, vốn cố ý không public. Thay vì public nó, User Lambda invoke trực tiếp Auth Lambda.

**9.1 — Viết policy.** Trong role, mở **Add permissions → Create inline policy → JSON**, nhập policy dưới đây và bấm **Next**:

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

![Policy editor, tab JSON: lambda:InvokeFunction chỉ trên Auth Lambda](/images/workshop/runbook/img037.jpg)

**9.2 — Đặt tên policy.** Nhập tên policy `fitness-assistant-dev-user-invoke-auth` và bấm **Create policy**.

![Review and create: tên policy fitness-assistant-dev-user-invoke-auth](/images/workshop/runbook/img038.jpg)

**9.3 — Thêm `AUTH_LAMBDA_NAME`.** Trong User Lambda, mở **Configuration → Environment variables → Edit**, bấm **Add environment variable**, nhập key `AUTH_LAMBDA_NAME` và giá trị `fitness-assistant-dev-auth` (tạm giữ `AUTH_SERVICE_URL`) rồi bấm **Save**.

![Edit environment variables: dòng AUTH_LAMBDA_NAME mới, Add environment variable, Save](/images/workshop/runbook/img040.jpg)

**9.4 — Kiểm tra kết quả.** Function lúc này có sáu biến, gồm cả `AUTH_LAMBDA_NAME` (giá trị secret đã che).

![Environment variable sau khi sửa: đã thêm AUTH_LAMBDA_NAME](/images/workshop/runbook/img039.jpg)

#### Bước 10 — Quyền S3 cuối cùng và CORS cho presigned upload

Ảnh hồ sơ, tài liệu ứng tuyển PT và PDF hợp đồng đều nằm trong bucket upload private.

**10.1 — Thay policy upload.** Sửa inline policy `fitness-assistant-dev-user-profile-upload` thành ba statement, mỗi statement giới hạn trong một prefix. *Runbook không có ảnh chụp thao tác sửa này.*

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

Không có `s3:*`, không có `s3:ListBucket`.

**10.2 — Thêm rule CORS.** Trình duyệt upload thẳng lên S3 bằng presigned URL, nên bucket upload cần một rule CORS trong khi vẫn giữ private. Mở **Permissions → Cross-origin resource sharing (CORS) → Edit** của bucket, dán JSON bên dưới và bấm **Save changes**.

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

![Edit CORS trên bucket upload private: rule JSON, Save changes](/images/workshop/runbook/img041.jpg)

#### Bước 11 — Tạo jobs Lambda

Background job chạy trong function riêng để HTTP Lambda không bao giờ chạy timer.

**11.1 — Tạo function.** Mở **Lambda → Create function → Author from scratch**, nhập tên `fitness-assistant-dev-user-jobs`, runtime **Node.js 22.x**, role có sẵn `fitness-assistant-dev-user-lambda-role`, rồi bấm **Create function**.

![Create function: tên fitness-assistant-dev-user-jobs, Node.js 22.x, role có sẵn](/images/workshop/runbook/img042.jpg)

**11.2 — Gắn VPC.** Trong **Configuration → VPC → Edit**, chọn VPC, cả hai private app subnet và `fitness-assistant-dev-lambda-sg`, rồi bấm **Save**.

![Edit VPC: VPC, private app subnet, Lambda security group, Save](/images/workshop/runbook/img043.jpg)

**11.3 — Đặt memory và timeout.** Trong **Configuration → General configuration → Edit**, đặt **Memory** `1024` MB và **Timeout** `1` min `0` sec, rồi bấm **Save**.

![Edit basic settings: memory 1024 MB, timeout 1 phút, Save](/images/workshop/runbook/img044.jpg)

**11.4 — Upload code.** Mở **Code → Upload from → .zip file**, chọn cùng `user-lambda.zip` và bấm **Update**.

![Update from a .zip file: user-lambda.zip, Update](/images/workshop/runbook/img045.jpg)

**11.5 — Đặt handler.** Mở **Runtime settings → Edit**, đặt **Handler** là `dist/jobs-lambda.handler` (architecture giữ x86_64) rồi bấm **Save**.

![Edit runtime settings: handler dist/jobs-lambda.handler, x86_64, Save](/images/workshop/runbook/img046.jpg)

**11.6 — Thêm environment variable:** `DATABASE_SECRET_ID`, `NODE_ENV`, `AUTH_LAMBDA_NAME`, `USER_UPLOAD_BUCKET`, `REQUIRE_CONTRACT_ESIGN=false` và `INTERNAL_SERVICE_SECRET` dùng chung, trong **Configuration → Environment variables → Edit → Save**.

![Environment variable của jobs Lambda (secret đã che)](/images/workshop/runbook/img047.jpg)

#### Bước 12 — Tạo scheduler role

**12.1 — Tạo role với custom trust policy.** Mở **IAM → Roles → Create role**, chọn trusted entity type **Custom trust policy** và dán policy dưới đây cho EventBridge Scheduler:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "scheduler.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
```

![Create role: Custom trust policy cho scheduler.amazonaws.com](/images/workshop/runbook/img048.jpg)

Tiếp tục mà không gắn managed policy nào (quyền được thêm bằng inline policy ở thao tác kế tiếp), đặt tên role `fitness-assistant-dev-user-jobs-scheduler-role` và tạo role. *Runbook không có ảnh chụp các trang cuối này.*

**12.2 — Viết inline policy.** Trong role mới, mở **Add permissions → Create inline policy → JSON** và cho phép `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-user-jobs`, rồi bấm **Next**. Scheduler không bao giờ dùng lại execution role của Lambda và không bao giờ có `lambda:*`.

![Policy editor, tab JSON: lambda:InvokeFunction chỉ trên User jobs Lambda](/images/workshop/runbook/img049.jpg)

**12.3 — Đặt tên policy.** Nhập tên policy `fitness-assistant-dev-invoke-user-jobs` và bấm **Create policy**.

![Review and create: tên policy fitness-assistant-dev-invoke-user-jobs](/images/workshop/runbook/img050.jpg)

#### Bước 13 — Tạo ba schedule

Mỗi job một schedule, mỗi schedule gửi `{"job": "<name>"}` tới `fitness-assistant-dev-user-jobs`:

| Schedule | Tần suất | Payload |
|---|---|---|
| `fitness-assistant-dev-user-session-settlement` | `rate(5 minutes)` | `{"job": "session-settlement"}` |
| `fitness-assistant-dev-user-session-auto-confirm` | `rate(10 minutes)` | `{"job": "session-auto-confirm"}` |
| `fitness-assistant-dev-user-reschedule-expiry` | `rate(10 minutes)` | `{"job": "reschedule-expiry"}` |

Các ảnh bên dưới đi theo schedule đầu tiên, `session-settlement`.

**13.1 — Mở wizard.** Mở **Amazon EventBridge → Scheduler → Schedules** và bấm **Create schedule**.

![EventBridge Scheduler: danh sách Schedules, Create schedule](/images/workshop/runbook/img051.jpg)

**13.2 — Đặt tên schedule.** Nhập schedule name `fitness-assistant-dev-user-session-settlement` và giữ schedule group `default`.

![Specify schedule detail: schedule name, group default](/images/workshop/runbook/img052.jpg)

**13.3 — Đặt pattern.** Chọn **Recurring schedule**, time zone `(UTC+07:00) Asia/Saigon`, **Rate-based schedule**, rate `5` `minutes`, và **Flexible time window** `Off`.

![Schedule pattern: recurring, Asia/Saigon, rate-based, rate(5 minutes), tắt flexible window](/images/workshop/runbook/img053.jpg)

**13.4 — Để trống timeframe** (schedule chạy vô thời hạn) rồi bấm **Next**.

![Timeframe để trống, Next](/images/workshop/runbook/img054.jpg)

**13.5 — Chọn target.** Với **Templated targets** đang chọn, chọn **AWS Lambda → Invoke**.

![Select target: Templated targets, AWS Lambda Invoke](/images/workshop/runbook/img055.jpg)

**13.6 — Đặt function và payload.** Chọn Lambda function `fitness-assistant-dev-user-jobs`, nhập payload `{"job": "session-settlement"}` rồi bấm **Next**.

![Invoke: Lambda function fitness-assistant-dev-user-jobs, payload, Next](/images/workshop/runbook/img056.jpg)

**13.7 — Settings.** Giữ: schedule state **Enable**, action after completion **NONE**, **Retry** bật với maximum age of event `5` phút và `2` lần thử lại, dead-letter queue **None** (DEV), key mã hoá do AWS sở hữu, và execution role **Use existing role → `fitness-assistant-dev-user-jobs-scheduler-role`** (không chọn *Create new role*). Bấm **Next**, rồi **Create schedule** ở trang review.

![Settings: Enable, NONE, retry 5 phút / 2 lần, không DLQ, scheduler role có sẵn, Next](/images/workshop/runbook/img057.jpg)

**13.8 — Kiểm tra schedule.** Schedule mới ở trạng thái *Enabled* với `rate (5 minutes)` theo time zone `Asia/Saigon`.

![Đã tạo schedule fitness-assistant-dev-user-session-settlement: banner, Enabled, rate(5 minutes)](/images/workshop/runbook/img058.jpg)

**13.9 — Lặp lại cho hai schedule còn lại.** Tạo schedule thứ hai theo cách tương tự với tên `fitness-assistant-dev-user-session-auto-confirm` và `rate(10 minutes)`, rồi schedule thứ ba `fitness-assistant-dev-user-reschedule-expiry` với `rate(10 minutes)`, mỗi cái với payload riêng trong bảng. *Runbook chỉ có ảnh trang đầu của schedule thứ hai; schedule thứ ba không có ảnh.*

![Schedule thứ hai: tên fitness-assistant-dev-user-session-auto-confirm và rate(10 minutes)](/images/workshop/runbook/img059.jpg)
