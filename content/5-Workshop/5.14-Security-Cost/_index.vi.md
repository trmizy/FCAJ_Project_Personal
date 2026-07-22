---
title: "5.14 Security and Cost Optimization"
date: 2026-07-15
weight: 14
chapter: false
pre: " <b> 5.14. </b> "
---

### Checklist bảo mật

- [ ] Đã áp dụng IAM least privilege ([5.11 IAM and Secrets](../5.11-IAM-Secrets/)).
- [ ] RDS là private (không public access), chỉ truy cập được từ Security Group của EC2.
- [ ] Đã bật encryption at rest trên RDS.
- [ ] Encryption in transit: TLS cho frontend (TODO — chưa cấu hình; MVP hiện phục vụ qua HTTP thuần, xem [5.15 Troubleshooting](../5.15-Troubleshooting/) và cân nhắc thêm certificate trước khi sử dụng thực tế).
- [ ] Secret nằm trong AWS Secrets Manager, không phải trong file `.env` trên host hay trong image.
- [ ] Không có AWS access key nào được commit vào source hay nhúng vào image.
- [ ] SSH giới hạn ở một IP cụ thể, không bao giờ `0.0.0.0/0`.
- [ ] Security Group tuân theo least privilege ([5.6 Network Infrastructure](../5.6-Network-Infrastructure/)).
- [ ] Có kế hoạch patch OS cho EC2 host (TODO: quyết định tần suất patch).
- [ ] Base image container được giữ tương đối mới (`node:20-alpine`, `nginx:1.25-alpine`, `postgres:15-alpine`).
- [ ] Dependency scanning (TODO: chưa chạy — cân nhắc `pnpm audit` hoặc công cụ scan container).
- [ ] Đã bật automated backup cho RDS.
- [ ] Retention của CloudWatch Log được đặt tường minh, không để không giới hạn.
- [ ] Giữ nguyên rate limiting ở gateway (`express-rate-limit`, đã có sẵn trong source — không xóa hay làm yếu đi khi triển khai).
- [ ] `JWT_SECRET` là giá trị mạnh, duy nhất trong Secrets Manager, không phải giá trị mẫu/mặc định từ `.env.example`.
- [ ] Giữ nguyên input validation (ứng dụng đã dùng `zod` để validate schema ở nhiều service — không bỏ qua khi điều chỉnh cho AWS).

{{% notice warning %}}
Checklist này mô tả các thực hành bảo mật hợp lý, có căn cứ cho một MVP mang tính học tập. Không khẳng định việc triển khai là "hoàn toàn an toàn" hay đã được hardening ở mức production — không triển khai nào là tuyệt đối an toàn, và báo cáo này không khẳng định điều ngược lại.
{{% /notice %}}

### Checklist tối ưu chi phí

- [ ] Chọn kích thước EC2 instance dựa trên mức sử dụng CPU/RAM đo được thực tế (xem [5.9 EC2 Deployment](../5.9-EC2-Deployment/)), không phải đoán.
- [ ] Dừng (không chỉ để nhàn rỗi) EC2 instance khi không dùng để demo hay kiểm thử.
- [ ] Dùng RDS instance class nhỏ, phù hợp cho lab/MVP, không phải instance quy mô production.
- [ ] Áp dụng ECR lifecycle policy để hết hạn image cũ/không có tag ([5.8 ECR](../5.8-ECR/)).
- [ ] Áp dụng S3 lifecycle policy nếu/khi S3 thực sự được triển khai ([5.10 S3 Storage](../5.10-S3-Storage/)).
- [ ] Đặt retention CloudWatch Log tường minh (không để "Never expire").
- [ ] **Cảnh báo chi phí NAT Gateway:** không dùng trong thiết kế MVP này; nếu thêm sau này, lưu ý chi phí theo giờ cộng chi phí xử lý dữ liệu theo GB trước khi bật.
- [ ] **Cảnh báo chi phí Elastic IP:** một Elastic IP không gắn với instance đang chạy sẽ phát sinh chi phí; giải phóng mọi Elastic IP không dùng.
- [ ] Xóa snapshot không còn cần thiết (snapshot RDS, snapshot EBS).
- [ ] Cân nhắc AWS Budgets như một lớp bảo vệ khuyến nghị (tùy chọn) để phát hiện chi tiêu bất ngờ — chưa cấu hình.
- [ ] Không nêu con số chi phí hàng tháng cố định ở bất kỳ đâu trong báo cáo này mà chưa kiểm tra [AWS Pricing Calculator](https://calculator.aws/).

{{% notice warning %}}
Không có con số cụ thể nào được nêu ở đây như một cam kết. Chi phí thực tế phụ thuộc vào Region, loại instance cuối cùng được chọn, và thời gian sử dụng — kiểm tra bằng AWS Pricing Calculator và AWS Cost Explorer trước và sau khi triển khai.
{{% /notice %}}
