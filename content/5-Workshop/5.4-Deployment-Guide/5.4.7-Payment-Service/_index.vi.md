---
title: "5.4.7 Payment Service"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.4.7. </b> "
---

Payment Service xử lý nạp ví, thanh toán hợp đồng PT, rút tiền và webhook của provider. Các endpoint nội bộ nhạy cảm (checkout, chuyển tiền ví, giải ngân hợp đồng, no-show, chấm dứt hợp đồng, rút tiền của gym) chỉ truy cập được qua direct Lambda invoke từ Gym, User và AI — không bao giờ qua API public.

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

Tạo `fitness-assistant/dev/payment-database` (`database = fitness_assistant_payment`), sau đó upload `payment-migrate-lambda.zip` (~69 MiB) và `payment-lambda.zip` lên bucket deployments.

![Upload payment-lambda.zip và payment-migrate-lambda.zip (105.1 MB)](/images/workshop/runbook/img123.jpg)

#### Bước 2 — Migration role

`fitness-assistant-dev-payment-migrate-role` với hai managed policy và inline policy `fitness-assistant-dev-payment-migration-secret` chỉ cho `fitness-assistant/dev/payment-database*`.

![Role fitness-assistant-dev-payment-migrate-role](/images/workshop/runbook/img124.jpg)

![Inline policy cho secret database của Payment](/images/workshop/runbook/img125.jpg)

![Tên policy fitness-assistant-dev-payment-migration-secret](/images/workshop/runbook/img126.jpg)

#### Bước 3 — Migration Lambda

`fitness-assistant-dev-payment-migrate`: 1024 MB, 15 phút, handler `dist/migrate-lambda.handler`, `DATABASE_SECRET_ID=fitness-assistant/dev/payment-database`, hai private app subnet + Lambda SG, code từ S3 ở copy mode.

![Create function fitness-assistant-dev-payment-migrate](/images/workshop/runbook/img127.jpg)

![Memory 1024 MB, timeout 15 phút](/images/workshop/runbook/img128.jpg)

![Handler dist/migrate-lambda.handler](/images/workshop/runbook/img129.jpg)

![DATABASE_SECRET_ID cho database Payment](/images/workshop/runbook/img130.jpg)

![Cấu hình VPC](/images/workshop/runbook/img131.jpg)

#### Bước 4 — Chạy 11 migration

Kiểm tra secret thật sự ghi `database = fitness_assistant_payment`, rồi invoke function một lần với `{}`. Handler có safety guard chỉ chấp nhận đúng tên database này, tự tạo logical database nếu chưa có và chỉ chạy `prisma migrate deploy`.

**Kết quả mong đợi:** `database = fitness_assistant_payment`, `migrateExitCode = 0`, `11 migrations found`, `All migrations have been successfully applied.`

![Kết quả migration: status ok, fitness_assistant_payment, migration đã áp dụng](/images/workshop/runbook/img132.jpg)

#### Bước 5 — Runtime role

`fitness-assistant-dev-payment-lambda-role` với hai managed policy cộng:

- `fitness-assistant-dev-payment-database-secret` cho secret của Payment;
- `fitness-assistant-dev-payment-service-invoke`:

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

![Role fitness-assistant-dev-payment-lambda-role](/images/workshop/runbook/img133.jpg)

![Role với hai managed policy và hai inline policy](/images/workshop/runbook/img134.jpg)

#### Bước 6 — Payment Lambda

`fitness-assistant-dev-payment`, 1024 MB, 30 giây, handler `dist/lambda.handler`, code `s3://fitness-assistant-deployments-dev-<account-id>/payment-lambda.zip`, cùng VPC với các Lambda dùng database khác.

![Create function fitness-assistant-dev-payment](/images/workshop/runbook/img135.jpg)

![Memory 1024 MB, timeout 30 giây](/images/workshop/runbook/img136.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img137.jpg)

![Code từ payment-lambda.zip trên S3](/images/workshop/runbook/img138.jpg)

![Cấu hình VPC của Payment Lambda](/images/workshop/runbook/img139.jpg)

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

