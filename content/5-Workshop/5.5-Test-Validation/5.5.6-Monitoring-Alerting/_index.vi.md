---
title: "Giám sát và cảnh báo với Amazon CloudWatch"
date: 2026-10-23
weight: 6
chapter: false
pre: " <b> 5.5.5. </b> "
---

Trang này cho thấy môi trường DEV được theo dõi bằng **log, metric và alarm** như thế nào, một cảnh báo đến tay con người ra sao, và cách kiểm thử từng lớp. Mọi giá trị bên dưới đều được đọc từ tài khoản thật.

#### 1. Các lớp giám sát

| Lớp | Dịch vụ AWS | Phạm vi |
|---|---|---|
| Log | Amazon CloudWatch Logs | Một log group cho mỗi Lambda, cộng với Chat task và migrator database |
| Metric | Amazon CloudWatch Metrics | Metric có sẵn của Lambda, API Gateway, Aurora, SQS, NAT Gateway và ECS |
| Alarm | Amazon CloudWatch Alarms | 12 alarm về lỗi, phản hồi 5xx, tải database và sức khoẻ NAT |
| Thông báo | Amazon SNS | Topic `fitness-assistant-dev-app-alerts` với một subscription email đã xác nhận |
| Truy vết | AWS X-Ray | Active tracing trên sáu Lambda API (auth, user, fitness, gym, payment, AI) |
| Chi phí | AWS Budgets | Budget hàng tháng với ba thông báo |

Các alarm và topic được tạo bởi CloudFormation stack `fitness-assistant-dev-app-monitoring`, nên dựng lại được và không phải bấm tay.

#### 2. Log

| Log group | Thời gian lưu | Ghi chú |
|---|---|---|
| `/aws/lambda/fitness-assistant-dev-<service>` và `-jobs`, `-worker`, `-migrate` | Không hết hạn (mặc định) | JSON có cấu trúc do `pino` ghi: level 30 là info, 40 là cảnh báo, 50 là lỗi |
| `/ecs/fitness-assistant-dev-chat` | 30 ngày | Chat service |
| `/ecs/fitness-assistant-dev-db-migrator` | 14 ngày | Migrator database chạy một lần |

Hai truy vấn CloudWatch Logs Insights bao quát phần lớn việc xử lý sự cố:

```
fields @timestamp, @message
| filter @message like /"level":50/
| sort @timestamp desc
| limit 20
```

```
fields @timestamp, @message
| filter @message like /Task timed out|AccessDenied|ECONNREFUSED|P1001/
| sort @timestamp desc
| limit 20
```

Truy vấn đầu liệt kê các lỗi mới nhất của một function; truy vấn thứ hai tìm bốn lỗi hạ tầng phổ biến nhất (timeout, thiếu quyền, kết nối bị từ chối, không tới được database). Ý nghĩa từng thông điệp có ở [5.5.4](../5.5.4-Background-Jobs-Logs/).

#### 3. Các metric đáng theo dõi

| Namespace | Metric | Lý do |
|---|---|---|
| `AWS/Lambda` | `Errors`, `Throttles`, `Duration`, `ConcurrentExecutions` | Sức khoẻ function và timeout 30 giây |
| `AWS/ApiGateway` | `Count`, `4xx`, `5xx`, `Latency` | Phân biệt lỗi do client với lỗi do server ở điểm vào |
| `AWS/RDS` | `ServerlessDatabaseCapacity`, `CPUUtilization` | Mức scale và tải của Aurora Serverless v2 |
| `AWS/SQS` | `ApproximateNumberOfMessagesVisible` của queue và dead-letter queue | Tồn đọng job AI, job lỗi |
| `AWS/NATGateway` | `ActiveConnectionCount`, `PacketsDropCount`, `ErrorPortAllocation` | Đường ra dùng cho Bedrock và email |

#### 4. Alarm

Cả 12 alarm đều dùng `TreatMissingData: notBreaching`, nên môi trường đang tắt không gây cảnh báo giả. Mỗi alarm gửi cả chuyển trạng thái **ALARM** lẫn **OK** tới SNS topic.

| Alarm | Metric | Điều kiện |
|---|---|---|
| `fitness-assistant-dev-auth-lambda-errors` | `AWS/Lambda` `Errors`, Sum | ≥ 5 trong 5 phút |
| `fitness-assistant-dev-user-lambda-errors` | như trên | ≥ 5 trong 5 phút |
| `fitness-assistant-dev-fitness-lambda-errors` | như trên | ≥ 5 trong 5 phút |
| `fitness-assistant-dev-gym-lambda-errors` | như trên | ≥ 5 trong 5 phút |
| `fitness-assistant-dev-payment-lambda-errors` | như trên | ≥ 5 trong 5 phút |
| `fitness-assistant-dev-ai-lambda-errors` | như trên | ≥ 5 trong 5 phút |
| `fitness-assistant-dev-apigw-5xx-high` | `AWS/ApiGateway` `5xx`, Sum | ≥ 10 trong 5 phút |
| `fitness-assistant-dev-aurora-cpu-high` | `AWS/RDS` `CPUUtilization`, Average | > 80 trong 2 chu kỳ 5 phút |
| `fitness-assistant-dev-aurora-capacity-pinned` | `AWS/RDS` `ServerlessDatabaseCapacity`, Average | ≥ 1,8 ACU trong 3 chu kỳ 5 phút (cluster scale từ 0,5 đến 2,0 ACU, nên nghĩa là đang kẹt gần mức tối đa) |
| `NAT-Gateway-High-Active-Connections` | `ActiveConnectionCount`, Average | > 1000 |
| `NAT-Gateway-Packet-Drops` | `PacketsDropCount`, Sum | > 100 |
| `NAT-Gateway-Port-Allocation-Errors` | `ErrorPortAllocation`, Sum | > 0 |

