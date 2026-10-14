---
title: "5.4.6 Gym Service"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.4.6. </b> "
---

Gym Service xử lý phòng gym, danh sách PT, công cụ cho chủ phòng và admin, hợp tác và QR check-in. Đây là service đầu tiên có thêm một secret riêng: key ký mã QR check-in.

| Mục | Giá trị |
|---|---|
| Logical database | `fitness_assistant_gym` (9 Prisma migration) |
| Secret | `fitness-assistant/dev/gym-database` |
| Function | `fitness-assistant-dev-gym`, `fitness-assistant-dev-gym-jobs` |
| Gọi tới | Auth, User và (sau [5.4.7](../5.4.7-Payment-Service/)) Payment Lambda |

#### Bước 1 — Tạo database secret

Cùng cấu trúc với các service khác, với `database = fitness_assistant_gym`.

![Secret fitness-assistant/dev/gym-database (mật khẩu đã che)](/images/workshop/runbook/img104.jpg)

#### Bước 2 — Upload artifact

Upload `gym-migrate-lambda.zip` (~69 MiB, nên bắt buộc dùng S3) và `gym-lambda.zip` (~36 MiB — đủ nhỏ để upload trực tiếp, nhưng vẫn dùng S3 cho đồng nhất) lên `fitness-assistant-deployments-dev-<account-id>`.

![Upload gym-lambda.zip (36 MB) lên bucket deployments](/images/workshop/runbook/img105.jpg)

![Upload thành công](/images/workshop/runbook/img106.jpg)

