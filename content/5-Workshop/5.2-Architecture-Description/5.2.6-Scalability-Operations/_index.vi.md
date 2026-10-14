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
| Lambda Auth / User / Fitness / Gym / Payment / AI | Theo từng lần gọi, tự động, scale về 0 khi idle | Không cần capacity planning cho mức traffic DEV hiện tại; đánh đổi là cold start trên function idle, chưa đo/tune. |
| Chat Service (ECS Fargate) | Số task thủ công hiện tại (dev sizing: 0.5 vCPU / 1 GB, thực chất cố định 1 task) | Chưa gắn Auto Scaling policy — một đơn giản hoá có chủ đích ở giai đoạn DEV, không phải thiếu sót; theo dõi như khoảng trống, không phải thiết kế đã hoàn thiện. |
| Aurora PostgreSQL Serverless v2 | Tự scale capacity (ACU) giữa một floor và ceiling đã cấu hình | Hiện giữ ở floor 0.5 ACU thay vì để scale về 0, cố ý để tránh độ trễ auto-pause/resume ảnh hưởng tới các smoke test đang chạy trong lúc phát triển (xem [5.2.7](../5.2.7-Cost-Optimization-Cleanup/)). |
| API Gateway, S3, EventBridge, SQS | Fully managed, tự scale, không cần cấu hình gì từ project này | Chưa chạm và không dự kiến chạm trần capacity nào ở mức traffic DEV. |

### Tách việc xử lý nền khỏi luồng request

Công việc theo lịch (reconciliation của Payment, reminder của Gym/Fitness) chạy trên rule Amazon EventBridge Scheduler, mỗi service một rule riêng, thay vì chạy trong request handler — để một request HTTP của user không bao giờ là thứ trigger một lượt reconciliation. Công việc AI bất đồng bộ đi qua Amazon SQS tới một AI Worker Lambda riêng, để một model completion chậm không giữ mở — hay làm timeout — một request API Gateway đồng bộ. Đây là lý do tính năng AI có ba Lambda (HTTP, Worker, Jobs) thay vì một: mỗi cái xử lý một yêu cầu về thời gian khác nhau thay vì một function cố làm cả ba.

### Khoảng trống vận hành, theo dõi thẳng thắn

Hệ thống này đã deploy và verify một phần, chưa phải "hoàn thiện và hardened". Các khoảng trống dưới đây là những cái được ghi rõ trong chính phần theo dõi trạng thái của runbook deployment nội bộ, không phải phát hiện sau khi xong việc:

- **CI/CD chưa tồn tại.** Mọi deployment cho tới giờ — một Lambda version mới, một task definition revision của Fargate, một database migration — đều là thao tác thủ công qua console hoặc CLI. Đây là phần việc vận hành lớn nhất còn lại (xem [5.1 Overview](../../5.1-Overview/)).
- **Chưa cấu hình CloudWatch Alarm nào.** Log có sẵn cho mọi Lambda và Fargate task, nhưng chưa có gì page hay gửi email khi lỗi tăng đột biến, Lambda bị throttle, hay Aurora chạm trần capacity. Monitoring hiện tại là "đọc log", không phải "được cảnh báo".
- **Kiểm thử end-to-end chưa hoàn tất.** Theo bảng trạng thái ở [5.2.1](../5.2.1-Architecture-Overview/), chỉ Auth và User có lượt E2E pass đầy đủ ghi nhận; Fitness, Gym, Payment, AI/Worker/Jobs, Chat, và tích hợp frontend đã deploy nhưng vẫn cần một lượt.
- **Chưa cấu hình Auto Scaling cho Chat Fargate service.** Một task cố định là đủ cho số phiên chat đồng thời ở mức DEV hiện tại; cần xem lại trước khi có tải nhiều user thật.

### Vì sao những khoảng trống này được liệt kê thay vì bỏ qua

[Definition of Done](../../5.1-Overview/) của báo cáo này cam kết không khẳng định một bước thành công mà thiếu bằng chứng. Nguyên tắc tương tự áp dụng cho độ chín vận hành: một kiến trúc serverless tự scale compute không tự động "sẵn sàng production" chỉ vì Lambda và Fargate xử lý phần cơ chế scale — những khoảng trống CI/CD, alarm, và E2E coverage ở trên chính là loại thứ mà một mô tả thuần kiến trúc có thể che lấp đi, nên chúng được nêu rõ ở đây.
