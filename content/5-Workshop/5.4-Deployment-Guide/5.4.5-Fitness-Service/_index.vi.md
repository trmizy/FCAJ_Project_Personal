---
title: "5.4.5 Fitness Service"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.4.5. </b> "
---

Fitness Service (bài tập, workout, dinh dưỡng, chu kỳ tập, dữ liệu coach) là service đầu tiên có artifact quá lớn để upload trực tiếp trên console, nên code được gắn từ bucket deployments.

| Mục | Giá trị |
|---|---|
| Logical database | `fitness_assistant_fitness` (48 Prisma migration) |
| Secret | `fitness-assistant/dev/fitness-database` |
| Function | `fitness-assistant-dev-fitness`, `fitness-assistant-dev-fitness-jobs`, `fitness-assistant-dev-fitness-migrate` tạm thời |
| Gọi tới | Auth và User Lambda (direct invoke) |

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của thao tác được viết ngay phía trên ảnh. Với thao tác mà runbook không có ảnh chụp, phần văn bản sẽ ghi rõ.

#### Bước 1 — Upload migration artifact lên bucket deployments

**1.1 — Mở trang upload.** Mở **S3 → `fitness-assistant-deployments-dev-<account-id>` → Upload** và bấm **Add files**. Destination hiển thị là bucket deployments.

![Trang Upload: bucket đích, Add files, Upload](/images/workshop/runbook/img060.jpg)

**1.2 — Chọn file và upload.** Chọn `backend/services/fitness-service/artifacts/fitness-migrate-lambda.zip` (70.8 MB) rồi bấm **Upload**. Object giữ private. Trang trạng thái hiển thị tiến độ.

![Upload status: fitness-migrate-lambda.zip (70.8 MB) đang upload](/images/workshop/runbook/img061.jpg)

**1.3 — Chờ thành công.** Khi banner **Upload succeeded** xuất hiện và file có trạng thái *Succeeded*, bấm **Close**.

![Upload succeeded: dòng file và Close](/images/workshop/runbook/img062.jpg)

#### Bước 2 — Tạo migration role

**2.1 — Tạo role.** Mở **IAM → Roles → Create role**, chọn **AWS service → Lambda** (màn hình giống bước 5.1) và bấm **Next**. *Runbook không có ảnh chụp màn hình này cho migration role.*

**2.2 — Gắn managed policy.** Chọn `AWSLambdaBasicExecutionRole` và `AWSLambdaVPCAccessExecutionRole`. Trang review liệt kê cả hai.

![Review: hai managed policy](/images/workshop/runbook/img063.jpg)

**2.3 — Đặt tên role.** Nhập tên role `fitness-assistant-dev-fitness-migrate-role` rồi bấm **Create role**.

![Tên role fitness-assistant-dev-fitness-migrate-role](/images/workshop/runbook/img064.jpg)

**2.4 — Thêm inline policy.** Trong role mới, mở **Permissions → Add permissions → Create inline policy**.

![Menu Add permissions: Create inline policy](/images/workshop/runbook/img065.jpg)

**2.5 — Dán JSON.** Chuyển sang tab **JSON** và dán policy dưới đây — chỉ quyền đọc secret của service này. Sau đó bấm **Next**.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": "arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/fitness-database*"
    }
  ]
}
```

![Policy editor, tab JSON: dòng Resource giới hạn trong secret database của Fitness](/images/workshop/runbook/img066.jpg)

**2.6 — Đặt tên policy.** Nhập tên policy `fitness-assistant-dev-fitness-migration-secret` rồi bấm **Create policy**.

![Review and create: tên policy, Create policy](/images/workshop/runbook/img067.jpg)

#### Bước 3 — Tạo migration Lambda và chạy migration

**3.1 — Tạo function.** Mở **Lambda → Create function**, chọn **Author from scratch**, nhập tên `fitness-assistant-dev-fitness-migrate`, runtime **Node.js 22.x**, và ở **Additional settings → Custom execution role** chọn role có sẵn `fitness-assistant-dev-fitness-migrate-role`. Sau đó bấm **Create function**.

![Create function: Author from scratch, tên, Node.js 22.x, role có sẵn](/images/workshop/runbook/img075.jpg)

Các thiết lập còn lại của function này:

| Thiết lập | Giá trị |
|---|---|
| Memory / timeout | 1024 MB / **15 phút** (48 migration) |
| Handler | `dist/migrate-lambda.handler` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` (không cần tự đặt `AWS_REGION` — Lambda đã cung cấp) |
| VPC | `private-app-a` + `private-app-b`, `fitness-assistant-dev-lambda-sg` |