#### Bước 7 — Route trên API Gateway

Tạo Lambda integration `fitness-assistant-dev-payment` (payload 2.0). `ANY /me` và `ANY /admin` đã thuộc service khác, nên Payment dùng prefix cụ thể:

| Nhóm | Route |
|---|---|
| Thanh toán public và webhook của provider | `ANY /payments`, `ANY /payments/{proxy+}` — bao phủ `GET /payments/webhook/vnpay`, `POST /payments/webhook/{provider}`, `GET /payments/vnpay/return` |
| Người dùng | `ANY /me/payments`, `/me/wallet`, `/me/pt-wallet`, `/me/withdrawals` — mỗi cái kèm route `/{proxy+}` |
| Admin | `ANY /admin/payments`, `ANY /admin/payments/{proxy+}` |

Không bao giờ tạo `/internal` và `/internal/{proxy+}`. Sau đó mở **Integrations → Attach integrations to routes** và xác nhận mọi route của Payment trỏ tới `fitness-assistant-dev-payment` — route chưa có integration sẽ trả `Not Found`.

![Route của Payment đã gắn vào Payment integration](/images/workshop/runbook/img140.jpg)

#### Bước 8 — Jobs Lambda và schedule reconciliation

`fitness-assistant-dev-payment-jobs`: cùng role, artifact, VPC và environment với HTTP Lambda, handler `dist/jobs-lambda.handler`, 1024 MB, 1 phút.

![Create function fitness-assistant-dev-payment-jobs](/images/workshop/runbook/img141.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img142.jpg)

![Memory 1024 MB, timeout 1 phút](/images/workshop/runbook/img143.jpg)

![Cấu hình VPC của jobs Lambda](/images/workshop/runbook/img144.jpg)

Tạo `fitness-assistant-dev-payment-jobs-scheduler-role` (trust `scheduler.amazonaws.com`, inline policy `fitness-assistant-dev-invoke-payment-jobs` chỉ cho Payment jobs Lambda), rồi tạo schedule `fitness-assistant-dev-payment-reconciliation`: `rate(5 minutes)`, payload `{"job": "reconciliation"}`, enabled, 5 phút / 2 lần thử, không DLQ, key do AWS sở hữu.

![Schedule fitness-assistant-dev-payment-reconciliation với rate(5 minutes)](/images/workshop/runbook/img145.jpg)

![Target fitness-assistant-dev-payment-jobs với payload {"job": "reconciliation"}](/images/workshop/runbook/img146.jpg)

![Settings với scheduler role của Payment](/images/workshop/runbook/img147.jpg)

Mỗi 5 phút, job reconciliation poll gateway để xác nhận các giao dịch đang chờ, thử lại kích hoạt và huỷ hoàn tiền, và dọn các giao dịch treo.

#### Bước 9 — Nối Gym với Payment {#gym-to-payment}

Gym được deploy trước khi Payment tồn tại, nên cần được "báo" về Payment:

1. Thêm `PAYMENT_LAMBDA_NAME=fitness-assistant-dev-payment` vào **cả** `fitness-assistant-dev-gym` và `fitness-assistant-dev-gym-jobs` (payout và referral settlement cũng gọi Payment). Không cần `PAYMENT_SERVICE_URL` khi dùng direct invoke.
2. Mở rộng invoke policy của Gym role (hoặc thêm `fitness-assistant-dev-gym-invoke-payment`):

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

Gym scheduler role không cần quyền này — scheduler chỉ invoke `gym-jobs`, và chính `gym-jobs` mới gọi Payment.

Vòng thanh toán giờ đã khép kín:

```
Gym Lambda ──direct invoke──► Payment Lambda ──► Payment DB ──► Provider (VNPAY)
                                                                   │ webhook
Gym Lambda ◄──callback── Payment Lambda ◄── API Gateway /payments ◄┘
```

Việc còn lại của service này là cấu hình ít nhất một provider sandbox thật (VNPAY trước, vì là mặc định trong code) cùng callback/webhook URL, để kiểm thử checkout end-to-end.
