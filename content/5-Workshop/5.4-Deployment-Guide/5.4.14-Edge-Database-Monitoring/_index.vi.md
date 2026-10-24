---
title: "5.4.14 CloudFront, Aurora reader và CloudWatch alarm"
date: 2026-10-23
weight: 14
chapter: false
pre: " <b> 5.4.14. </b> "
---

Bước này bao gồm ba phần của kiến trúc mà các bước trước chỉ nhắc tới: distribution **CloudFront** đứng trước frontend và chat, **Aurora reader** ở Availability Zone thứ hai, và một **CloudWatch alarm** gửi thông báo tới SNS topic. Với mỗi phần bạn thấy kết quả hoàn chỉnh trên console và form dùng để tạo nó. Trong ảnh, **khung đỏ kèm số** chỉ chỗ cần điền hoặc bấm, theo thứ tự.

{{% notice note %}}
Các ảnh của form tạo được chụp bằng cách mở từng form rồi thoát bằng **Cancel**: không có gì được tạo khi chụp, và các tài nguyên thật đã được kiểm tra lại sau đó (vẫn 12 alarm, 2 instance Aurora, 1 behavior CloudFront ngoài mặc định). Tài nguyên thật được tạo bởi các CloudFormation stack của dự án, nên cùng kết quả đó dựng lại được mà không cần bấm tay.
{{% /notice %}}

#### Phần A — Distribution CloudFront

Distribution phục vụ web app qua HTTPS và chuyển lưu lượng chat tới load balancer.

**A.1 — Kiểm tra hai origin.** Mở **CloudFront → Distributions → `E2MHD79JFC1700` → Origins**. Phải có hai origin:

| Tên origin | Loại | Truy cập |
|---|---|---|
| `frontend-s3-origin` | S3 | Origin Access Control, nên bucket chỉ được đọc qua CloudFront |
| `chat-alb-origin` | Elastic Load Balancing | Chỉ HTTP về phía origin (load balancer không có HTTPS listener) |

![Tab Origins của CloudFront với origin S3 và origin load balancer chat](/images/workshop/console/cf-origins.jpg)
*Tab Origins: origin S3 dùng Origin Access Control và origin thứ hai là load balancer của chat.*

**A.2 — Kiểm tra hai behavior.** Mở tab **Behaviors**. Quy tắc `/socket.io/*` phải đứng đầu, để chat được khớp trước quy tắc mặc định.

