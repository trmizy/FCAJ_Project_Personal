---
title: "Worklog Tuần 6"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 1.6. </b> "
---

# WORKLOG TUẦN 6

### Mục tiêu tuần 6:

- Hoàn thành Module 5: Container services
- Nắm vững orchestration và deployment của containerized applications trên Lightsail, ECS, và EKS
- Tham gia cộng đồng chuyên nghiệp và tích hợp sâu hơn vào môi trường làm việc

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Học và hoàn thành Module 5: Container services | 24-7-2026 | 30-7-2026 | 46: https://000046.awsstudygroup.com/ <br>67: https://000067.awsstudygroup.com/ <br>152: https://000152.awsstudygroup.com/ |

### Kết quả đạt được tuần 6:

**Tổng quan:**

Trong tuần này, mình tập trung hoàn toàn vào AWS Container services (Module 5), khám phá cách chạy và orchestrate containers ở các mức độ complexity khác nhau sử dụng Amazon Lightsail, ECS, và EKS. Ngoài việc học kỹ thuật, mình còn tham gia sâu hơn vào cộng đồng chuyên nghiệp và môi trường công ty.

**Kiến thức lý thuyết học được:**

- **Amazon Lightsail Containers:** Học cách deploy và chạy containerized applications nhanh chóng trong môi trường đơn giản với predictable pricing.

- **Amazon ECS & Fargate:** Hiểu architectural strategies để modernize legacy Monolithic applications thành Microservices sử dụng Docker, Amazon ECS, và serverless AWS Fargate compute engine.

- **Amazon EKS & CI/CD:** Nắm vững fundamentals của Kubernetes cluster management trên AWS (EKS) và học cách thiết lập continuous integration/delivery (CI/CD) pipeline sử dụng AWS CodePipeline cho automated container deployments.

- Có được valuable networking và professional experience thông qua việc attend community events và integrate vào workplace.

**Hands-on labs đã thực hiện:**

- Deploy thành công containerized application sử dụng Amazon Lightsail Containers
- Migrate monolithic application sang microservices architecture dùng Docker, orchestrating deployment thông qua ECS và Fargate
- Configure robust CI/CD pipeline cho Amazon EKS sử dụng AWS CodePipeline để automate Kubernetes deployments

**Áp dụng vào Fitness Assistant:**

**Container Strategy Evaluation:**

Sau [Tuần 5](../1.5-Week5/), sáu trong bảy service đã được lên kế hoạch chạy trên Lambda. Câu hỏi của tuần này hẹp hơn: service duy nhất cần process chạy liên tục nên chạy ở đâu? Đó là Chat, service giữ một kết nối Socket.IO cho mỗi người dùng. Mình so sánh ba nền tảng trong module:

1. **Amazon Lightsail Containers:**
   - **Pros:** Simple setup, predictable pricing ($10-40/month), good cho MVP
   - **Cons:** Scaling hạn chế, và khó tích hợp với VPC private, IAM role riêng cho từng service và Secrets Manager mà phần còn lại của thiết kế đang dùng
   - **Decision:** Không dùng

2. **Amazon ECS with Fargate:**
   - **Pros:** Serverless (không manage servers), good AWS integration, cost-effective cho small-medium scale
   - **Cons:** Vendor lock-in (AWS-specific), learning curve
   - **Decision:** **Chọn cho Chat service.** Cùng cluster còn chạy được các task một lần, sau này dùng cho job migration database

3. **Amazon EKS (Kubernetes):**
   - **Pros:** Industry standard, portable, powerful orchestration
   - **Cons:** Setup phức tạp, tốn phí control plane cho mỗi cluster, quá mức cần thiết cho một container service duy nhất
   - **Decision:** Không cần ở quy mô này

**Implementation Plan cho Chat Service:**

**Phase 1 - Image và registry:**
- Build production image của chat-service cho `linux/amd64`
- Push lên một private repository Amazon ECR cùng region

**Phase 2 - Task và service:**
- Một task definition: 0.5 vCPU / 1 GB, container port 3005, database URL và internal secret được inject từ Secrets Manager
- Một ECS service dùng Fargate launch type trong các private application subnet

**Phase 3 - Load balancer và routing:**
- Application Load Balancer internet-facing ở public subnet, với IP target group được health check trên `/health`
- Bật stickiness cho target group và tăng idle timeout, để kết nối Socket.IO không bị cắt
- Listener rule trả 404 cho `/internal/*` và `/metrics`; các REST call dưới `/chat/*` đi tới ALB qua API Gateway

