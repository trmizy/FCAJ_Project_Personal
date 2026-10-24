---
title: "Gym Service"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.4.6. </b> "
---

Gym Service xử lý phòng gym, danh sách PT, công cụ cho chủ phòng và admin, hợp tác và QR check-in. Đây là service đầu tiên có thêm một secret riêng: key ký mã QR check-in.

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của bước nhỏ được viết ngay phía trên ảnh.

| Mục | Giá trị |
|---|---|
| Logical database | `fitness_assistant_gym` (9 Prisma migration) |
| Secret | `fitness-assistant/dev/gym-database` |
| Function | `fitness-assistant-dev-gym`, `fitness-assistant-dev-gym-jobs` |
| Gọi tới | Auth, User và (sau [5.4.7](../5.4.7-Payment-Service/)) Payment Lambda |

#### Bước 1 — Tạo database secret

**1.1 — Chọn loại secret và nhập các cặp.** Mở **Secrets Manager → Store a new secret**, chọn **Other type of secret**, rồi thêm năm dòng key/value giống các service khác: `username`, `password`, `host`, `port` và `database` = `fitness_assistant_gym`. Bấm **Next** và lưu secret với tên `fitness-assistant/dev/gym-database`.

![Other type of secret, năm dòng key/value, nút Next (mật khẩu đã che)](/images/workshop/runbook/img104.jpg)

*Runbook không có ảnh của bước đặt tên cuối cùng và bấm **Store**.*

#### Bước 2 — Upload artifact

**2.1 — Upload `gym-lambda.zip`.** Mở bucket S3 `fitness-assistant-deployments-dev-<account-id>`, bấm **Upload**, thêm `gym-lambda.zip` (~36 MiB — đủ nhỏ để upload trực tiếp, nhưng vẫn dùng S3 cho đồng nhất) rồi bấm **Upload**. `gym-migrate-lambda.zip` (~69 MiB) cũng phải đi qua S3 theo cách tương tự.

![gym-lambda.zip trong danh sách file và nút Upload](/images/workshop/runbook/img105.jpg)

**2.2 — Kiểm tra kết quả.** Trang trạng thái phải hiện **Succeeded** cạnh file. Bấm **Close**.

![Trạng thái Succeeded và nút Close](/images/workshop/runbook/img106.jpg)

{{% notice warning %}}
Ở thời điểm này của runbook, bước migration của Gym bị bỏ qua dù service có 9 migration: Lambda và route vẫn deploy được, nhưng mọi route chạm database sẽ lỗi cho tới khi `fitness_assistant_gym` có schema. Migration sau đó được chạy bằng function `fitness-assistant-dev-gym-migrate` theo [khuôn mẫu chung](../#common-pattern) — function này có trong danh sách function ở [5.4.10](../5.4.10-Chat-Service-ECS/) — và bảng trạng thái triển khai ghi nhận migration của Gym đã hoàn tất.
{{% /notice %}}

#### Bước 3 — Tạo runtime role

**3.1 — Tạo role.** Trong **IAM → Roles → Create role**, chọn **AWS service → Lambda**, gắn hai managed policy và đặt tên `fitness-assistant-dev-gym-lambda-role`.

*Runbook không có ảnh của thao tác này.*

**3.2 — Thêm policy cho secret.** Trên role, mở **Add permissions → Create inline policy**, chuyển sang **JSON** và dán policy bên dưới. Đặt tên `fitness-assistant-dev-gym-database-secret`.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
    "Resource": "arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/gym-database*"
  }]
}
```

![JSON editor với statement GetSecretValue / DescribeSecret](/images/workshop/runbook/img107.jpg)

**3.3 — Thêm policy invoke.** Tạo inline policy thứ hai theo cách tương tự, tên `fitness-assistant-dev-gym-service-invoke`, cho phép `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-auth` và `fitness-assistant-dev-user`.

![JSON editor với statement lambda:InvokeFunction cho Auth và User](/images/workshop/runbook/img108.jpg)

**3.4 — Kiểm tra role.** Cả hai inline policy phải xuất hiện trong danh sách của role.

![Hai inline policy trong danh sách của role](/images/workshop/runbook/img109.jpg)

Payment cố ý chưa có trong danh sách invoke — sẽ được thêm ở [5.4.7](../5.4.7-Payment-Service/#gym-to-payment) khi Payment Lambda đã tồn tại.

#### Bước 4 — Tạo Gym Lambda

**4.1 — Điền thông tin function.** Mở **Lambda → Create function**, giữ **Author from scratch**, đặt tên `fitness-assistant-dev-gym`, runtime **Node.js 22.x** (x86_64). Ở **Additional settings → Custom execution role** chọn `fitness-assistant-dev-gym-lambda-role`, rồi bấm **Create function**.

![Author from scratch, tên, runtime Node.js 22.x và role có sẵn](/images/workshop/runbook/img110.jpg)

**4.2 — Đặt memory và timeout.** Mở **Configuration → General configuration → Edit**, đặt **Memory** `1024` MB và **Timeout** `0` phút `30` giây, rồi bấm **Save**.

![Memory 1024 MB, timeout 0 phút 30 giây, Save](/images/workshop/runbook/img111.jpg)

**4.3 — Đặt handler.** Mở **Code → Runtime settings → Edit**, nhập `dist/lambda.handler` và bấm **Save**.

![Handler dist/lambda.handler và Save](/images/workshop/runbook/img112.jpg)

**4.4 — Nạp code.** Mở **Upload from → Amazon S3 location**, giữ **Copy mode**, dán `s3://fitness-assistant-deployments-dev-<account-id>/gym-lambda.zip` và bấm **Update**.

