---
title: "Kiểm thử & xác nhận"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.5. </b> "
---

Phần này tập hợp các bài kiểm tra chứng minh từng phần của hệ thống hoạt động, kèm bằng chứng chụp trong lúc triển khai và kết quả mong đợi chính xác. Những bài kiểm tra vẫn còn phải chạy trong lượt end-to-end cuối cùng được ghi rõ như vậy, không báo là đã pass.

1. [5.5.1 Schema migration](5.5.1-Schema-Migrations/) — database của mọi service đã được tạo và migrate; restore dữ liệu đã xác nhận.
2. [5.5.2 Frontend, API Gateway và Auth](5.5.2-Auth-Frontend-Smoke-Test/) — đường đi request từ browser tới Aurora.
3. [5.5.3 Chat health và Socket.IO](5.5.3-Chat-Health-SocketIO/) — ECS service, ALB và WebSocket handshake.
4. [5.5.4 Background job, queue và log](5.5.4-Background-Jobs-Logs/) — schedule, SQS worker và CloudWatch Logs.
5. [5.5.5 Giám sát và cảnh báo với Amazon CloudWatch](5.5.6-Monitoring-Alerting/) — log, metric, alarm, thông báo, request mẫu và kiểm thử ca lỗi.
