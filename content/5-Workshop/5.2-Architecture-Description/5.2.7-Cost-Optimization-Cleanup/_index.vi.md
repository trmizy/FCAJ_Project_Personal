---
title: "5.2.7 Tối ưu chi phí và dọn dẹp"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.2.7. </b> "
---

### Đòn bẩy chi phí đang dùng

- **Lambda cho sáu trong bảy service** — trả tiền theo lần gọi thay vì một instance chạy cả ngày; lưu lượng DEV và các job theo lịch phần lớn nằm trong free tier của Lambda.
- **Aurora Serverless v2 với floor thấp** — 0.5 ACU khi đang deploy các service (tránh auto-pause làm nhiễu smoke test), thiết kế để về 0 ACU khi môi trường idle.
- **Một cluster Aurora với bảy logical database** thay vì bảy cluster.
- **OpenSearch Serverless NextGen ở 0–2 OCU** — scale về 0 khi idle thay vì mức tối đa mặc định 96 OCU.
- **Bedrock theo nhu cầu** — không tốn chi phí host model; throttling theo route cho các route AI ngăn client hoặc bug frontend tạo lượng token mất kiểm soát.
- **S3 static website cho frontend** — chi phí gần như bằng 0 cho một bản build không đổi lúc request.
- **Một NAT Gateway** cho cả VPC DEV thay vì mỗi Availability Zone một cái.
- **Fargate task đúng kích thước** — 0.5 vCPU / 1 GB cho Chat Service; task migrator (1 vCPU / 2 GB) chỉ tồn tại khi đang chạy.
- **Interface VPC endpoint** cho Secrets Manager và OpenSearch giữ traffic đó khỏi phí xử lý theo GB của NAT Gateway.

### Chi phí cố định nằm ở đâu

Khi gần như mọi thứ tính theo mức dùng, các khoản tính theo giờ vẫn chạy kể cả khi không ai dùng là **NAT Gateway**, **Chat ALB**, **Fargate task**, **capacity tối thiểu của Aurora**, **interface VPC endpoint** và **địa chỉ IPv4 public** (Elastic IP của NAT và các địa chỉ của ALB). [Phần ngân sách trong Proposal](../../../2-Proposal/#budget) ước tính các khoản này; chúng là mục tiêu của chế độ "sleep" bên dưới.

### Đã lên kế hoạch, chưa tự động hoá

- **Chế độ sleep cho DEV** — Aurora về 0 ACU, Chat service về 0 task ngoài giờ, và xoá NAT Gateway giữa các phiên kiểm thử (xem [5.7](../../5.7-Cleanup/#pause)).
- **CloudFront** đứng trước bucket frontend private, thêm cache và HTTPS.
- **Cảnh báo AWS Budgets** trên account để phát hiện khoản phí bất thường trong vòng một ngày.

### Dọn dẹp

Quy trình xoá toàn bộ resource của kiến trúc này theo đúng thứ tự phụ thuộc nằm ở [5.7 Dọn dẹp tài nguyên](../../5.7-Cleanup/).