**Đường thông báo:** alarm → SNS topic `fitness-assistant-dev-app-alerts` → email (1 subscription đã xác nhận, 0 đang chờ). Alarm tự đổi trạng thái: ví dụ lịch sử của alarm API 5xx cho thấy các chuyển `OK → ALARM` và `ALARM → OK` ngày 23/10/2026, và alarm tự trở về OK mỗi lần.

![Danh sách CloudWatch alarm với 12 alarm](/images/workshop/console/cw-alarms-list.jpg)
*12 alarm trong CloudWatch → Alarms.*

![SNS topic với một subscription email đã xác nhận](/images/workshop/console/sns-subscriptions.jpg)
*SNS topic với một subscription email đã xác nhận.*

![Trang cấu hình Lambda cho thấy Lambda service traces đã bật](/images/workshop/console/lambda-tracing.jpg)
*Lambda → Configuration → Monitoring and operations tools: logs và metrics đã bật, Lambda service traces (X-Ray) đã bật.*

Các bước tạo một alarm, kèm form, có ở [5.4.14](../../5.4-Deployment-Guide/5.4.14-Edge-Database-Monitoring/).

#### 5. Giám sát chi phí

Budget `fitness-assistant-monthly` có hạn mức **15 USD mỗi tháng** với ba thông báo: chi tiêu thực tế vượt 50 phần trăm và vượt 100 phần trăm hạn mức, và chi tiêu dự báo vượt 100 phần trăm. Điều này quan trọng vì nhiều tài nguyên tính tiền theo giờ (NAT Gateway, load balancer, Aurora, endpoint), nên môi trường có quy trình bật tắt theo yêu cầu ([5.7](../../5.7-Cleanup/)).

#### 6. Kiểm thử và xác nhận

**6.1 Request mẫu.** Các request này được chạy với API và CloudFront đã deploy; kết quả thực tế được ghi lại.

| # | Request | Kỳ vọng | Kết quả |
|---|---|---|---|
| 1 | `GET /health` | `200` và tên service | `200` `{"status":"ok","service":"auth-service"}` |
| 2 | `POST /auth/login` sai mật khẩu | `401`, không tiết lộ trường nào sai | `401` `{"error":"Invalid credentials"}` |
| 3 | `POST /auth/login` với JSON sai định dạng (`{"email":`) | `400` và không lộ stack trace | `400` `Bad Request` |
| 4 | `POST /auth/login` với body rỗng `{}` | `400` kèm các trường còn thiếu | `400` `Validation failed`, liệt kê `email` và `password` là bắt buộc |
| 5 | `GET /plans/workout` không có token | `401` | `401` `UNAUTHORIZED` ("Request must carry a valid Bearer token…") |
| 6 | `GET /plans/workout` với token giả | `401` | `401` `UNAUTHORIZED` ("Invalid or expired token") |
| 7 | `GET /me/gym-memberships` không có token | `401` | `401` `UNAUTHORIZED` ("Authentication required") |
| 8 | `GET /does-not-exist` | `404` từ API Gateway | `404` `{"message":"Not Found"}` |
| 9 | `GET /` trên domain CloudFront | `200`, phục vụ từ S3 | `200`, `Server: AmazonS3`, header phản hồi cho thấy CloudFront |

Ví dụ cho test 2:

```
curl -s -X POST https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/auth/login \
  -H "content-type: application/json" \
  -d '{"email":"nobody@example.com","password":"wrong"}'
```

**6.2 Xác minh log.** Sau test 2 đến 4, log group `/aws/lambda/fitness-assistant-dev-auth` có một mục có cấu trúc cho mỗi request với method `POST` và URL `/auth/login`, và metric `Errors` của Lambda vẫn bằng 0: một lần đăng nhập bị từ chối là `4xx` đã được xử lý, không phải lỗi function.

**6.3 Xác minh metric.** Vài phút sau, `Count` và `4xx` của `AWS/ApiGateway` tăng đúng bằng số request đã gửi, còn `5xx` vẫn bằng 0. Metric có độ trễ từ một đến vài phút.

**6.4 Kiểm thử alarm.** Để chứng minh toàn bộ đường cảnh báo mà không làm hỏng gì, ép một alarm sang trạng thái ALARM và kiểm tra email có đến không, rồi để nó tự về OK:

```
aws cloudwatch set-alarm-state \
  --alarm-name fitness-assistant-dev-apigw-5xx-high \
  --state-value ALARM --state-reason "Alert path test"
```

Alarm sẽ đánh giá lại metric thật ở chu kỳ kế tiếp và tự trở về OK.

**6.5 Kiểm tra ca lỗi.** Các test âm tính ở trên (sai mật khẩu, body sai định dạng, thiếu token, token giả, route không tồn tại) xác nhận lỗi bị từ chối đúng tầng với đúng mã trạng thái, và không test nào làm các alarm lỗi function nổ.
