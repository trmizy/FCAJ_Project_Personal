---
title: "Workshop"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5. </b> "
draft: false
---

# Workshop — Triển khai Gymini (Fitness Assistant) trên AWS Serverless

Workshop này ghi lại cách ứng dụng Fitness Assistant (tên sản phẩm **Gymini**) được triển khai lên AWS dưới dạng môi trường DEV theo hướng serverless tại `ap-southeast-1`: sáu microservice chạy trên Lambda phía sau Amazon API Gateway, một service ECS Fargate cho chat real-time, Amazon Aurora PostgreSQL Serverless v2, Amazon Bedrock cho AI, và OpenSearch Serverless cho vector search. Mọi bước đều được dựng lại từ runbook triển khai ghi chép trong lúc xây dựng hệ thống, kèm screenshot console gốc.

#### Nội dung

1. [5.1 Tổng quan](5.1-Overview/)
2. [5.2 Mô tả kiến trúc](5.2-Architecture-Description/)
3. [5.3 Chuẩn bị](5.3-Prerequisites/)
4. [5.4 Hướng dẫn triển khai](5.4-Deployment-Guide/)
5. [5.5 Kiểm thử & xác nhận](5.5-Test-Validation/)
6. [5.6 Demo](5.6-Demo/)
7. [5.7 Dọn dẹp tài nguyên](5.7-Cleanup/)
8. [5.8 Xử lý sự cố và hướng phát triển](5.8-Troubleshooting/)
