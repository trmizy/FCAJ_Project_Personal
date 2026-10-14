---
title: "5.5.3 Chat health và Socket.IO"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.5.3. </b> "
---

| # | Kiểm tra | Cách làm | Kết quả mong đợi | Trạng thái |
|---|---|---|---|---|
| C1 | ECS service ổn định | ECS → `fitness-assistant-dev-cluster` → *Services* | `fitness-assistant-dev-chat-service` Active, 1/1 task đang chạy, deployment *Completed* | Pass |
| C2 | ALB thấy task healthy | EC2 → Target groups → `fitness-assistant-dev-chat-tg` → *Targets* | Một private IP (10.0.10.x / 10.0.11.x) ở port 3005, trạng thái **Healthy** | Pass |
| C3 | HTTP health qua ALB | `GET http://<chat-alb-dns>/health` | HTTP 200 | Pass |
| C4 | Socket.IO handshake | `GET http://<chat-alb-dns>/socket.io/?EIO=4&transport=polling` | Body bắt đầu bằng `0{"sid":"…","upgrades":["websocket"],"pingInterval":…,"pingTimeout":…}` — không phải 404, 502 hay 503 | Đã xác nhận khi deploy |
| C5 | Path nội bộ bị ẩn | `GET http://<chat-alb-dns>/internal/x` và `/metrics` | `404 Not Found` cố định từ listener rule của ALB; request không bao giờ tới container | Listener rule đã có |
| C6 | REST qua API Gateway | `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/chat/conversations` | Tới được backend Chat: 401 nếu không có token, danh sách hội thoại nếu có Bearer token hợp lệ | Đưa vào lượt E2E cuối |
| C7 | Nối secret runtime | Log group `/ecs/fitness-assistant-dev-chat` sau revision 3 | Không còn `URL must start with postgresql://`; service kết nối được `fitness_assistant_chat` | Cần xác nhận trong log sau khi rollout revision 3 |
| C8 | Nhắn tin real-time | Hai người dùng mở cùng một hội thoại trên frontend và nhắn tin qua lại | Tin nhắn hiện ngay cho cả hai mà không cần refresh | Đưa vào lượt E2E cuối |

#### Bằng chứng

![C1 — service active với 1/1 task đang chạy](/images/workshop/runbook/img330.jpg)

![C2 — target 10.0.11.164:3005 healthy](/images/workshop/runbook/img331.jpg)

![C5 — listener rule: ALB tự trả lời /internal/* và /metrics, còn lại forward tới target group](/images/workshop/runbook/img328.jpg)

#### Nếu có lỗi

| Triệu chứng | Nguyên nhân cần kiểm tra |
|---|---|
| Task chuyển từ PENDING sang STOPPED | *Stopped reason*: pull image (ECR/NAT), inject secret (policy của execution role), hoặc container crash khi khởi động (log group) |
| Target *Unhealthy* | Chat SG phải cho phép 3005 từ ALB SG; `/health` phải trả 200 trong 5 giây; grace period đủ dài cho lúc khởi động |
| 502 / 503 từ ALB | Chưa có target healthy nào được đăng ký, hoặc task đang khởi động lại |
| Socket.IO kết nối rồi bị ngắt | Idle timeout của ALB (đặt 120 giây) và stickiness của target group; chỉ chạy 1 task khi trạng thái phiên còn nằm trong memory |
