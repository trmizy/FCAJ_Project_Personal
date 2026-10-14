---
title: "5.2 Mô tả kiến trúc"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2. </b> "
---

Phần này mô tả kiến trúc thực sự đã deploy cho môi trường DEV — một bản thiết kế lại serverless-first từ kế hoạch MVP EC2 + Docker Compose trước đó. Chia làm bảy trang, mỗi trang phủ một mối quan tâm riêng:

1. [5.2.1 Architecture Overview](5.2.1-Architecture-Overview/) — các thành phần, hạ tầng dùng chung, và hình dạng tổng thể của hệ thống.
2. [5.2.2 Architecture Diagram](5.2.2-Architecture-Diagram/) — sơ đồ thành phần, render trực tiếp trong báo cáo.
3. [5.2.3 Main Request Flows](5.2.3-Main-Request-Flows/) — luồng Core API, luồng Chat, và luồng xử lý nền, đi qua từng bước.
4. [5.2.4 AWS Services and Selection Rationale](5.2.4-AWS-Services-Selection/) — service AWS nào dùng cho việc gì, và tại sao chọn nó thay vì phương án khác.
5. [5.2.5 Security and IAM](5.2.5-Security-IAM/) — cô lập network, IAM least-privilege theo từng service, và cách xử lý secret.
6. [5.2.6 Scalability and Operations](5.2.6-Scalability-Operations/) — mỗi thành phần scale thế nào, và khoảng trống vận hành nào còn mở.
7. [5.2.7 Cost Optimization and Clean-up](5.2.7-Cost-Optimization-Cleanup/) — các đòn bẩy chi phí đang dùng và những cái còn đang lên kế hoạch.

{{% notice note %}}
Kiến trúc này được tài liệu hoá từ một runbook deployment nội bộ ghi lại xuyên suốt project (các bước console, environment variable, và screenshot đúng lúc hệ thống được xây dựng thật). Chỗ nào chi tiết chưa được xác nhận trong runbook đó, nó được đánh dấu thay vì đoán — nhất quán với Definition of Done ở [5.1 Overview](../5.1-Overview/).
{{% /notice %}}
