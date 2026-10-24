---
title: "Payment Service"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.4.7. </b> "
---

Payment Service xử lý nạp ví, thanh toán hợp đồng PT, rút tiền và webhook của provider. Các endpoint nội bộ nhạy cảm (checkout, chuyển tiền ví, giải ngân hợp đồng, no-show, chấm dứt hợp đồng, rút tiền của gym) chỉ truy cập được qua direct Lambda invoke từ Gym, User và AI — không bao giờ qua API public.

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của bước nhỏ được viết ngay phía trên ảnh.

| Mục | Giá trị |
|---|---|
| Logical database | `fitness_assistant_payment` (11 Prisma migration) |
| Secret | `fitness-assistant/dev/payment-database` |
| Function | `fitness-assistant-dev-payment`, `fitness-assistant-dev-payment-jobs`, `fitness-assistant-dev-payment-migrate` tạm thời |
| Provider | `PAYMENT_PROVIDER=VNPAY` (code hỗ trợ MoMo, PayOS, ZaloPay) |

Với database của Payment, cluster Aurora có cấu trúc:

```
fitness-assistant-dev-aurora
├── fitness_assistant          → Auth
├── fitness_assistant_user     → User
├── fitness_assistant_fitness  → Fitness
├── fitness_assistant_gym      → Gym
└── fitness_assistant_payment  → Payment
```

#### Bước 1 — Secret và artifact

**1.1 — Tạo secret.** Trong **Secrets Manager → Store a new secret** chọn **Other type of secret**, nhập năm cặp giống các service khác với `database` = `fitness_assistant_payment`, đặt tên `fitness-assistant/dev/payment-database`.

*Runbook không có ảnh của thao tác này; form giống [5.4.6 Bước 1](../5.4.6-Gym-Service/).*

**1.2 — Upload hai file zip.** Trong bucket deployments bấm **Upload**, thêm `payment-lambda.zip` (36 MB) và `payment-migrate-lambda.zip` (~69 MiB, nên bắt buộc dùng S3), rồi bắt đầu upload. Ảnh cho thấy cả hai file trong danh sách (tổng 105.1 MB).

![payment-lambda.zip và payment-migrate-lambda.zip đang upload](/images/workshop/runbook/img123.jpg)

#### Bước 2 — Migration role

**2.1 — Tạo role.** **IAM → Roles → Create role**, chọn **AWS service → Lambda**, gắn `AWSLambdaBasicExecutionRole` và `AWSLambdaVPCAccessExecutionRole`, đặt tên `fitness-assistant-dev-payment-migrate-role`.

![Role mới với hai managed policy](/images/workshop/runbook/img124.jpg)

**2.2 — Viết policy cho secret.** Trên role mở **Add permissions → Create inline policy**, chuyển sang **JSON** và cho phép `secretsmanager:GetSecretValue` / `DescribeSecret` chỉ trên `fitness-assistant/dev/payment-database*`.

![JSON editor với statement cho secret của Payment](/images/workshop/runbook/img125.jpg)

**2.3 — Đặt tên và tạo policy.** Nhập tên `fitness-assistant-dev-payment-migration-secret` và bấm **Create policy**.

![Tên policy và nút Create policy](/images/workshop/runbook/img126.jpg)

#### Bước 3 — Migration Lambda

**3.1 — Điền thông tin function.** **Lambda → Create function**, giữ **Author from scratch**, tên `fitness-assistant-dev-payment-migrate`, runtime **Node.js 22.x**, custom execution role `fitness-assistant-dev-payment-migrate-role`, rồi **Create function**.

![Author from scratch, tên, runtime và migrate role](/images/workshop/runbook/img127.jpg)

**3.2 — Đặt memory và timeout.** **Configuration → General configuration → Edit**: **Memory** `1024` MB, **Timeout** `15` phút `0` giây, **Save**.

![Memory 1024 MB, timeout 15 phút, Save](/images/workshop/runbook/img128.jpg)

**3.3 — Đặt handler.** **Code → Runtime settings → Edit**: `dist/migrate-lambda.handler`, **Save**.

![Handler dist/migrate-lambda.handler và Save](/images/workshop/runbook/img129.jpg)

**3.4 — Thêm environment variable.** **Configuration → Environment variables → Edit**: key `DATABASE_SECRET_ID`, value `fitness-assistant/dev/payment-database`, **Save**.

![DATABASE_SECRET_ID cho database Payment và Save](/images/workshop/runbook/img130.jpg)

**3.5 — Gắn VPC.** **Configuration → VPC → Edit**: VPC của dự án, cả hai private app subnet và `fitness-assistant-dev-lambda-sg`, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img131.jpg)

**3.6 — Nạp code.** **Upload from → Amazon S3 location**: `s3://fitness-assistant-deployments-dev-<account-id>/payment-migrate-lambda.zip`, copy mode, **Update**.