**3.2 — Đặt memory và timeout.** Trong **Configuration → General configuration → Edit**, đặt **Memory** `1024` MB và **Timeout** `15` min `0` sec, rồi bấm **Save**.

![Edit basic settings: memory 1024 MB, timeout 15 phút, Save](/images/workshop/runbook/img068.jpg)

**3.3 — Đặt handler.** Trong **Runtime settings → Edit**, đặt **Handler** là `dist/migrate-lambda.handler`, giữ architecture **x86_64** và bấm **Save**.

![Edit runtime settings: handler dist/migrate-lambda.handler, x86_64, Save](/images/workshop/runbook/img069.jpg)

**3.4 — Thêm tên secret.** Trong **Configuration → Environment variables → Edit**, thêm `DATABASE_SECRET_ID` = `fitness-assistant/dev/fitness-database` rồi bấm **Save**.

![Edit environment variables: DATABASE_SECRET_ID, Save](/images/workshop/runbook/img070.jpg)

**3.5 — Gắn VPC.** Trong **Configuration → VPC → Edit**, chọn VPC, cả hai private app subnet và `fitness-assistant-dev-lambda-sg`, rồi bấm **Save**.

![Edit VPC: hai private app subnet và Lambda security group, Save](/images/workshop/runbook/img071.jpg)

**3.6 — Mở menu cập nhật code.** Ở tab **Code**, bấm **Update** và chọn **Update from a file in Amazon S3**. (File ZIP quá lớn để upload trực tiếp.)

![Tab Code: menu Update, Update from a file in Amazon S3](/images/workshop/runbook/img072.jpg)

**3.7 — Trỏ tới object S3.** Giữ **Copy mode (default)**, dán S3 URI của object `s3://fitness-assistant-deployments-dev-<account-id>/fitness-migrate-lambda.zip` vào **Amazon S3 link**, rồi bấm **Update**.

![Update from a file in Amazon S3: Copy mode, S3 link, Update](/images/workshop/runbook/img073.jpg)

**3.8 — Kiểm tra code properties.** Function lúc này có package 70.8 MB với code storage mode *Copy (default)*.

![Code properties: package 70.8 MB nạp từ S3, Copy mode](/images/workshop/runbook/img074.jpg)

Trước khi invoke, kiểm tra lại VPC, handler, environment và role một lần nữa, rồi invoke function với `{}`. Sau khi toàn bộ 48 migration được áp dụng, migration Lambda tạm thời được xoá — có thể thấy banner xanh "Successfully deleted function: fitness-assistant-dev-fitness-migrate" ở các screenshot tiếp theo.

#### Bước 4 — Upload artifact chính

**4.1 — Upload `fitness-lambda.zip`.** Lặp lại bước 1 cho `fitness-lambda.zip` (53.3 MB) lên cùng bucket deployments. Khi upload xong, kiểm tra trạng thái *Succeeded* rồi bấm **Close**.

![Upload succeeded: fitness-lambda.zip (53.3 MB), Close](/images/workshop/runbook/img076.jpg)

#### Bước 5 — Tạo runtime role

**5.1 — Chọn trusted entity.** Mở **IAM → Roles → Create role**, chọn **AWS service**, use case **Lambda**, rồi bấm **Next**.

![Select trusted entity: AWS service, Lambda, Next](/images/workshop/runbook/img077.jpg)

**5.2 — Gắn managed policy.** Chọn cùng hai managed policy `AWSLambdaBasicExecutionRole` và `AWSLambdaVPCAccessExecutionRole`.

![Managed policy gắn vào role](/images/workshop/runbook/img078.jpg)

**5.3 — Đặt tên role.** Nhập tên role `fitness-assistant-dev-fitness-lambda-role` rồi bấm **Create role**. Trang cũng hiển thị trust policy cho `lambda.amazonaws.com`.

![Tên role fitness-assistant-dev-fitness-lambda-role](/images/workshop/runbook/img079.jpg)

