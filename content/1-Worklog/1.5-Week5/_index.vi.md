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

Trong tuần intensive này, mình hoàn thành hai major tracks: system performance/cost optimization (Module 3) và application modernization (Module 4). Khối lượng lab work rất lớn bao gồm containerization, serverless computing, data lakes và cost analytics phức tạp.

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

**Performance Optimization:**
- Evaluate containerization strategy: migrate từ Docker Compose sang Amazon ECS cho better scaling và management
- Design CI/CD pipeline: GitHub → AWS CodePipeline → CodeBuild → ECR → ECS deployment
- Consider CloudFront CDN cho frontend assets để reduce latency

**Cost Optimization:**
- Right-sizing analysis: monitor EC2 utilization, identify opportunities để downsize instances
- Implement tagging strategy cho cost allocation by service (auth-service, fitness-service, ai-service)
- Research Savings Plans và Reserved Instances cho predictable workloads
- Setup AWS Budgets và Cost Anomaly Detection alerts

**Modernization Path:**
- Evaluate serverless migration cho specific workloads:
  - Notification service → Lambda + SQS
  - Image processing (nutrition labels) → Lambda triggered by S3
  - Daily stats aggregation → Lambda với scheduled EventBridge rules
- Plan microservices decomposition strategy (future enhancement khi scale)
- Consider API Gateway để replace application gateway container (better managed service)

### Khó khăn gặp phải:

- **Cloud9 Limitation:** Không access được AWS Cloud9 (có thể do region restrictions hoặc account limitations), dẫn đến skip một số hands-on steps trong labs 47, 54, 55. Tuy nhiên conceptual learning vẫn được maintain thông qua đọc documentation và video tutorials.

- **Containerization Complexity:** Hiểu difference giữa Docker Compose (local dev) và ECS (production) requires learning curve về task definitions, services, và clusters.

- **Serverless Cold Start Trade-offs:** Khi research Lambda migration, nhận ra cold start latency có thể impact user experience cho synchronous APIs. Cần evaluate carefully which workloads phù hợp với serverless.

- **Cost Calculation Complexity:** AWS cost model rất granular (per request, per GB-second, data transfer costs). Difficult để forecast costs accurately khi planning serverless migration.

### Cách giải quyết:

- **Cloud9 Workaround:** Sử dụng local development environment với AWS CLI và SAM CLI để simulate Cloud9 workflows. Đọc lab documentation thoroughly để understand intended outcomes.

- **ECS Learning:** Vẽ comparison diagram giữa Docker Compose concepts và ECS equivalents. Practice với simple containerized apps trước khi apply vào Fitness Assistant.

- **Cold Start Mitigation:** Research provisioned concurrency cho critical Lambda functions. Plan hybrid approach: keep synchronous APIs trên containers, async workloads trên Lambda.

- **Cost Forecasting:** Sử dụng AWS Pricing Calculator để estimate costs. Setup granular billing alerts. Plan phased migration để monitor costs incrementally.

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
- Containerize tất cả services và deploy lên ECS thay vì single EC2
- Setup CI/CD pipeline cho automated deployments
- Implement CloudWatch monitoring và X-Ray tracing

**Future Enhancements:**
- Migrate notification service sang Lambda + SQS
- Implement API Gateway cho better API management
- Build data lake cho workout analytics và user behavior analysis

### Liên kết Workshop tương ứng:

- [5.6 Network Infrastructure](../../5-Workshop/5.6-Network-Infrastructure/) - VPC design cho ECS
- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - Container deployment strategies
