---
title: "Worklog Tuần 5"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 1.5. </b> "
---

# WORKLOG TUẦN 5

### Mục tiêu tuần 5:

- Hoàn thành Module 3: Tối ưu hóa hệ thống, tập trung sâu vào System Performance và Cost Optimization strategies
- Hoàn thành Module 4: Hiện đại hóa ứng dụng bằng cách khám phá và implement Serverless và Microservices architectures

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Hoàn thành Module 3: Tối ưu hóa hệ thống | 17-7-2026 | 23-7-2026 | **Module 3 - Performance:** <br>15: https://000015.awsstudygroup.com/ <br>16: https://000016.awsstudygroup.com/ <br>17: https://000017.awsstudygroup.com/ <br>23: https://000023.awsstudygroup.com/ <br>24: https://000024.awsstudygroup.com/ <br>25: https://000025.awsstudygroup.com/ <br>35: https://000035.awsstudygroup.com/ <br>**Module 3 - Optimizing costs:** <br>32: https://000032.awsstudygroup.com/ <br>34: https://000034.awsstudygroup.com/ <br>40: https://000040.awsstudygroup.com/ <br>42: https://000042.awsstudygroup.com/ |
| Hoàn thành Module 4: Hiện đại hóa ứng dụng | 17-7-2026 | 23-7-2026 | **Module 4 - Modernize the application:** <br>47: https://000047.awsstudygroup.com/ <br>50: https://000050.awsstudygroup.com/ <br>51: https://000051.awsstudygroup.com/ <br>52: https://000052.awsstudygroup.com/ <br>53: https://000053.awsstudygroup.com/ <br>54: https://000054.awsstudygroup.com/ <br>55: https://000055.awsstudygroup.com/ <br>56: https://000056.awsstudygroup.com/ |

### Kết quả đạt được tuần 5:

**Tổng quan:**

Trong tuần intensive này, mình hoàn thành hai major tracks: system performance/cost optimization (Module 3) và application modernization (Module 4). Khối lượng lab work rất lớn bao gồm containerization, serverless computing, data lakes và cost analytics phức tạp. Module 4 cũng trả lời câu hỏi thiết kế lớn nhất của dự án: phần lớn Fitness Assistant không cần server.

**Lưu ý:** Một số sections trong modernization labs (cụ thể labs 47, 54, và 55) yêu cầu sử dụng AWS Cloud9. Do AWS Cloud9 hiện không khả dụng trong environment của mình, các sections này được strategically skipped, nhưng architectural concepts underlying vẫn được study thoroughly.

**Kiến thức lý thuyết học được:**

- **Performance & Cost Optimization:** Học deployment paradigms sử dụng Docker và Amazon ECS. Nắm vững CI/CD automation với AWS CodePipeline. Nghiên cứu Data Lake foundations và khám phá financial governance thông qua Savings Plans, EC2 right-sizing, và AWS Glue/Athena querying.

- **Modernization & Microservices:** Hiểu architectural patterns để migrate monolithic applications sang microservices. Khám phá decoupled messaging/eventing systems và integrate orchestration tools như AWS Step Functions.

- **Serverless Architecture:** Làm sâu expertise về serverless ecosystem sử dụng AWS Lambda, Amazon API Gateway, Serverless Application Model (SAM), Amazon Cognito cho identity, SQS/SNS cho async processing, và AppSync.

**Hands-on labs đã thực hiện:**

- Deploy thành công containerized applications trên Amazon ECS, integrate với automated CI/CD pipelines
- Configure enterprise storage solutions bao gồm File Storage Gateways và FSx for Windows, cùng với Data Lake optimizations
- Thực hiện advanced cost tracking và query analysis sử dụng AWS Glue và Amazon Athena
- Engineer và deploy fully serverless applications (ví dụ: Serverless Bookstore), bao gồm frontend API integration, SSL setup, CI/CD workflows, và CloudWatch/X-Ray distributed tracing
- Skip specific execution steps trong Labs 47, 54, và 55 do không thể provision AWS Cloud9 environments, nhưng theoretical framework cho Step Functions, Messaging/Eventing, và SPA configurations vẫn được review thoroughly

**Áp dụng vào Fitness Assistant:**

**Hướng hiện đại hóa (quyết định thiết kế chính):**
- Ứng dụng vốn đã tách thành các service (auth, user, fitness, gym, payment, ai, chat) chạy chung bằng Docker Compose ở local. Sáu service chỉ trả lời các HTTP request ngắn hoặc chạy job theo lịch, đúng với mô hình Lambda; chỉ có chat là phải giữ kết nối Socket.IO.
- Quyết định: chạy sáu HTTP service thành Lambda function phía sau một API Gateway HTTP API, thay cho container application gateway làm điểm vào duy nhất.
- Việc chạy theo lịch (settlement buổi tập, nhắc lịch tập, payout, đối soát thanh toán, làm mới tri thức AI) chuyển từ timer chạy trong process sang EventBridge Scheduler, gọi một jobs function riêng cho mỗi service.
- Việc AI tốn thời gian (tạo kế hoạch tập và dinh dưỡng) chuyển sang SQS queue và một worker function, để không HTTP call nào phải chờ quá giới hạn ~30 giây của API Gateway. Việc này cũng thay luôn hàng đợi Redis/BullMQ, vốn cần một cache cluster chạy liên tục.
- Chat vẫn chạy bằng container; chạy ở đâu được đánh giá ở [Tuần 6](../1.6-Week6/).