![Tab Behaviors của CloudFront với quy tắc /socket.io/* và quy tắc mặc định](/images/workshop/console/cf-behaviors.jpg)
*Tab Behaviors: `/socket.io/*` đi tới origin chat, mọi đường dẫn khác đi tới S3.*

**A.3 — Tạo behavior cho chat.** Bấm **Create behavior** và điền form (số tương ứng với các khung đỏ):

1. **Path pattern:** gõ mẫu bên dưới.
2. **Origin and origin groups:** chọn `chat-alb-origin`.
3. **Viewer protocol policy:** chọn **HTTPS only**.

```text
/socket.io/*
```

![Nửa đầu form Create behavior với path pattern, origin và viewer protocol](/images/workshop/console/cf-create-behavior-1.jpg)
*Nửa đầu của form: path pattern, origin và viewer protocol policy.*

Sau đó cuộn xuống và đặt các policy cache và request:

1. **Cache policy:** `CachingDisabled`, vì kết nối WebSocket hay long-polling không bao giờ được cache.
2. **Origin request policy:** `AllViewer`, để mọi header của người xem, kể cả header upgrade, tới được chat service.

Với **Allowed HTTP methods** chọn cả bảy method (`GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE`), vì transport polling của Socket.IO dùng `POST`. Bấm **Create behavior** để hoàn tất.

![Nửa sau form Create behavior với cache policy và origin request policy](/images/workshop/console/cf-create-behavior-2.jpg)
*Nửa sau: cache policy và origin request policy.*

**A.4 — Kiểm chứng.** Sau khi trạng thái distribution là **Deployed**, request này phải trả `200` kèm handshake Engine.IO (`sid`, `upgrades: ["websocket"]`) khi chat service đang chạy:

```text
curl "https://<distribution-domain>/socket.io/?EIO=4&transport=polling"
```

Nếu trả `502`, load balancer đứng sau `chat-alb-origin` đã được tạo lại với tên DNS mới: sửa origin và nhập tên DNS hiện tại của load balancer.

#### Phần B — Aurora reader ở Availability Zone thứ hai

Cluster có một **Writer** và một **Reader**, nên việc đọc vẫn tiếp tục được nếu một instance hay một Availability Zone gặp sự cố.

**B.1 — Kiểm tra kết quả.** Mở **Aurora and RDS → Databases**. Cluster `fitness-assistant-dev-aurora` có hai instance, đều **Available**: một instance có vai trò *Writer instance* và một có vai trò *Reader instance*, cả hai là Aurora Serverless v2.

![Danh sách RDS với cluster, writer và reader](/images/workshop/console/rds-writer-reader.jpg)
*Cluster với hai instance Writer và Reader.*

**B.2 — Thêm reader.** Mở cluster và dùng menu **Actions**:

1. Bấm **Actions** ở góc trên bên phải trang cluster.

![Trang cluster với nút Actions được đánh dấu](/images/workshop/console/rds-cluster.jpg)
*Trang cluster, bước 1: nút Actions.*

2. Chọn **Add reader**.

![Menu Actions với Add reader được đánh dấu](/images/workshop/console/rds-actions-menu.jpg)
*Menu Actions, bước 1: Add reader.*

3. Trong form **Add reader**, gõ **DB instance identifier** (ví dụ `fitness-assistant-dev-aurora-instance-2`) và giữ **DB instance class** là **Aurora serverless**. Khoảng capacity được kế thừa từ cluster: tối thiểu 0,5 ACU, tối đa 2 ACU.

```text
fitness-assistant-dev-aurora-instance-2
```

![Form Add reader với instance identifier và lớp Aurora serverless được đánh dấu](/images/workshop/console/rds-add-reader.jpg)
*Form Add reader: instance identifier và lớp Aurora serverless.*

Cuộn xuống, giữ mặc định cho mạng, bảo mật và giám sát, rồi bấm **Add reader**. Reader được đặt ở Availability Zone khác với writer, và **Promotion tier** quyết định reader nào được lên làm writer trước khi failover.

#### Phần C — CloudWatch alarm gửi email

Dự án có 12 alarm, tạo bằng CloudFormation. Phần này cho thấy cách dựng một alarm bằng tay: lỗi của function `auth` vượt ngưỡng sẽ gửi thông báo tới SNS topic.

**C.1 — Kiểm tra nơi nhận thông báo.** Mở **SNS → Topics → `fitness-assistant-dev-app-alerts`**. Tab **Subscriptions** phải có một subscription email với trạng thái **Confirmed**.

![SNS topic với một subscription email đã xác nhận](/images/workshop/console/sns-subscriptions.jpg)
*Topic và subscription email đã xác nhận.*

**C.2 — Tạo alarm.** Mở **CloudWatch → Alarms → Create alarm**.

1. Bấm **Select metric**.

![Create alarm, bước 1, với Select metric được đánh dấu](/images/workshop/console/cw-create-1-metric.jpg)
*Bước 1 của wizard: Select metric.*

2. Chọn **Lambda → By Function Name**, tick dòng **Errors** của `fitness-assistant-dev-auth`, rồi bấm **Select metric**.

![Bộ chọn metric với metric Errors của function auth được tick](/images/workshop/console/cw-create-2-pick.jpg)
*Bộ chọn metric: metric `Errors` của `fitness-assistant-dev-auth`.*

3. Đặt **Statistic** là `Sum` và **Period** là `5 minutes`. Ở **Whenever Errors is…** chọn **Greater/Equal**, gõ ngưỡng bên dưới, rồi bấm **Next**.

```text
5
```

![Cài đặt điều kiện với Greater/Equal, ngưỡng 5 và Next được đánh dấu](/images/workshop/console/cw-create-3-condition.jpg)
*Điều kiện: lớn hơn hoặc bằng 5 lỗi trong 5 phút.*

4. Ở **Configure actions**, giữ **In alarm** làm trigger, chọn **Select an existing SNS topic**, và chọn `fitness-assistant-dev-app-alerts`. Thêm thông báo thứ hai cho **OK** với cùng topic, để bạn cũng nhận tin khi alarm phục hồi.

![Bước actions với ô SNS topic được đánh dấu](/images/workshop/console/cw-create-4-actions.jpg)
*Bước actions: chọn SNS topic.*

5. Bấm **Next**, nhập tên `fitness-assistant-dev-auth-lambda-errors`, bấm **Next**, xem lại rồi bấm **Create alarm**.

**C.3 — Kiểm chứng.** Alarm mới hiện **OK** (hoặc **Insufficient data** trong vài phút). Danh sách đầy đủ các alarm của dự án:

![Danh sách CloudWatch alarm với 12 alarm](/images/workshop/console/cw-alarms-list.jpg)
*12 alarm của dự án. Ba alarm NAT Gateway hiện Insufficient data khi NAT Gateway đang tắt.*

**Kiểm thử đường cảnh báo** mà không làm hỏng gì bằng cách ép alarm sang trạng thái alarm, rồi chờ email và chờ alarm tự về OK:

```text
aws cloudwatch set-alarm-state --alarm-name fitness-assistant-dev-auth-lambda-errors --state-value ALARM --state-reason "Alert path test"
```

#### Kết quả

- Distribution CloudFront có origin S3 dùng Origin Access Control và origin chat, với `/socket.io/*` được khớp trước.
- Cluster Aurora có Writer và Reader ở các Availability Zone khác nhau.
- Một CloudWatch alarm gửi thông báo ALARM và OK tới một email đã xác nhận qua SNS.
