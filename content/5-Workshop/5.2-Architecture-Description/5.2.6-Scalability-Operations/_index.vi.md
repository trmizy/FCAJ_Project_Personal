---
title: "5.2.6 Khả năng mở rộng và vận hành"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.2.6. </b> "
---

### Mỗi thành phần scale thế nào

| Thành phần | Model scale | Ghi chú |
|---|---|---|
| Lambda của service (HTTP và jobs) | Theo từng lần gọi, tự động, scale về 0 | Mỗi function 1024 MB; đánh đổi là cold start trên function idle, chưa đo. Không đặt reserved concurrency, nên cấu hình không khiến một route nóng làm nghẽn route khác. |
| AI Worker | Mỗi message SQS một lần gọi Lambda (batch size 1) | Thông lượng tăng theo độ sâu hàng đợi; message lỗi vào DLQ sau 2 lần nhận. |
| Chat Service (ECS Fargate) | Cố định 1 task (0.5 vCPU / 1 GB) | Có chủ đích: trạng thái phiên Socket.IO nằm trong memory, task thứ hai sẽ chia tách phiên cho tới khi có adapter dùng chung (ví dụ Redis). Chưa có service auto scaling. |
| Aurora PostgreSQL Serverless v2 | Capacity theo ACU giữa floor và ceiling | Giữ floor 0.5 ACU khi đang deploy để auto-pause/resume không làm nhiễu smoke test; có thể về 0 khi idle. |
| OpenSearch Serverless (NextGen) | 0–2 OCU cho indexing và cho search | Scale về 0 sau ~10 phút idle; request đầu tiên sau đó có thể mất thêm 10–30 giây. |
| API Gateway, SQS, EventBridge, S3 | Fully managed | Không cần capacity planning ở lưu lượng DEV. Các route AI được throttling có chủ đích. |

### Giữ việc chậm ra khỏi luồng request

Việc theo lịch chạy từ EventBridge Scheduler vào function jobs riêng, nên không request nào của người dùng kích hoạt một lượt settlement hay reconciliation. Việc AI dài đi qua SQS tới AI Worker (timeout 300 giây) và nạp tri thức chạy trong AI Jobs function (timeout 600 giây), trong khi function HTTP luôn dưới giới hạn integration ~30 giây của API Gateway. Đó là lý do AI Service có ba function thay vì một.

### Vận hành hệ thống hiện tại

- **Deploy** là thủ công và được ghi lại từng bước ở [5.4](../../5.4-Deployment-Guide/): ZIP upload từ bucket deployments, task definition revision được rollout bằng *Force new deployment*, và thay đổi schema được áp dụng bằng migration function của từng service.
- **Log** của mọi function và task nằm trong CloudWatch Logs (`/aws/lambda/…`, `/ecs/…`); [5.5.4](../../5.5-Test-Validation/5.5.4-Background-Jobs-Logs/) liệt kê những gì cần tìm.
- **Đổi secret** (ví dụ mật khẩu Aurora được xoay vòng) cần làm mới execution environment của Lambda, vì function cache secret khi còn warm — lúc deploy Auth đã làm việc này bằng cách sửa một biến vô hại `DEPLOY_REVISION`.

### Khoảng trống vận hành, theo dõi công khai

- **CI/CD đã có** — GitHub Actions kiểm tra mọi PR và deploy code Lambda, image Chat và stack API Gateway qua các workflow có cổng người duyệt.
- **Giám sát đã có** — 12 CloudWatch alarm (lỗi Lambda của sáu service API, API Gateway 5xx, CPU và capacity của Aurora, sức khoẻ NAT Gateway) gửi tới một SNS topic có subscription e-mail đã xác nhận; một AWS Budget hàng tháng cảnh báo chi phí; X-Ray tracing bật trên sáu Lambda API.
- **Kiểm thử end-to-end chưa xong** — Auth và User đã verify; các service còn lại đã deploy nhưng đang chờ ([5.5.5](../../5.5-Test-Validation/5.5.5-Status-Open-Items/)).
- **Chat chỉ có một task** — chấp nhận được cho DEV, sẽ xem lại trước khi có tải nhiều người dùng thật.

Một kiến trúc serverless tự scale compute không tự động "sẵn sàng production"; những khoảng trống về độ phủ kiểm thử còn lại ở trên chính là thứ một mô tả thuần kiến trúc có thể che đi, nên chúng được nêu rõ ở đây.
