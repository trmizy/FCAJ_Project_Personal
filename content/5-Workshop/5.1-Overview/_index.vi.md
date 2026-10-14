---
title: "5.1 Tổng quan"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.1. </b> "
---

### Vấn đề

Fitness Assistant là một ứng dụng open-source thật, đang được phát triển tích cực, nhưng chỉ được build và test cho local development qua Docker Compose. Source code không có sẵn bất kỳ AWS deployment, CI/CD pipeline, hay cloud infrastructure nào. Workshop này lấp khoảng trống đó bằng cách deploy một phiên bản production-shaped, serverless-first của ứng dụng lên AWS.

{{% notice note %}}
Workshop này trước đây mô tả một kế hoạch MVP đơn giản hơn: EC2 + Docker Compose. Kế hoạch đó đã được thay thế bằng kiến trúc serverless mô tả từ đây trở đi — microservices chạy trên Lambda phía sau API Gateway, Aurora PostgreSQL Serverless, và ECS Fargate cho component duy nhất (Chat) thực sự cần một kết nối sống lâu dài. [Proposal](../../2-Proposal/) vẫn còn phản ánh kế hoạch EC2 cũ và đang chờ cập nhật cho khớp; chỗ nào hai tài liệu mâu thuẫn nhau, Workshop này và các trang kiến trúc ở [5.2](../5.2-Architecture-Description/) mô tả đúng những gì đã thực sự được deploy.
{{% /notice %}}

### Đối tượng sử dụng

- Thành viên phòng gym / người dùng cuối của app fitness, theo dõi workout, mục tiêu, và nhận gợi ý huấn luyện từ AI.
- Mentor/reviewer FCAJ đánh giá kết quả thực tập này.

### Tính năng ứng dụng (đúng như đã deploy)

- Đăng ký và đăng nhập, dựa trên JWT (`auth-service`, Lambda).
- Quản lý hồ sơ, bao gồm upload ảnh InBody với trích xuất hỗ trợ bởi AI (`user-service`, Lambda).
- Danh mục bài tập, kế hoạch tập luyện, ghi nhận workout (`fitness-service`, Lambda).
- AI coaching: Amazon Bedrock (Nova Pro cho chat/vision, Cohere multilingual embeddings cho retrieval) (`ai-service`, Lambda + một AI Worker chạy async cho background job).
- Danh sách phòng gym/PT và check-in bằng QR (`gym-service`, Lambda), thanh toán ví/hợp đồng PT qua VNPAY, kèm credential MoMo/PayOS/ZaloPay sẽ thêm dần khi có (`payment-service`, Lambda).
- Chat real-time (`chat-service`), chạy trên Amazon ECS Fargate phía sau Application Load Balancer — khác với các service còn lại, Socket.IO cần một kết nối sống lâu dài mà model request/response của Lambda không giữ được.

{{% notice note %}}
Tính năng AI coaching ban đầu chạy trên LLM self-host (Ollama) kèm vector store Qdrant, như đã mô tả ở [Tuần 8](../../1-Worklog/1.8-Week8/) của Worklog — một lựa chọn có chủ đích lúc đó để tránh chi phí managed-endpoint. Service này sau đó đã chuyển sang Amazon Bedrock (model `apac.amazon.nova-pro-v1:0` cho chat/vision, `cohere.embed-multilingual-v3` cho embeddings), giúp bỏ gánh nặng vận hành của việc sizing và vá lỗi một EC2 instance cho LLM. Tính năng trích xuất ảnh InBody riêng trong `user-service` cũng gọi vào cùng luồng AI này thay vì tích hợp API trực tiếp riêng. Cả hai tính năng đều không thay thế được tư vấn y tế — xem disclaimer ở [5.17 Conclusion](../5.17-Conclusion/).
{{% /notice %}}

### Kết quả mong muốn

Một môi trường DEV hoạt động, truy cập được qua internet: frontend tĩnh trên Amazon S3, cổng vào Amazon API Gateway, sáu microservice chạy trên Lambda và một service chạy trên ECS Fargate phía sau, và một cluster Amazon Aurora PostgreSQL Serverless duy nhất chứa một logical database cho mỗi service — được tài liệu hoá từng bước kèm bằng chứng (screenshot console, danh sách environment variable, ghi chú verification), không phải suy đoán.

### Phạm vi

- **Hạ tầng dùng chung:** một VPC, private application subnet cho Lambda, private DB subnet riêng (không có route ra internet), một public subnet chỉ để đặt NAT Gateway, và cặp NAT + Internet Gateway cho các lời gọi outbound (gọi API Gateway, Bedrock, Secrets Manager).
- **Tám service được tài liệu hoá đầy đủ:** Auth, User, Fitness, Gym, Payment, AI (HTTP + Worker + Jobs), Chat, và phần Database Migration một lần để chuyển 7 dump Postgres local vào Aurora.
- **Frontend:** một bản build tĩnh host trên Amazon S3 (website endpoint qua HTTP hiện tại; CloudFront + Origin Access Control là việc cần làm tiếp theo, chưa dùng được trong môi trường này).

### Những phần chưa hoàn thiện

- **CI/CD pipeline:** chưa xây dựng — mọi deployment cho tới giờ là thao tác thủ công qua console/CLI, được ghi lại đúng như lúc thực hiện.
- **Kiểm thử end-to-end:** Auth và User đã được verify đầy đủ; Fitness, Gym, Payment, AI/Worker/Jobs, Chat, và tích hợp Frontend vẫn cần một lượt E2E đầy đủ (theo dõi là "NEEDS VERIFICATION" trong bảng trạng thái deployment ở [5.2.1 Architecture Overview](../5.2-Architecture-Description/5.2.1-Architecture-Overview/)).
- **Việc bảo mật cố ý hoãn lại:** xoay vòng credential ADMIN và xử lý các seed account còn lại — không phải blocker cho môi trường DEV hiện tại, nhưng vẫn được theo dõi là việc còn mở.
- **Kiểm soát chi phí:** chiến lược "sleep" cho DEV khi không dùng (ví dụ pause Aurora, scale Chat Fargate service về 0 ngoài giờ làm việc) đã lên kế hoạch nhưng chưa triển khai.

### Sản phẩm bàn giao

- Workshop này, viết lại từng phần cho khớp với những gì thực sự đã deploy, kèm các bước có thể tái tạo và bằng chứng.
- Mô tả kiến trúc bao gồm request flow, lý do chọn AWS service, mô hình security/IAM, cách scale, và tình hình chi phí (phần này, [5.2](../5.2-Architecture-Description/)).
- Hướng dẫn deploy từng bước cho mỗi service, kế thừa từ runbook deployment nội bộ ([5.4](../5.4-Run-Local/), đang thực hiện).
- Ví dụ IAM policy và bảng test case kèm trạng thái bằng chứng.

### Định nghĩa hoàn thành

- Mọi AWS service được đánh dấu "Implemented" hoặc "Deployed" ở nơi khác trong báo cáo này đều có screenshot, log excerpt, hoặc command output tương ứng ở đâu đó trong Workshop này.
- Không bước nào ở đây được coi là thành công nếu thiếu mục Evidence tương ứng, kể cả khi mục đó hiện đang ghi `TODO` — quy tắc kế thừa nguyên vẹn từ Workshop MVP ban đầu, và vẫn là quy tắc đúng cho một hệ thống serverless với tám phần chuyển động.
