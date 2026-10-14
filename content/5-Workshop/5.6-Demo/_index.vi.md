---
title: "5.6 Demo"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.6. </b> "
---

{{% notice info %}}
Runbook triển khai chỉ chứa bằng chứng trên AWS console. Screenshot và một đoạn quay màn hình ngắn của ứng dụng đang chạy sẽ được ghi lại trong lượt kiểm thử end-to-end cuối cùng ([5.5.5](../5.5-Test-Validation/5.5.5-Status-Open-Items/)) và bổ sung vào trang này; trước đó, trang mô tả kịch bản demo để bất kỳ ai có quyền truy cập môi trường DEV đều làm lại được.
{{% /notice %}}

#### Điểm truy cập

| Gì | URL |
|---|---|
| Ứng dụng web | `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com` |
| REST API | `https://<api-id>.execute-api.ap-southeast-1.amazonaws.com` |
| Chat real-time | `http://fitness-assistant-dev-chat-alb-<id>.ap-southeast-1.elb.amazonaws.com` (frontend dùng cho Socket.IO) |

#### 5.6.1 Hành trình của thành viên

1. **Đăng ký và đăng nhập** — `/register`, xác minh, rồi `/login` (Auth Lambda, JWT).
2. **Onboarding và hồ sơ** — body profile, mục tiêu, ảnh hồ sơ upload thẳng lên S3 bucket private bằng presigned URL (User Lambda).
3. **Tập luyện** — xem bài tập, tạo hoặc import kế hoạch tập, bắt đầu và hoàn thành một workout; job nhắc lịch quét các workout được lên kế hoạch hôm nay (Fitness Lambda + EventBridge).
4. **AI coach** — đặt câu hỏi trong AI chat (Bedrock Nova Pro, dựa trên các index tri thức trong OpenSearch), rồi yêu cầu tạo kế hoạch tập hoặc dinh dưỡng và theo dõi nó hoàn tất qua SQS worker (AI HTTP Lambda → SQS → AI Worker).
5. **Phòng gym và huấn luyện viên** — xem danh sách gym và PT, check-in tại phòng tập bằng mã QR có chữ ký (Gym Lambda).
6. **Thanh toán** — nạp ví hoặc thanh toán hợp đồng PT qua VNPAY sandbox; giao dịch được xác nhận bởi callback của provider và job reconciliation 5 phút (Payment Lambda).
7. **Chat** — mở một hội thoại với PT; tin nhắn đến ngay qua Socket.IO (Chat trên ECS Fargate).

#### 5.6.2 Hành trình của admin

1. Đăng nhập bằng tài khoản admin.
2. **Người dùng** — xem danh sách, đổi role, khoá và mở lại tài khoản (`/auth/users/*`).
3. **Hồ sơ ứng tuyển PT và hợp đồng** — duyệt hồ sơ ứng tuyển PT và tài liệu kèm theo (User Lambda, S3 private).
4. **Thanh toán** — xem giao dịch và yêu cầu rút tiền (`/admin/payments/*`).
5. **Quản trị AI** — mở trang tổng quan AI (`/admin/ai/*`), cũng bị rate limit như mọi route AI.

#### Demo chứng minh điều gì

| Bước | Đường đi trên AWS được kiểm chứng |
|---|---|
| Mọi lần tải trang | S3 static website |
| Đăng nhập, hồ sơ, tập luyện, gym, thanh toán, admin | API Gateway → Lambda của service → Aurora (private subnet) |
| Câu trả lời và kế hoạch từ AI | API Gateway → AI Lambda → Bedrock (qua NAT) và OpenSearch (qua VPC endpoint), SQS → AI Worker |
| Nhắc lịch, settlement, reconciliation | EventBridge Scheduler → jobs Lambda |
| Chat trực tiếp | Chat ALB → ECS Fargate → Aurora |

Cả AI coach lẫn bất kỳ tính năng nào khác của ứng dụng đều không thay thế được tư vấn y tế.