{{% notice warning %}}
Ở thời điểm này của runbook, bước migration của Gym bị bỏ qua dù service có 9 migration: Lambda và route vẫn deploy được, nhưng mọi route chạm database sẽ lỗi cho tới khi `fitness_assistant_gym` có schema. Migration sau đó được chạy bằng function `fitness-assistant-dev-gym-migrate` theo [khuôn mẫu chung](../#common-pattern) — function này có trong danh sách function ở [5.4.10](../5.4.10-Chat-Service-ECS/) — và bảng trạng thái triển khai ghi nhận migration của Gym đã hoàn tất.
{{% /notice %}}

#### Bước 3 — Tạo runtime role

`fitness-assistant-dev-gym-lambda-role` (AWS service → Lambda, hai managed policy), với hai inline policy:

- `fitness-assistant-dev-gym-database-secret` — `secretsmanager:GetSecretValue` / `DescribeSecret` trên `fitness-assistant/dev/gym-database*`.
- `fitness-assistant-dev-gym-service-invoke` — `lambda:InvokeFunction` trên `fitness-assistant-dev-auth` và `fitness-assistant-dev-user`.

![Inline policy cho secret database của Gym](/images/workshop/runbook/img107.jpg)

![Inline policy cho phép invoke Auth và User Lambda](/images/workshop/runbook/img108.jpg)

![Hai inline policy đã gắn vào role](/images/workshop/runbook/img109.jpg)

Payment cố ý chưa có trong danh sách invoke — sẽ được thêm ở [5.4.7](../5.4.7-Payment-Service/#gym-to-payment) khi Payment Lambda đã tồn tại.

#### Bước 4 — Tạo Gym Lambda

`fitness-assistant-dev-gym`, Node.js 22.x, x86_64, role `fitness-assistant-dev-gym-lambda-role`, 1024 MB, 30 giây, handler `dist/lambda.handler`, code từ `s3://fitness-assistant-deployments-dev-<account-id>/gym-lambda.zip` (copy mode).

![Create function fitness-assistant-dev-gym](/images/workshop/runbook/img110.jpg)

![Memory 1024 MB, timeout 30 giây](/images/workshop/runbook/img111.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img112.jpg)

![Code từ gym-lambda.zip trên S3, copy mode](/images/workshop/runbook/img113.jpg)

#### Bước 5 — Environment variable

| Biến | Giá trị |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/gym-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `INTERNAL_SERVICE_SECRET` | giá trị service-to-service dùng chung |
| `CHECKIN_TOKEN_SECRET` | một giá trị ngẫu nhiên mạnh, mới |

![Environment variable của Gym Lambda (cả hai secret đã che)](/images/workshop/runbook/img114.jpg)

`CHECKIN_TOKEN_SECRET` phải khác `INTERNAL_SERVICE_SECRET`: nó ký mã QR hiển thị cho thành viên phòng gym, nên lộ một cái không được kéo theo lộ cái kia. `PAYMENT_LAMBDA_NAME` và `FITNESS_LAMBDA_NAME` chưa đặt.

![Cấu hình VPC của Gym Lambda](/images/workshop/runbook/img115.jpg)

#### Bước 6 — Nối Gym Lambda vào API Gateway

Tạo Lambda integration `fitness-assistant-dev-gym` (payload 2.0), sau đó tạo cặp route gốc + greedy route cho mỗi prefix:

```
ANY /gyms             ANY /gyms/{proxy+}
ANY /pt               ANY /pt/{proxy+}
ANY /me               ANY /me/{proxy+}
ANY /owner            ANY /owner/{proxy+}
ANY /admin            ANY /admin/{proxy+}
ANY /collaborations   ANY /collaborations/{proxy+}
```

![Lambda integration cho fitness-assistant-dev-gym](/images/workshop/runbook/img116.jpg)

![Route của Gym đã gắn vào integration](/images/workshop/runbook/img117.jpg)

{{% notice note %}}
`/me`, `/admin` và `/pt` có thể đã tồn tại từ User Service. HTTP API không thể route cùng method và path tới hai integration, nên khi console báo route đã tồn tại thì **không** ghi đè — xung đột được giải quyết bằng cách kiểm tra code của service nào thực sự sở hữu path đó. Payment Service về sau tránh hẳn vấn đề này bằng các prefix cụ thể hơn như `/me/wallet`.
{{% /notice %}}

API lúc này route:

```
fitness-assistant-dev-api
├── /auth/*          → Auth Lambda
├── User routes      → User Lambda
├── Fitness routes   → Fitness Lambda
└── Gym routes       → Gym Lambda ──► Auth / User Lambda, Aurora (fitness_assistant_gym)
```

#### Bước 7 — Tạo jobs Lambda

`fitness-assistant-dev-gym-jobs`: cùng role và artifact, handler `dist/jobs-lambda.handler`, 1024 MB, 1 phút, cùng VPC và environment variable (bao gồm `CHECKIN_TOKEN_SECRET`).

![Create function fitness-assistant-dev-gym-jobs](/images/workshop/runbook/img118.jpg)

![Memory 1024 MB, timeout 1 phút](/images/workshop/runbook/img119.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img120.jpg)

![Cùng gym-lambda.zip từ S3](/images/workshop/runbook/img121.jpg)

![Cấu hình VPC của jobs Lambda](/images/workshop/runbook/img122.jpg)

#### Bước 8 — Scheduler role và schedule

Tạo `fitness-assistant-dev-gym-jobs-scheduler-role` (trust `scheduler.amazonaws.com`) với inline policy `fitness-assistant-dev-invoke-gym-jobs` cho phép `lambda:InvokeFunction` chỉ trên Gym jobs Lambda, rồi tạo hai schedule:

| Schedule | Tần suất | Payload |
|---|---|---|
| `fitness-assistant-dev-gym-membership-payout` | `rate(10 minutes)` | `{"job":"membership-payout-sweep"}` |
| `fitness-assistant-dev-gym-referral-settlement` | `rate(10 minutes)` | `{"job":"referral-settlement-sweep"}` |

Cả hai: tắt flexible window, enabled, maximum event age 5 phút, 2 lần thử lại, không DLQ, key do AWS sở hữu, dùng scheduler role có sẵn. Cả hai job đều cần Payment Service, đó là lý do Gym jobs Lambda cũng nhận `PAYMENT_LAMBDA_NAME` ở trang tiếp theo.
