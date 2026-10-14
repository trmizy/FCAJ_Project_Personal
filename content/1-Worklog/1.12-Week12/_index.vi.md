---
title: "Worklog Tuần 12"
date: 2026-07-15
weight: 12
chapter: false
pre: " <b> 1.12. </b> "
draft: false
---

# WORKLOG TUẦN 12

### Mục tiêu tuần 12:

- Finalize và aggregate 12-week technical worklog documentation cho culminating internship report

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Finalize và aggregate 12-week technical worklog documentation cho culminating internship report | 19-10-2026 | 19-10-2026 | |

### Kết quả đạt được tuần 12:

**Tổng quan:**

Trong final week này, primary operational focus của mình là review, refine, và aggregate comprehensive 12-week worklog documentation. Effort này serve để systematize all knowledge và outcomes achieved throughout internship và project lifecycle, ensuring full readiness cho final internship report.

**Kiến thức lý thuyết học được:**

- **Documentation and Reporting:** Enhanced skills trong việc systematize information và present technical documentation theo clear, professional, và logical manner.

- **Retrospective Assessment:** Systematically reviewed entire project lifecycle, từ ideation và architectural design đến infrastructure deployment và environment testing.

**Hands-on labs đã thực hiện:**

- Completed detailed documentation cho all internship weeks within worklog system
- Conducted thorough reviews của spelling, grammar, và overall document formatting
- Packaged all finalized materials để support polished và professional final report

**Fitness Assistant Project Summary:**

**Kiến trúc đã triển khai (môi trường DEV, `ap-southeast-1`):**
- Sáu service trên AWS Lambda (12 function chạy lâu dài cho HTTP, job theo lịch và AI worker) phía sau một API Gateway HTTP API
- Aurora PostgreSQL Serverless v2: một cluster với bảy logical database, credential trong Secrets Manager
- Chat (REST + Socket.IO) trên ECS Fargate phía sau Application Load Balancer
- AI trên Amazon Bedrock (Nova Pro, Cohere Embed Multilingual v3) với vector search trên OpenSearch Serverless, tác vụ dài qua SQS và 13 schedule của EventBridge Scheduler
- Mạng private: Lambda, Fargate và Aurora nằm trong private subnet, một NAT Gateway, VPC endpoint cho Secrets Manager và OpenSearch
- Dữ liệu chuyển từ các database local bằng một Fargate task chạy một lần: 7/7 database đã restore, 23/23 foreign key đã xác nhận

**Technical Skills Gained:**
- Serverless: AWS Lambda, API Gateway (HTTP API), Amazon SQS, EventBridge Scheduler
- Database: Aurora PostgreSQL Serverless v2, schema migration chạy bằng các Lambda function riêng, restore dump bằng ECS task
- Container: Docker, Amazon ECR, ECS Fargate, Application Load Balancer
- AI/ML: Amazon Bedrock và vector search trên OpenSearch Serverless trong dự án; SageMaker ở Module 7
- Mạng và bảo mật: thiết kế VPC, security group tham chiếu lẫn nhau, IAM quyền tối thiểu cho từng function, Secrets Manager
- Data analytics (Glue, Athena, QuickSight) từ Module 6

**Community Contributions:**
- Published technical blogs về cost optimization và security
- Participated trong FCAJ Community Day events
- Shared knowledge với AWS Study Group VN community

**Project Outcomes:**
- Mô tả kiến trúc và sơ đồ ([Workshop 5.2](../../5-Workshop/5.2-Architecture-Description/))
- Hướng dẫn triển khai từng bước kèm screenshot console ([Workshop 5.4](../../5-Workshop/5.4-Deployment-Guide/))
- Kế hoạch và kết quả kiểm thử ([5.5](../../5-Workshop/5.5-Test-Validation/)): Auth và User đã kiểm thử end-to-end; Fitness, Gym, Payment, AI, Chat và frontend đã deploy, đang chờ lượt kiểm thử end-to-end cuối
- Ước tính chi phí kèm "chế độ ngủ" khi idle ([Proposal mục 8](../../2-Proposal/#budget)) và thứ tự dọn dẹp đầy đủ ([5.7](../../5-Workshop/5.7-Cleanup/))
- Còn mở: CI/CD pipeline, CloudWatch alarm, HTTPS với CloudFront