**5.4 — Thêm inline policy đầu tiên.** Trong role, mở **Permissions → Add permissions → Create inline policy**.

![Menu Add permissions: Create inline policy](/images/workshop/runbook/img080.jpg)

**5.5 — Policy secret.** Ở tab **JSON** dán cùng statement secret như ở bước 2.5, bấm **Next**, đặt tên `fitness-assistant-dev-fitness-database-secret` rồi bấm **Create policy**.

![Policy editor, tab JSON: statement secret database của Fitness](/images/workshop/runbook/img081.jpg)

**5.6 — Policy invoke.** Tạo inline policy thứ hai tên `fitness-assistant-dev-fitness-service-invoke` với JSON dưới đây. *Runbook không có ảnh chụp bước này.*

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user"
      ]
    }
  ]
}
```

Không thêm quyền S3, SQS, Bedrock hay Redis — Fitness Service không dùng chúng trên AWS.

#### Bước 6 — Tạo Fitness Lambda

**6.1 — Tạo function.** Mở **Lambda → Create function → Author from scratch**, nhập tên `fitness-assistant-dev-fitness`, runtime **Node.js 22.x**, x86_64, custom execution role `fitness-assistant-dev-fitness-lambda-role`, rồi bấm **Create function**.

![Create function: tên fitness-assistant-dev-fitness, Node.js 22.x, custom execution role](/images/workshop/runbook/img085.jpg)

**6.2 — Gắn code.** Đặt memory 1024 MB và timeout 30 giây, rồi ở **Code → Update → Update from a file in Amazon S3** dùng `s3://fitness-assistant-deployments-dev-<account-id>/fitness-lambda.zip` ở **Copy mode**, giống hệt bước 3.6–3.7. *Runbook không có ảnh chụp các màn hình này cho function này.*

**6.3 — Đặt handler.** Trong **Runtime settings → Edit**, đặt **Handler** là `dist/lambda.handler` rồi bấm **Save**.

![Edit runtime settings: handler dist/lambda.handler, Save](/images/workshop/runbook/img082.jpg)

**6.4 — Thêm environment variable** trong bảng dưới ở **Configuration → Environment variables → Edit**, bấm **Add environment variable** cho từng biến, rồi **Save**.

| Biến | Giá trị |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `FITNESS_DISABLE_REDIS` | `true` |
| `INTERNAL_SERVICE_SECRET` | giá trị dùng chung với Auth/User |

![Edit environment variables: sáu biến, Add environment variable, Save (secret đã che)](/images/workshop/runbook/img083.jpg)

`AI_SERVICE_URL`, `CHAT_SERVICE_URL`, `REDIS_HOST`, `REDIS_PORT` và `PEXELS_API_KEY` để trống vì các dependency đó chưa deploy hoặc chưa bật.

**6.5 — Gắn VPC.** Trong **Configuration → VPC → Edit**, chọn VPC, cả hai private app subnet và `fitness-assistant-dev-lambda-sg`, rồi bấm **Save**.

![Edit VPC: hai private app subnet và Lambda security group, Save](/images/workshop/runbook/img084.jpg)

#### Bước 7 — Nối Fitness Lambda vào API Gateway

**7.1 — Tạo integration.** Mở **API Gateway → `fitness-assistant-dev-api` → Integrations → Manage integrations → Create**. Chọn **Lambda function**, region `ap-southeast-1`, function `fitness-assistant-dev-fitness`, payload format version **2.0**, giữ bật **Grant API Gateway permission to invoke your Lambda function**, rồi bấm **Create**.

![Create integration: Lambda function, region, function, payload 2.0, quyền invoke, Create](/images/workshop/runbook/img086.jpg)

**7.2 — Tạo route.** Với mỗi prefix public, tạo **cả** route gốc lẫn greedy route để `/workouts` và `/workouts/...` đều khớp (**Routes → Create**, method `ANY`). *Runbook không có ảnh chụp việc tạo route của service này; cách làm giống [5.4.4, bước 8](../5.4.4-User-Service/).*

