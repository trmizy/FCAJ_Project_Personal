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

#### Bước 1 — Upload migration artifact lên bucket deployments

**S3 → `fitness-assistant-deployments-dev-<account-id>` → Upload** `backend/services/fitness-service/artifacts/fitness-migrate-lambda.zip`. Object giữ private.

![Upload lên bucket deployments](/images/workshop/runbook/img060.jpg)

![Đang upload fitness-migrate-lambda.zip (70.8 MB)](/images/workshop/runbook/img061.jpg)

![Upload thành công](/images/workshop/runbook/img062.jpg)

#### Bước 2 — Tạo migration role

**IAM → Roles → Create role → AWS service → Lambda**, managed policy `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole`, tên `fitness-assistant-dev-fitness-migrate-role`.

![Tên role fitness-assistant-dev-fitness-migrate-role](/images/workshop/runbook/img064.jpg)

![Hai managed policy](/images/workshop/runbook/img063.jpg)

Sau đó **Permissions → Add permissions → Create inline policy → JSON** — chỉ quyền đọc secret của service này:

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

![Add permissions → Create inline policy](/images/workshop/runbook/img065.jpg)

![Inline policy giới hạn trong secret database của Fitness](/images/workshop/runbook/img066.jpg)

![Tên policy fitness-assistant-dev-fitness-migration-secret](/images/workshop/runbook/img067.jpg)

#### Bước 3 — Tạo migration Lambda và chạy migration

**Lambda → Create function → Author from scratch**: `fitness-assistant-dev-fitness-migrate`, Node.js 22.x, x86_64, existing role `fitness-assistant-dev-fitness-migrate-role`.

![Create function fitness-assistant-dev-fitness-migrate](/images/workshop/runbook/img075.jpg)

| Thiết lập | Giá trị |
|---|---|
| Memory / timeout | 1024 MB / **15 phút** (48 migration) |
| Handler | `dist/migrate-lambda.handler` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` (không cần tự đặt `AWS_REGION` — Lambda đã cung cấp) |
| VPC | `private-app-a` + `private-app-b`, `fitness-assistant-dev-lambda-sg` |

![Memory 1024 MB và timeout 15 phút](/images/workshop/runbook/img068.jpg)

![Handler dist/migrate-lambda.handler trên x86_64](/images/workshop/runbook/img069.jpg)

![DATABASE_SECRET_ID cho database Fitness](/images/workshop/runbook/img070.jpg)

![VPC: hai private app subnet và Lambda security group](/images/workshop/runbook/img071.jpg)

Gắn code bằng **Code → Upload from → Amazon S3 location**, dán S3 URI của object và giữ **Copy mode**.

![Code → Update from a file in Amazon S3](/images/workshop/runbook/img072.jpg)

![S3 link tới fitness-migrate-lambda.zip, copy mode](/images/workshop/runbook/img073.jpg)

![Code properties: package 70.8 MB nạp từ S3](/images/workshop/runbook/img074.jpg)

Trước khi invoke, kiểm tra lại VPC, handler, environment và role một lần nữa, rồi invoke function với `{}`. Sau khi toàn bộ 48 migration được áp dụng, migration Lambda tạm thời được xoá — có thể thấy banner xanh "Successfully deleted function: fitness-assistant-dev-fitness-migrate" ở các screenshot tiếp theo.

#### Bước 4 — Upload artifact chính

Upload `fitness-lambda.zip` lên cùng bucket deployments.

![fitness-lambda.zip (53.3 MB) đã upload lên bucket deployments](/images/workshop/runbook/img076.jpg)

#### Bước 5 — Tạo runtime role

Tạo `fitness-assistant-dev-fitness-lambda-role` (AWS service → Lambda, cùng hai managed policy).

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img077.jpg)

![Managed policy gắn vào role](/images/workshop/runbook/img078.jpg)

![Tên role fitness-assistant-dev-fitness-lambda-role và trust policy](/images/workshop/runbook/img079.jpg)

Thêm hai inline policy: `fitness-assistant-dev-fitness-database-secret` (cùng statement secret như ở Bước 2) và `fitness-assistant-dev-fitness-service-invoke`:

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

![Create inline policy trên runtime role](/images/workshop/runbook/img080.jpg)

![Inline policy cho secret database của Fitness](/images/workshop/runbook/img081.jpg)

Không thêm quyền S3, SQS, Bedrock hay Redis — Fitness Service không dùng chúng trên AWS.

#### Bước 6 — Tạo Fitness Lambda

**Lambda → Create function**: `fitness-assistant-dev-fitness`, Node.js 22.x, x86_64, role `fitness-assistant-dev-fitness-lambda-role`; 1024 MB, 30 giây; handler `dist/lambda.handler`; code từ `s3://fitness-assistant-deployments-dev-<account-id>/fitness-lambda.zip` (copy mode).

