---
title: "5.2.3 Các luồng request chính"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.2.3. </b> "
---

### Luồng Core API

Bao gồm Auth, User, Fitness, Gym, Payment, và AI HTTP Lambda.

1. Browser load frontend tĩnh từ Amazon S3 website endpoint (`fitness-assistant-frontend-dev-191798898985`).
2. Frontend gọi Amazon API Gateway (`fitness-assistant-dev-api`, `https://id1iz7upbl.execute-api.ap-southeast-1.amazonaws.com`).
3. API Gateway route request tới Lambda của service tương ứng (Auth, User, Fitness, Gym, Payment, hoặc AI) dựa trên path.
4. Với các route cần user đã đăng nhập, Lambda đích tự verify JWT của caller (không qua một bước "auth check" riêng ở API Gateway), và khi cần dữ liệu từ service khác, invoke trực tiếp Lambda của service đó (ví dụ Payment invoke Auth/User để xác định đang billing cho ai), xác thực bằng một internal service secret dùng chung thay vì round-trip JWT lần hai.
5. Lambda đọc/ghi database logic của chính nó trên cluster Aurora PostgreSQL Serverless dùng chung, truy cập qua private app subnet.
6. Response trả về qua API Gateway tới frontend.

### Luồng Chat

1. Browser kết nối tới DNS name công khai của Chat ALB, qua REST endpoint thông thường hoặc nâng cấp WebSocket Socket.IO.
2. ALB forward kết nối tới task Chat Service chạy trên ECS Fargate (`fitness-assistant-dev-cluster` / `fitness-assistant-dev-chat-service`), ở container port 3005.
3. Chuỗi security group chỉ cho phép ALB truy cập task Fargate ở port đó — task không bao giờ truy cập trực tiếp được từ internet.
4. Chat Service đọc/ghi database Chat trên cùng cluster Aurora.
5. Khi Chat cần gọi service khác (ví dụ xác nhận identity user), nó invoke Lambda của service đó theo cách giống luồng Core API gọi lẫn nhau.

{{% notice note %}}
DEV hiện tại chạy ALB qua HTTP (port 80) thôi — frontend cũng chỉ HTTP ở giai đoạn này (xem [5.2.7](../5.2.7-Cost-Optimization-Cleanup/)), nên chưa có vấn đề mixed-content. Chuyển ALB sang HTTPS được theo dõi như việc cần làm khi có domain và chứng chỉ ACM.
{{% /notice %}}

### Luồng xử lý nền (Background Processing)

1. Các hành động theo lịch (reconciliation schedule của Payment, reminder schedule của Gym và Fitness) được trigger bởi rule Amazon EventBridge Scheduler, mỗi service một rule riêng, thay vì một Lambda cron dùng chung.
2. Công việc AI bất đồng bộ (chat completion lâu hơn timeout của HTTP Lambda, hoặc job được service khác queue tường minh) đi qua Amazon SQS tới AI Worker Lambda.
3. AI Worker và các Jobs Lambda của từng service đọc/ghi cùng cluster Aurora như các Lambda ở luồng request — không có database "jobs" riêng.
4. Luồng AI còn gọi thêm ra Amazon Bedrock (model `apac.amazon.nova-pro-v1:0` cho chat/vision, `cohere.embed-multilingual-v3` cho embeddings) qua NAT Gateway, vì Bedrock được gọi như một AWS API thông thường từ trong VPC.

### Vì sao có ba luồng riêng thay vì một

Luồng Core API là ví dụ kinh điển phù hợp với Lambda: ngắn, stateless, scale về 0. Luồng Chat không dùng được model đó vì Socket.IO cần một kết nối sống qua nhiều vòng request/response — nên dùng ECS Fargate và ALB thay vì API Gateway và Lambda cho riêng service này. Luồng xử lý nền tồn tại để công việc theo lịch và AI chậm không chặn cửa sổ timeout của một request HTTP user-facing, và để một đợt tăng đột biến request AI được xếp hàng trong SQS thay vì làm throttle luồng API đồng bộ.