**Về sau:**
- Chỉ chạy nhiều hơn một Chat task sau khi có Socket.IO adapter dùng chung (hiện trạng thái phiên nằm trong memory)
- CI/CD cho image; CloudWatch Container Insights và alarm cho health của target

**Architecture Comparison:**

*Kế hoạch đầu tiên (lift-and-shift lên một host):*
```
User → EC2 (Docker Compose với tất cả service, Ollama, Qdrant, Redis) → RDS
```

*Thiết kế được chọn:*
```
Browser → S3 static website (frontend)
Browser → API Gateway (HTTP API) → Lambda (auth, user, fitness, gym, payment, ai) → Aurora PostgreSQL
Browser → Chat ALB (Socket.IO; REST qua API Gateway /chat/*) → ECS Fargate (chat) → Aurora PostgreSQL
```

### Khó khăn gặp phải:

- **ECS vs EKS Decision:** Ban đầu confused về khi nào dùng ECS vs EKS. ECS đơn giản hơn nhưng AWS-specific, EKS industry standard nhưng complex hơn nhiều.

- **Task Definition Complexity:** ECS Task Definitions có nhiều configuration options (CPU, memory, networking mode, volume mounts, environment variables, secrets). Khó để optimize correctly.

- **Fargate Pricing Model:** Fargate tính tiền theo vCPU và memory được cấp mỗi giây, và load balancer phía trước là chi phí cố định hằng tháng. Với lượng truy cập DEV, đường Chat chạy liên tục tốn hơn cả sáu Lambda service cộng lại.

- **Gọi giữa các service:** Trong Docker Compose, các service gọi nhau qua hostname trên cùng một network. Lambda function và Fargate task đứng sau load balancer đều không có điều đó, còn AWS Cloud Map cho service discovery lại có learning curve riêng.

### Cách giải quyết:

- **Platform Decision:** ECS trên Fargate chỉ cho Chat: production-ready, tích hợp tốt với AWS, độ phức tạp vừa phải, rẻ hơn EKS. EKS vẫn là lựa chọn nếu sau này dự án cần Kubernetes hoặc multi-cloud.

- **Task Definitions:** Bắt đầu từ task definition nhỏ nhất chạy được (một container, một port, secret lấy từ Secrets Manager) và giữ mỗi thay đổi thành một revision mới.

- **Cost Management:** Dùng AWS Pricing Calculator để ước tính chi phí Fargate và ALB. Giữ Chat ở một task nhỏ, có thể scale về 0 giữa các đợt kiểm thử; chỉ cân nhắc Savings Plans khi có baseline ổn định.

- **Gọi giữa các service:** Không dùng Cloud Map: lời gọi nội bộ là gọi thẳng Lambda theo đúng ARN của function, kèm một internal secret dùng chung, và Chat task cũng gọi Auth và User theo cách đó. API Gateway không có route `/internal/*`, nên các endpoint này không bao giờ public.

### Kỹ năng / Dịch vụ AWS đã học:

**Services:**
- Amazon Lightsail Containers
- Amazon ECS (Elastic Container Service)
- AWS Fargate (serverless compute for containers)
- Amazon EKS (Elastic Kubernetes Service)
- AWS CodePipeline (cho container CI/CD)
- Amazon ECR (Elastic Container Registry)
- AWS Cloud Map (service discovery)
- Application Load Balancer (ALB)
- AWS Copilot CLI

**Skills:**
- Container orchestration strategies
- ECS vs EKS evaluation và selection
- Fargate serverless container management
- Kubernetes fundamentals (EKS)
- CI/CD pipeline design cho containers
- Microservices deployment patterns
- Service discovery và inter-service communication
- Container cost optimization

### Liên kết với Fitness Assistant Architecture:

**Immediate Actions:**
- Dockerfile production cho chat-service (các service khác được đóng gói thành file ZIP cho Lambda thay vì image)
- Một task definition và một ECS service cho Chat
- ALB rule cho Socket.IO và để ẩn các path nội bộ

**Medium-term Goals:**
- Implement full CI/CD pipeline
- Socket.IO adapter dùng chung trước khi scale Chat lên nhiều task
- Alarm cho health của Chat target

### Liên kết Workshop tương ứng:

- [5.4.1 Hạ tầng mạng dùng chung](../../5-Workshop/5.4-Deployment-Guide/5.4.1-Shared-Network/) - VPC, subnet và NAT setup
- [5.4.10 Chat Service trên ECS Fargate](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/) - Triển khai container trên ECS Fargate phía sau ALB