![Link S3 tới gym-lambda.zip và Update](/images/workshop/runbook/img113.jpg)

#### Bước 5 — Environment variable và VPC

**5.1 — Thêm biến.** Mở **Configuration → Environment variables → Edit** và thêm:

| Biến | Giá trị |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/gym-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `INTERNAL_SERVICE_SECRET` | giá trị service-to-service dùng chung |
| `CHECKIN_TOKEN_SECRET` | một giá trị ngẫu nhiên mạnh, mới |

![Sáu biến trong danh sách, nút Edit (cả hai secret đã che)](/images/workshop/runbook/img114.jpg)

`CHECKIN_TOKEN_SECRET` phải khác `INTERNAL_SERVICE_SECRET`: nó ký mã QR hiển thị cho thành viên phòng gym, nên lộ một cái không được kéo theo lộ cái kia. `PAYMENT_LAMBDA_NAME` và `FITNESS_LAMBDA_NAME` chưa đặt.

**5.2 — Gắn VPC.** Mở **Configuration → VPC → Edit**, chọn VPC của dự án (`10.0.0.0/16`), chọn cả hai private app subnet (`private-app-a`, `private-app-b`) và security group `fitness-assistant-dev-lambda-sg`, rồi bấm **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img115.jpg)

#### Bước 6 — Nối Gym Lambda vào API Gateway

**6.1 — Tạo integration.** Trong **API Gateway → fitness-assistant-dev-api → Integrations → Create**, chọn **Lambda function**, region `ap-southeast-1`, chọn `fitness-assistant-dev-gym` và giữ payload format `2.0`.

![Integration type Lambda function và Gym Lambda đã chọn](/images/workshop/runbook/img116.jpg)

**6.2 — Gắn route.** Tạo cặp route gốc + greedy cho mỗi prefix và gắn từng route vào integration này:

```
ANY /gyms             ANY /gyms/{proxy+}
ANY /pt               ANY /pt/{proxy+}
ANY /me               ANY /me/{proxy+}
ANY /owner            ANY /owner/{proxy+}
ANY /admin            ANY /admin/{proxy+}
ANY /collaborations   ANY /collaborations/{proxy+}
```

**6.3 — Kiểm tra một route.** Ở **Attach integrations to routes**, chọn một route như `ANY /collaborations`; chi tiết bên phải phải hiện `fitness-assistant-dev-gym`.

![Route ANY /collaborations được chọn, Lambda function fitness-assistant-dev-gym](/images/workshop/runbook/img117.jpg)

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

`fitness-assistant-dev-gym-jobs` dùng cùng role và artifact với Gym Lambda.

**7.1 — Điền thông tin function.** Mở **Lambda → Create function**, giữ **Author from scratch**, đặt tên `fitness-assistant-dev-gym-jobs`, runtime **Node.js 22.x**, ở **Additional settings → Custom execution role** chọn `fitness-assistant-dev-gym-lambda-role`. Rồi bấm **Create function**.

![Author from scratch, tên gym-jobs, runtime Node.js 22.x và role có sẵn](/images/workshop/runbook/img118.jpg)

**7.2 — Đặt memory và timeout.** **Configuration → General configuration → Edit**: **Memory** `1024` MB, **Timeout** `1` phút `0` giây, rồi **Save**.

![Memory 1024 MB, timeout 1 phút 0 giây, Save](/images/workshop/runbook/img119.jpg)

**7.3 — Đặt handler.** **Code → Runtime settings → Edit**: `dist/jobs-lambda.handler`, rồi **Save**.

![Handler dist/jobs-lambda.handler và Save](/images/workshop/runbook/img120.jpg)

**7.4 — Nạp code.** **Upload from → Amazon S3 location**: dán cùng link `gym-lambda.zip`, giữ **Copy mode**, bấm **Update**.

![Cùng link S3 tới gym-lambda.zip và Update](/images/workshop/runbook/img121.jpg)

**7.5 — Gắn VPC.** **Configuration → VPC → Edit**: cùng VPC, subnet và security group như Gym Lambda, rồi **Save**. Sao chép luôn các environment variable, bao gồm `CHECKIN_TOKEN_SECRET`.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img122.jpg)

#### Bước 8 — Scheduler role và schedule

**8.1 — Tạo scheduler role.** Tạo `fitness-assistant-dev-gym-jobs-scheduler-role` (trust `scheduler.amazonaws.com`) với inline policy `fitness-assistant-dev-invoke-gym-jobs` cho phép `lambda:InvokeFunction` chỉ trên Gym jobs Lambda.

*Runbook không có ảnh của thao tác này.*

**8.2 — Tạo hai schedule** trong **EventBridge → Schedules**:

| Schedule | Tần suất | Payload |
|---|---|---|
| `fitness-assistant-dev-gym-membership-payout` | `rate(10 minutes)` | `{"job":"membership-payout-sweep"}` |
| `fitness-assistant-dev-gym-referral-settlement` | `rate(10 minutes)` | `{"job":"referral-settlement-sweep"}` |

Cả hai: tắt flexible window, enabled, maximum event age 5 phút, 2 lần thử lại, không DLQ, key do AWS sở hữu, dùng scheduler role có sẵn. Cả hai job đều cần Payment Service, đó là lý do Gym jobs Lambda cũng nhận `PAYMENT_LAMBDA_NAME` ở trang tiếp theo.

*Runbook không có ảnh của bước tạo schedule.*