*Runbook không có ảnh của thao tác này; hộp thoại giống [5.4.6 Bước 4.4](../5.4.6-Gym-Service/).*

#### Bước 4 — Chạy 11 migration

**4.1 — Invoke một lần.** Kiểm tra secret thật sự ghi `database = fitness_assistant_payment`, rồi mở tab **Test** và invoke function một lần với `{}`. Handler có safety guard chỉ chấp nhận đúng tên database này, tự tạo logical database nếu chưa có và chỉ chạy `prisma migrate deploy`.

![Tab Test: Executing function succeeded và JSON response](/images/workshop/runbook/img132.jpg)

**Kết quả mong đợi:** `database = fitness_assistant_payment`, `migrateExitCode = 0`, `11 migrations found`, `All migrations have been successfully applied.`

#### Bước 5 — Runtime role

**5.1 — Tạo role.** **IAM → Roles → Create role**, AWS service → Lambda, cùng hai managed policy, tên `fitness-assistant-dev-payment-lambda-role`.

![Role mới với hai managed policy](/images/workshop/runbook/img133.jpg)

**5.2 — Thêm hai inline policy.** `fitness-assistant-dev-payment-database-secret` cho secret của Payment, và `fitness-assistant-dev-payment-service-invoke`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-gym"
      ]
    }
  ]
}
```

![Role với hai managed policy và hai inline policy](/images/workshop/runbook/img134.jpg)

#### Bước 6 — Payment Lambda

**6.1 — Điền thông tin function.** **Lambda → Create function**, tên `fitness-assistant-dev-payment`, runtime **Node.js 22.x**, custom execution role `fitness-assistant-dev-payment-lambda-role`, **Create function**.

![Author from scratch, tên, runtime và Payment role](/images/workshop/runbook/img135.jpg)

**6.2 — Đặt memory và timeout.** **Memory** `1024` MB, **Timeout** `0` phút `30` giây, **Save**.

![Memory 1024 MB, timeout 30 giây, Save](/images/workshop/runbook/img136.jpg)

**6.3 — Đặt handler.** `dist/lambda.handler`, **Save**.

![Handler dist/lambda.handler và Save](/images/workshop/runbook/img137.jpg)

**6.4 — Nạp code.** **Upload from → Amazon S3 location**: `s3://fitness-assistant-deployments-dev-<account-id>/payment-lambda.zip`, copy mode, **Update**.

![Link S3 tới payment-lambda.zip và Update](/images/workshop/runbook/img138.jpg)

**6.5 — Gắn VPC.** Cùng VPC, subnet và security group với các Lambda dùng database khác, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img139.jpg)

**6.6 — Thêm environment variable.**