![Create function fitness-assistant-dev-fitness](/images/workshop/runbook/img085.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img082.jpg)

| Biến | Giá trị |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `FITNESS_DISABLE_REDIS` | `true` |
| `INTERNAL_SERVICE_SECRET` | giá trị dùng chung với Auth/User |

![Environment variable của Fitness Lambda (secret đã che)](/images/workshop/runbook/img083.jpg)

`AI_SERVICE_URL`, `CHAT_SERVICE_URL`, `REDIS_HOST`, `REDIS_PORT` và `PEXELS_API_KEY` để trống vì các dependency đó chưa deploy hoặc chưa bật.

![Cấu hình VPC của Fitness Lambda](/images/workshop/runbook/img084.jpg)

#### Bước 7 — Nối Fitness Lambda vào API Gateway

Tạo Lambda integration `fitness-assistant-dev-fitness` (payload 2.0). Sau đó, với mỗi prefix public, tạo **cả** route gốc lẫn greedy route để `/workouts` và `/workouts/...` đều khớp:

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

![Lambda integration cho fitness-assistant-dev-fitness](/images/workshop/runbook/img086.jpg)

![Các route đã gắn vào Fitness integration](/images/workshop/runbook/img087.jpg)

#### Bước 8 — Tạo jobs Lambda

`fitness-assistant-dev-fitness-jobs`: cùng role, cùng `fitness-lambda.zip` từ S3, handler `dist/jobs-lambda.handler`, 1024 MB, 1 phút, cùng VPC và cùng environment variable với HTTP Lambda. Function này chạy hai job: `workout-upcoming-reminder` và `workout-unfinished-reminder`.

![Create function fitness-assistant-dev-fitness-jobs](/images/workshop/runbook/img088.jpg)

![Cấu hình VPC của jobs Lambda](/images/workshop/runbook/img089.jpg)

![Environment variable của jobs Lambda (secret đã che)](/images/workshop/runbook/img090.jpg)

#### Bước 9 — Tạo scheduler role

Custom trust policy cho `scheduler.amazonaws.com`, tên role `fitness-assistant-dev-fitness-jobs-scheduler-role`, inline policy `fitness-assistant-dev-invoke-fitness-jobs` cho phép `lambda:InvokeFunction` chỉ trên jobs Lambda.

![Custom trust policy cho EventBridge Scheduler](/images/workshop/runbook/img091.jpg)

![Tên role fitness-assistant-dev-fitness-jobs-scheduler-role](/images/workshop/runbook/img092.jpg)

![Inline policy giới hạn trong fitness-assistant-dev-fitness-jobs](/images/workshop/runbook/img093.jpg)

![Tên policy fitness-assistant-dev-invoke-fitness-jobs](/images/workshop/runbook/img094.jpg)

#### Bước 10 — Tạo hai schedule nhắc lịch

| Schedule | Tần suất | Payload | Tác dụng |
|---|---|---|---|
| `fitness-assistant-dev-workout-upcoming-reminder` | `rate(30 minutes)` | `{"job": "workout-upcoming-reminder"}` | Quét các workout `NOT_STARTED` hôm nay chưa được nhắc |
| `fitness-assistant-dev-workout-unfinished-reminder` | `rate(30 minutes)` | `{"job": "workout-unfinished-reminder"}` | Nhắc các workout `IN_PROGRESS` đã bắt đầu ít nhất 3 giờ |

Cả hai dùng time zone `Asia/Saigon`, tắt flexible window, state enabled, action NONE, retry (5 phút / 2 lần), không DLQ, key do AWS sở hữu và scheduler role có sẵn.

![Schedule fitness-assistant-dev-workout-upcoming-reminder: recurring, rate-based, Asia/Saigon](/images/workshop/runbook/img095.jpg)

![rate(30 minutes), tắt flexible window](/images/workshop/runbook/img096.jpg)

![Target: AWS Lambda Invoke](/images/workshop/runbook/img097.jpg)

![Payload {"job": "workout-upcoming-reminder"}](/images/workshop/runbook/img098.jpg)

![Retry: maximum age 5 phút, 2 lần, không DLQ](/images/workshop/runbook/img099.jpg)

![Settings với scheduler role có sẵn](/images/workshop/runbook/img100.jpg)

![Schedule thứ hai fitness-assistant-dev-workout-unfinished-reminder](/images/workshop/runbook/img101.jpg)

![Payload {"job": "workout-unfinished-reminder"}](/images/workshop/runbook/img102.jpg)

![Settings của schedule thứ hai](/images/workshop/runbook/img103.jpg)

{{% notice note %}}
Nhắc workout sắp tới hiện chỉ có độ chi tiết theo ngày: schema hiện tại không lưu giờ tập dự kiến, nên job không thể gửi kiểu "còn 30 phút nữa tới buổi tập". Nó nhắc các workout lên lịch hôm nay mà chưa được nhắc.
{{% /notice %}}
