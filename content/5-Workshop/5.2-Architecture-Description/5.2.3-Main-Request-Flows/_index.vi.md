---
title: "Các luồng request chính"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.2.3. </b> "
---

### Luồng Core API

Bao gồm Auth, User, Fitness, Gym, Payment và AI HTTP Lambda.

1. Browser tải frontend tĩnh từ Amazon S3 website endpoint.
2. Frontend gọi Amazon API Gateway (`fitness-assistant-dev-api`) kèm `Authorization: Bearer <JWT>`.
3. API Gateway khớp route (route tường minh cho Auth, một cặp route gốc + greedy route cho mỗi prefix của các service khác) và invoke Lambda của service đó với payload format 2.0. `/internal/*`, `/metrics` và route catch-all `/{proxy+}` không bao giờ được public.
4. Lambda tự verify JWT — ví dụ AI Lambda invoke Auth Lambda để kiểm tra token và từ chối header `x-user-id` / `x-user-role` giả mạo — nên không cần authorizer riêng ở API Gateway.
5. Khi request cần service khác, Lambda invoke trực tiếp Lambda của service đó (`lambda:InvokeFunction`), xác thực bằng `INTERNAL_SERVICE_SECRET` dùng chung. Ví dụ: User → Auth, Payment → Auth/User/Gym, Gym → Payment, Payment → AI để kích hoạt dịch vụ cá nhân hoá đã thanh toán.
6. Lambda đọc/ghi logical database của chính nó trên Aurora qua private app subnet, dùng credential resolve từ Secrets Manager lúc runtime.
7. Response trả về qua API Gateway tới browser.

### Luồng Chat

1. **REST** (danh sách hội thoại, lịch sử): frontend gọi API Gateway `ANY /chat/{proxy+}` — một HTTP proxy integration chuyển tiếp tới `http://<chat-alb>/chat/{proxy}`.
2. **Real-time**: frontend mở Socket.IO thẳng tới Chat ALB (`/socket.io/`), HTTP port 80 ở DEV.
3. ALB chuyển tiếp tới Fargate task ở container port 3005; listener trả 404 cố định cho `/internal/*` và `/metrics` nên các path này không bao giờ tới container. Stickiness của target group giữ client ở cùng một task.
4. Task chạy trong private app subnet, không có public IP; security group của nó chỉ nhận port 3005 từ security group của ALB.
5. Chat Service đọc/ghi `fitness_assistant_chat` trên Aurora và invoke Auth/User Lambda qua ECS task role.

{{% notice note %}}
Ở DEV, ALB chỉ chạy HTTP, giống S3 website endpoint, nên chưa có vấn đề mixed-content. Chuyển cả hai sang HTTPS cần domain và chứng chỉ ACM (xem [5.2.5](../5.2.5-Security-IAM/)).
{{% /notice %}}

### Luồng xử lý nền

1. **Job theo lịch** — 13 schedule EventBridge Scheduler (session settlement, auto-confirm, reschedule expiry, nhắc workout, membership payout, referral settlement, payment reconciliation, AI auto-accept và bốn lượt refresh tri thức hằng đêm) invoke function jobs của từng service với payload `{"job": "<name>"}`. Mỗi service có scheduler role riêng chỉ được invoke đúng function jobs của nó.
2. **Việc AI dài** — AI HTTP Lambda đưa yêu cầu tạo kế hoạch vào Amazon SQS (`fitness-assistant-dev-ai-tasks`); AI Worker Lambda xử lý từng message một (batch size 1, tối đa 300 giây mỗi message, 2 lần thử trước khi vào dead-letter queue) và frontend poll trạng thái job.
3. **Nạp tri thức** — AI Jobs Lambda lấy dữ liệu PubMed, RSS, web và local evidence hằng đêm, tạo embedding bằng Cohere Embed Multilingual v3 (1024 chiều) và ghi vào OpenSearch Serverless.
4. Mọi function AI gọi Amazon Bedrock qua NAT Gateway và truy cập OpenSearch Serverless private qua VPC endpoint, ký request bằng IAM role của chính nó (SigV4).

### Vì sao có ba luồng riêng thay vì một

Luồng Core API là ví dụ điển hình phù hợp với Lambda: ngắn, stateless, scale về 0. Luồng Chat không dùng được model đó vì Socket.IO cần kết nối sống qua nhiều vòng request/response — nên dùng ECS Fargate và ALB cho riêng service này. Luồng xử lý nền giữ việc chậm hoặc định kỳ ra khỏi request HTTP của người dùng: API Gateway chỉ cho integration khoảng 30 giây, trong khi tạo kế hoạch có thể mất vài phút và crawl tri thức tới mười phút.
