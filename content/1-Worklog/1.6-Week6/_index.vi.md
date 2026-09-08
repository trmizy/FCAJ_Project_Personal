---
title: "Tuần 6"
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

Sau khi học 3 container platforms, mình evaluate phương án phù hợp nhất cho Fitness Assistant:

1. **Amazon Lightsail Containers:**
   - **Pros:** Simple setup, predictable pricing ($10-40/month), good cho MVP
   - **Cons:** Limited scaling, không suitable cho production growth
   - **Decision:** Có thể dùng cho initial prototype testing

2. **Amazon ECS with Fargate:**
   - **Pros:** Serverless (không manage servers), good AWS integration, cost-effective cho small-medium scale
   - **Cons:** Vendor lock-in (AWS-specific), learning curve
   - **Decision:** **Recommended choice cho MVP** - balance giữa simplicity và production-readiness

3. **Amazon EKS (Kubernetes):**
   - **Pros:** Industry standard, portable, powerful orchestration
   - **Cons:** Complex setup, higher cost, overkill cho current scale
   - **Decision:** Future consideration khi scale lên hoặc cần multi-cloud portability

**Implementation Plan cho Fitness Assistant:**

**Phase 1 - ECS Migration (Immediate):**
- Containerize tất cả services (auth, user, fitness, ai, gateway)
- Create ECS Task Definitions cho mỗi service
- Setup ECS Service với Fargate launch type
- Configure Application Load Balancer cho routing
- Migrate từ single EC2 → ECS cluster

**Phase 2 - CI/CD Pipeline:**
- GitHub repository → AWS CodePipeline trigger on push
- CodeBuild stage: build Docker images, run tests
- Push images → Amazon ECR
- CodeDeploy stage: deploy to ECS với blue/green deployment
- Automated rollback on failure

**Phase 3 - Advanced Features:**
- Service Auto Scaling based on CPU/memory
- Service Mesh với AWS App Mesh cho advanced traffic management
- CloudWatch Container Insights cho detailed monitoring

**Architecture Comparison:**

*Current (MVP on EC2):*
```
User → EC2 (Docker Compose với all services) → RDS
```

*After ECS Migration:*
```
User → ALB → ECS Services (auth/user/fitness/ai services độc lập) → RDS
                ↓
            Fargate Tasks (auto-scale)
```

### Khó khăn gặp phải:

- **ECS vs EKS Decision:** Ban đầu confused về khi nào dùng ECS vs EKS. ECS đơn giản hơn nhưng AWS-specific, EKS industry standard nhưng complex hơn nhiều.

- **Task Definition Complexity:** ECS Task Definitions có nhiều configuration options (CPU, memory, networking mode, volume mounts, environment variables, secrets). Khó để optimize correctly.

- **Fargate Pricing Model:** Fargate pricing based on vCPU và memory allocated per second. Khó estimate costs accurately so với flat EC2 pricing.

- **Service Discovery:** Khi migrate sang microservices trên ECS, services cần communicate với nhau. AWS Cloud Map cho service discovery có learning curve.

### Cách giải quyết:

- **Platform Decision:** Quyết định dùng ECS cho MVP dựa trên criteria: production-ready, AWS-integrated, manageable complexity, lower cost than EKS. Reserve EKS cho future nếu cần Kubernetes expertise hoặc multi-cloud.

- **Task Definitions:** Start với simple task definitions, iterate dần. Use AWS Copilot CLI (tool đơn giản hóa ECS deployments) cho initial setup, sau đó refine manually.

- **Cost Management:** Use AWS Pricing Calculator để estimate Fargate costs. Setup CloudWatch alarms cho cost thresholds. Consider Savings Plans cho Fargate nếu có predictable baseline.

- **Service Discovery:** Implement AWS Cloud Map cho service-to-service communication. Combine với Environment Variables cho flexibility.

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
- Design ECS cluster architecture
- Create Dockerfiles cho production (nếu chưa có)
- Plan Task Definitions cho mỗi service
- Design ALB routing rules

**Medium-term Goals:**
- Implement full CI/CD pipeline
- Setup auto-scaling policies
- Migrate production traffic từ EC2 → ECS

### Liên kết Workshop tương ứng:

- [5.6 Network Infrastructure](../../5-Workshop/5.6-Network-Infrastructure/) - VPC và ALB setup
- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - Container migration strategy