```
ANY /exercises         ANY /exercises/{proxy+}
ANY /workouts          ANY /workouts/{proxy+}
ANY /nutrition         ANY /nutrition/{proxy+}
ANY /stats             ANY /stats/{proxy+}
ANY /food              ANY /food/{proxy+}
ANY /training-cycles   ANY /training-cycles/{proxy+}
ANY /coach             ANY /coach/{proxy+}
ANY /equipment         ANY /equipment/{proxy+}
ANY /imports           ANY /imports/{proxy+}
ANY /exports           ANY /exports/{proxy+}
ANY /templates         ANY /templates/{proxy+}
```

Không tạo `/internal`, `/internal/{proxy+}` và `/{proxy+}`, và không tạo trùng `GET /health` toàn cục (đang thuộc Auth).

**7.3 — Kiểm tra việc gắn.** Mở **Integrations → Attach integrations to routes**. Chọn một route mới như `ANY /exercises/{proxy+}`: phần chi tiết hiển thị Lambda function `fitness-assistant-dev-fitness`.

![Attach integrations to routes: ANY /exercises/{proxy+} trỏ tới fitness-assistant-dev-fitness](/images/workshop/runbook/img087.jpg)

#### Bước 8 — Tạo jobs Lambda

`fitness-assistant-dev-fitness-jobs`: cùng role, cùng `fitness-lambda.zip` từ S3, handler `dist/jobs-lambda.handler`, 1024 MB, 1 phút, cùng VPC và cùng environment variable với HTTP Lambda. Function này chạy hai job: `workout-upcoming-reminder` và `workout-unfinished-reminder`.

**8.1 — Tạo function.** Mở **Lambda → Create function → Author from scratch**, nhập tên `fitness-assistant-dev-fitness-jobs`, runtime **Node.js 22.x**, custom execution role `fitness-assistant-dev-fitness-lambda-role`, rồi bấm **Create function**.

![Create function: tên fitness-assistant-dev-fitness-jobs, Node.js 22.x, custom execution role](/images/workshop/runbook/img088.jpg)

**8.2 — Gắn VPC.** Trong **Configuration → VPC → Edit**, chọn VPC, cả hai private app subnet và Lambda security group, rồi bấm **Save**.

![Edit VPC: hai private app subnet và Lambda security group, Save](/images/workshop/runbook/img089.jpg)

**8.3 — Thêm environment variable** (sáu biến giống HTTP Lambda) trong **Configuration → Environment variables → Edit → Save**. Danh sách sau đó trông như bên dưới (secret đã che). *Runbook không có ảnh chụp memory, timeout, handler và code của function này; chúng làm theo các bước 3.2, 3.3, 3.6 và 3.7 với giá trị ở trên.*

![Environment variable của jobs Lambda: nút Edit và sáu biến](/images/workshop/runbook/img090.jpg)

#### Bước 9 — Tạo scheduler role

**9.1 — Chọn custom trust policy.** Mở **IAM → Roles → Create role**, chọn **Custom trust policy** và dán trust policy cho `scheduler.amazonaws.com`, rồi tiếp tục mà không gắn managed policy.

![Create role: Custom trust policy cho scheduler.amazonaws.com](/images/workshop/runbook/img091.jpg)

**9.2 — Đặt tên role.** Nhập tên role `fitness-assistant-dev-fitness-jobs-scheduler-role` rồi bấm **Create role**.

![Tên role fitness-assistant-dev-fitness-jobs-scheduler-role](/images/workshop/runbook/img092.jpg)

**9.3 — Thêm inline policy.** Trong role, mở **Add permissions → Create inline policy → JSON** và cho phép `lambda:InvokeFunction` chỉ trên jobs Lambda, rồi bấm **Next**.

![Policy editor, tab JSON: lambda:InvokeFunction trên fitness-assistant-dev-fitness-jobs](/images/workshop/runbook/img093.jpg)

**9.4 — Đặt tên policy.** Nhập tên policy `fitness-assistant-dev-invoke-fitness-jobs` rồi bấm **Create policy**.

![Review and create: tên policy fitness-assistant-dev-invoke-fitness-jobs](/images/workshop/runbook/img094.jpg)

#### Bước 10 — Tạo hai schedule nhắc lịch

