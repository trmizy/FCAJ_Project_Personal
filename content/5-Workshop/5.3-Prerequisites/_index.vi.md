---
title: "Chuẩn bị"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.3. </b> "
---

Trước khi làm theo [Hướng dẫn triển khai](../5.4-Deployment-Guide/), cần chuẩn bị:

1. [5.3.1 Tài khoản AWS và quyền truy cập](5.3.1-AWS-Account-Permissions/) — account, IAM identity dùng trên console, và bước bật quyền truy cập model Amazon Bedrock một lần.
2. [5.3.2 Region triển khai](5.3.2-Deployment-Region/) — vì sao mọi thứ chạy ở `ap-southeast-1` (Singapore), kể cả Bedrock và OpenSearch Serverless.
3. [5.3.3 Công cụ local](5.3.3-Local-Tools/) — những gì cần trên máy để build Lambda artifact và container image.