**Performance Optimization:**
- Với Lambda, memory là thông số sizing duy nhất (CPU tăng theo memory), nên không còn chuyện chọn instance type
- Cân nhắc CloudFront CDN cho frontend assets để giảm latency, hoãn lại cho đến khi site có domain và HTTPS

**Cost Optimization:**
- Dùng dịch vụ trả theo mức dùng cho tầng ứng dụng (Lambda, HTTP API vốn rẻ hơn REST API, SQS, EventBridge Scheduler) và Aurora Serverless v2 thay cho database instance kích thước cố định
- Liệt kê các khoản vẫn tốn tiền khi ứng dụng idle (NAT Gateway, load balancer, VPC endpoint, capacity tối thiểu của database); đây trở thành các dòng chính trong [ngân sách](../../2-Proposal/#budget)
- Một quy tắc đặt tên cho mọi resource (`fitness-assistant-dev-<service>-…`), để lọc chi phí và dọn dẹp theo từng service
- Research Savings Plans cho predictable workloads (Compute Savings Plans áp dụng cả cho Lambda và Fargate)
- Setup AWS Budgets và Cost Anomaly Detection alerts

**CI/CD:**
- Phác thảo pipeline: build package Lambda của từng service vào bucket deployments và image chat vào ECR, rồi cập nhật function và ECS service. Chưa xây dựng: việc deploy hiện làm thủ công và được ghi lại từng bước ở [5.4](../../5-Workshop/5.4-Deployment-Guide/); CI/CD là việc còn mở lớn nhất.

### Khó khăn gặp phải:

- **Cloud9 Limitation:** Không access được AWS Cloud9 (có thể do region restrictions hoặc account limitations), dẫn đến skip một số hands-on steps trong labs 47, 54, 55. Tuy nhiên conceptual learning vẫn được maintain thông qua đọc documentation và video tutorials.

- **Chuyển từ Docker Compose sang serverless:** Trong Docker Compose, mỗi service là một container chạy liên tục và gọi các service khác qua hostname. Trên Lambda không có process chạy liên tục và cũng không có hostname, nên timer trong process, hàng đợi Redis và các lời gọi giữa service đều phải đổi cách làm.

- **Serverless Cold Start Trade-offs:** Khi research Lambda migration, nhận ra cold start latency có thể impact user experience cho synchronous APIs. Cần evaluate carefully which workloads phù hợp với serverless.

- **Cost Calculation Complexity:** AWS cost model rất granular (per request, per GB-second, data transfer costs). Difficult để forecast costs accurately khi planning serverless migration.

### Cách giải quyết:

- **Cloud9 Workaround:** Sử dụng local development environment với AWS CLI và SAM CLI để simulate Cloud9 workflows. Đọc lab documentation thoroughly để understand intended outcomes.

- **Chuyển đổi:** Liệt kê mọi phần chạy liên tục của từng service và chọn cho mỗi phần một dịch vụ managed thay thế: timer → EventBridge Scheduler và jobs function, Redis/BullMQ → SQS và worker, socket → container chat trên ECS, lời gọi HTTP giữa các service → gọi thẳng Lambda theo đúng ARN của function.

- **Cold Start Mitigation:** Chấp nhận cold start cho môi trường DEV, nơi nó chỉ ảnh hưởng request đầu tiên sau một khoảng idle. Provisioned concurrency là phương án cho production, nên các API đồng bộ không cần ở lại trên container.

- **Cost Forecasting:** Sử dụng AWS Pricing Calculator để estimate costs. Setup granular billing alerts. Lên kế hoạch deploy từng service một để kiểm tra chi phí sau mỗi bước.

### Kỹ năng / Dịch vụ AWS đã học:

**Services - Containerization & CI/CD:**
- Amazon ECS (Elastic Container Service)
- Amazon ECR (Elastic Container Registry)
- AWS CodePipeline
- AWS CodeBuild
- AWS CodeDeploy

**Services - Serverless:**
- AWS Lambda
- Amazon API Gateway
- AWS SAM (Serverless Application Model)
- Amazon Cognito
- Amazon SQS/SNS
- AWS AppSync
- AWS Step Functions

**Services - Storage & Data:**
- AWS Storage Gateway
- Amazon FSx
- AWS Glue
- Amazon Athena
- Data Lake architecture

**Services - Cost & Monitoring:**
- AWS Cost Explorer
- AWS Budgets
- Savings Plans
- Amazon CloudWatch
- AWS X-Ray (distributed tracing)

**Skills:**
- Container orchestration với ECS
- CI/CD pipeline design và implementation
- Serverless architecture patterns
- Cost optimization strategies
- Data Lake design fundamentals
- Distributed tracing và observability

### Liên kết với Fitness Assistant Architecture:

**Immediate Applications:**
- Sáu HTTP service trên Lambda phía sau một API Gateway HTTP API
- Job theo lịch trên EventBridge Scheduler; tác vụ AI dài qua SQS và worker function
- CloudWatch Logs cho mọi function; X-Ray tracing bổ sung sau

**Future Enhancements:**
- CI/CD pipeline cho package Lambda và image chat
- CloudFront và HTTPS cho frontend
- Build data lake cho workout analytics và user behavior analysis

### Liên kết Workshop tương ứng:

- [5.2.4 Dịch vụ AWS và lý do lựa chọn](../../5-Workshop/5.2-Architecture-Description/5.2.4-AWS-Services-Selection/) - Vì sao chọn Lambda, API Gateway, SQS và EventBridge Scheduler
- [5.4.2 Auth Service và API Gateway](../../5-Workshop/5.4-Deployment-Guide/5.4.2-Auth-Service-API-Gateway/) - Service đầu tiên được triển khai theo mô hình này