| Schedule | Tần suất | Payload | Tác dụng |
|---|---|---|---|
| `fitness-assistant-dev-workout-upcoming-reminder` | `rate(30 minutes)` | `{"job": "workout-upcoming-reminder"}` | Quét các workout `NOT_STARTED` hôm nay chưa được nhắc |
| `fitness-assistant-dev-workout-unfinished-reminder` | `rate(30 minutes)` | `{"job": "workout-unfinished-reminder"}` | Nhắc các workout `IN_PROGRESS` đã bắt đầu ít nhất 3 giờ |

Cả hai dùng time zone `Asia/Saigon`, tắt flexible window, state enabled, action NONE, retry (5 phút / 2 lần), không DLQ, key do AWS sở hữu và scheduler role có sẵn. Các ảnh đầu tiên đi theo schedule upcoming-reminder.

**10.1 — Đặt tên và pattern.** Trong **EventBridge → Scheduler → Schedules → Create schedule**, nhập schedule name `fitness-assistant-dev-workout-upcoming-reminder`, giữ group `default`, chọn **Recurring schedule**, time zone `(UTC+07:00) Asia/Saigon` và **Rate-based schedule**.

![Specify schedule detail: tên, group default, recurring, Asia/Saigon, rate-based](/images/workshop/runbook/img095.jpg)

**10.2 — Đặt rate.** Nhập rate `30` `minutes` và giữ **Flexible time window** `Off`. Để trống timeframe rồi bấm **Next**.

![Rate expression: 30 minutes, tắt flexible time window](/images/workshop/runbook/img096.jpg)

**10.3 — Chọn target.** Với **Templated targets** đang chọn, chọn **AWS Lambda → Invoke**.

![Select target: Templated targets, AWS Lambda Invoke](/images/workshop/runbook/img097.jpg)

**10.4 — Function và payload.** Chọn Lambda function `fitness-assistant-dev-fitness-jobs`, nhập payload `{"job": "workout-upcoming-reminder"}` rồi bấm **Next**.

![Invoke: function fitness-assistant-dev-fitness-jobs, payload workout-upcoming-reminder, Next](/images/workshop/runbook/img098.jpg)

**10.5 — Thiết lập retry.** Giữ **Retry** bật với maximum age of event `5` phút (`0` giờ) và `2` lần retry, dead-letter queue **None**.

![Retry policy: Retry bật, maximum age 5 phút, 2 lần, DLQ None](/images/workshop/runbook/img099.jpg)

**10.6 — Permissions.** Ở **Execution role**, chọn **Use existing role** và chọn `fitness-assistant-dev-fitness-jobs-scheduler-role`, rồi bấm **Next** và **Create schedule** ở trang review. *Trong ảnh toàn trang này công tắc Retry đang hiển thị tắt; giá trị retry lấy từ ảnh trước, nên hãy kiểm tra lại công tắc này khi làm lại bước.*

![Settings: Use existing role, scheduler role, Next](/images/workshop/runbook/img100.jpg)

**10.7 — Schedule thứ hai: tên và rate.** Tạo schedule thứ hai theo cách tương tự: tên `fitness-assistant-dev-workout-unfinished-reminder`, recurring, rate-based, rate `30` `minutes`.

![Schedule thứ hai: tên fitness-assistant-dev-workout-unfinished-reminder, rate 30 minutes](/images/workshop/runbook/img101.jpg)

**10.8 — Schedule thứ hai: payload.** Target **AWS Lambda → Invoke**, function `fitness-assistant-dev-fitness-jobs`, payload `{"job": "workout-unfinished-reminder"}`, rồi **Next**.

![Invoke: function fitness-assistant-dev-fitness-jobs, payload workout-unfinished-reminder, Next](/images/workshop/runbook/img102.jpg)

**10.9 — Schedule thứ hai: settings.** Giữ: **Enable**, action **NONE**, **Retry** bật với maximum age `5` phút và `2` lần, DLQ **None**, và **Use existing role** với cùng scheduler role. Sau đó tạo schedule.

![Settings: Enable, Retry 5 phút / 2 lần, DLQ None, role có sẵn](/images/workshop/runbook/img103.jpg)

{{% notice note %}}
Nhắc workout sắp tới hiện chỉ có độ chi tiết theo ngày: schema hiện tại không lưu giờ tập dự kiến, nên job không thể gửi kiểu "còn 30 phút nữa tới buổi tập". Nó nhắc các workout lên lịch hôm nay mà chưa được nhắc.
{{% /notice %}}