| Biến | Giá trị |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/payment-database` |
| `INTERNAL_SERVICE_SECRET` | giá trị dùng chung |
| `AUTH_LAMBDA_NAME` / `USER_LAMBDA_NAME` / `GYM_LAMBDA_NAME` | tên ba function tương ứng |
| `PAYMENT_PROVIDER` | `VNPAY` |
| `VNPAY_SIMULATE` | `false` |
| `FRONTEND_URL` | S3 website endpoint |
| `PAYMENT_PUBLIC_URL` | invoke URL của API Gateway (dùng để tạo callback URL cho provider) |

Credential của provider (`VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`, key MoMo / PayOS / ZaloPay) chỉ được thêm khi có credential sandbox thật.

*Runbook không có ảnh của form environment variable cho function này.*

#### Bước 7 — Route trên API Gateway

**7.1 — Tạo integration.** **API Gateway → fitness-assistant-dev-api → Integrations → Create**: Lambda function `fitness-assistant-dev-payment`, payload `2.0`.

*Runbook không có ảnh của thao tác này; form giống [5.4.6 Bước 6.1](../5.4.6-Gym-Service/).*

**7.2 — Tạo route.** `ANY /me` và `ANY /admin` đã thuộc service khác, nên Payment dùng prefix cụ thể:

| Nhóm | Route |
|---|---|
| Thanh toán public và webhook của provider | `ANY /payments`, `ANY /payments/{proxy+}` — bao phủ `GET /payments/webhook/vnpay`, `POST /payments/webhook/{provider}`, `GET /payments/vnpay/return` |
| Người dùng | `ANY /me/payments`, `/me/wallet`, `/me/pt-wallet`, `/me/withdrawals` — mỗi cái kèm route `/{proxy+}` |
| Admin | `ANY /admin/payments`, `ANY /admin/payments/{proxy+}` |

Không bao giờ tạo `/internal` và `/internal/{proxy+}`.

**7.3 — Kiểm tra việc gắn route.** Mở **Integrations → Attach integrations to routes**, chọn từng route của Payment và xác nhận nó trỏ tới `fitness-assistant-dev-payment` — route chưa có integration sẽ trả `Not Found`.

![Route ANY /payments/{proxy+} hiện Lambda function fitness-assistant-dev-payment](/images/workshop/runbook/img140.jpg)

#### Bước 8 — Jobs Lambda và schedule reconciliation

`fitness-assistant-dev-payment-jobs` dùng cùng role, artifact, VPC và environment với HTTP Lambda.

**8.1 — Điền thông tin function.** **Lambda → Create function**, tên `fitness-assistant-dev-payment-jobs`, runtime **Node.js 22.x**, role `fitness-assistant-dev-payment-lambda-role`, **Create function**.

![Author from scratch, tên payment-jobs, runtime và Payment role](/images/workshop/runbook/img141.jpg)

**8.2 — Đặt handler.** `dist/jobs-lambda.handler`, **Save**.

![Handler dist/jobs-lambda.handler và Save](/images/workshop/runbook/img142.jpg)

**8.3 — Đặt memory và timeout.** **Memory** `1024` MB, **Timeout** `1` phút `0` giây, **Save**.

![Memory 1024 MB, timeout 1 phút, Save](/images/workshop/runbook/img143.jpg)

**8.4 — Gắn VPC.** Cùng VPC, subnet và security group, **Save**. Nạp cùng code `payment-lambda.zip` và sao chép các environment variable.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img144.jpg)

**8.5 — Tạo scheduler role.** `fitness-assistant-dev-payment-jobs-scheduler-role` (trust `scheduler.amazonaws.com`, inline policy `fitness-assistant-dev-invoke-payment-jobs` chỉ cho Payment jobs Lambda).

*Runbook không có ảnh của thao tác này.*

**8.6 — Đặt tên schedule.** **EventBridge → Schedules → Create schedule**: tên `fitness-assistant-dev-payment-reconciliation`, **Recurring schedule**, **Rate-based schedule**, rate `5` `minutes`.

![Tên schedule, Recurring schedule, Rate-based, rate 5 phút](/images/workshop/runbook/img145.jpg)

**8.7 — Chọn target.** Chọn ô **AWS Lambda — Invoke**, chọn `fitness-assistant-dev-payment-jobs` và nhập payload `{"job": "reconciliation"}`.

![AWS Lambda Invoke, function payment-jobs và payload reconciliation](/images/workshop/runbook/img146.jpg)

**8.8 — Chọn settings.** Giữ retry bật với maximum age `0` giờ `5` phút và `2` lần thử, DLQ **None**, key do AWS sở hữu, và **Use existing role** với `fitness-assistant-dev-payment-jobs-scheduler-role`. Rồi bấm **Next** và tạo schedule.

![Retry 5 phút / 2 lần, DLQ None, scheduler role có sẵn, Next](/images/workshop/runbook/img147.jpg)

{{% notice note %}}
Banner ở đầu ba ảnh cuối vẫn nêu schedule Gym tạo trước đó (`fitness-assistant-dev-gym-referral-settlement`); bản thân form là của schedule reconciliation của Payment.
{{% /notice %}}

Mỗi 5 phút, job reconciliation poll gateway để xác nhận các giao dịch đang chờ, thử lại kích hoạt và huỷ hoàn tiền, và dọn các giao dịch treo.

#### Bước 9 — Nối Gym với Payment {#gym-to-payment}

Gym được deploy trước khi Payment tồn tại, nên cần được "báo" về Payment:

**9.1 — Thêm biến vào cả hai function Gym.** Thêm `PAYMENT_LAMBDA_NAME=fitness-assistant-dev-payment` vào **cả** `fitness-assistant-dev-gym` và `fitness-assistant-dev-gym-jobs` (payout và referral settlement cũng gọi Payment). Không cần `PAYMENT_SERVICE_URL` khi dùng direct invoke.

**9.2 — Mở rộng invoke policy của Gym role** (hoặc thêm `fitness-assistant-dev-gym-invoke-payment`):

```json
{
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": [
    "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
    "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user",
    "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-payment"
  ]
}
```

*Runbook không có ảnh của Bước 9.*

Gym scheduler role không cần quyền này — scheduler chỉ invoke `gym-jobs`, và chính `gym-jobs` mới gọi Payment.

Vòng thanh toán giờ đã khép kín:

```
Gym Lambda ──direct invoke──► Payment Lambda ──► Payment DB ──► Provider (VNPAY)
                                                                   │ webhook
Gym Lambda ◄──callback── Payment Lambda ◄── API Gateway /payments ◄┘
```

Việc còn lại của service này là cấu hình ít nhất một provider sandbox thật (VNPAY trước, vì là mặc định trong code) cùng callback/webhook URL, để kiểm thử checkout end-to-end.
