---
title: "Tuần 7"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 1.7. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Tạo Amazon ECR repository cho từng service thuộc phạm vi MVP.
- Build, tag và push Docker image production.
- Tạo IAM Role để EC2 dùng khi pull image từ ECR.

### Công việc đã thực hiện

- Tạo một ECR repository cho mỗi service trong MVP (frontend, gateway, auth-service, user-service, fitness-service, ai-service), khớp với `Dockerfile`/`Dockerfile.production.example` đã xây ở Tuần 3.
- Đăng nhập Docker vào ECR (`aws ecr get-login-password`), build từng image ở local, gắn tag theo URI của ECR repository, rồi push lên.
- Xác nhận từng image đã xuất hiện trong ECR repository tương ứng với đúng tag.
- Soạn thảo IAM policy chỉ cấp đúng quyền pull ECR mà EC2 cần (`ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`), và tạo IAM Role cho EC2 gắn kèm policy này.
- Ghi chú rõ ràng rằng `gym-service` và `payment-service` hiện chưa có Dockerfile production trong repository nguồn, nên **không** được build hoặc push trong tuần này; đây được ghi nhận là mục còn mở trong phần Hướng phát triển thay vì bỏ qua âm thầm.

### Kết quả đạt được

- Đã tạo và đưa image lên ECR repository cho các service thuộc MVP.
- Đã định nghĩa IAM Role cho EC2 với quyền pull ECR theo nguyên tắc least privilege.
- TODO: Ghi lại tag image cuối cùng dùng cho lần deploy đầu tiên.

### Khó khăn

- Lỗi xác thực ở lần `docker login` đầu tiên vào ECR (token hết hạn / sai region).

### Cách giải quyết

- Chạy lại `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com` và xác nhận profile/region của AWS CLI khớp với region của ECR repository.

### Kỹ năng / Dịch vụ AWS đã học

- Tạo repository Amazon ECR, vòng đời image, và thiết kế IAM policy least-privilege cho quyền pull ECR.

### Bằng chứng cần bổ sung

- TODO: Screenshot ECR repository đã có image được push.
- TODO: Output terminal chạy `docker push` cho từng service.
- TODO: Screenshot IAM Role/policy (đã che account ID).

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Tạo ECR repository | [TODO_DATE] | [TODO_DATE] | [Workshop 5.8](../../5-Workshop/5.8-ECR/) |
| 2 | Build, tag và push image | [TODO_DATE] | [TODO_DATE] | [Workshop 5.8](../../5-Workshop/5.8-ECR/) |
| 3 | Soạn thảo và gắn IAM Role cho EC2 | [TODO_DATE] | [TODO_DATE] | [Workshop 5.11](../../5-Workshop/5.11-IAM-Secrets/) |
| 4 | Xác minh image và quyền hạn | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã tạo ECR repository cho các service MVP
- [ ] Đã build, tag và push image
- [ ] Đã tạo IAM Role với policy pull ECR least-privilege
- [ ] Đã ghi lại rõ ràng vấn đề thiếu Dockerfile của `gym-service`/`payment-service`

### Liên kết Workshop tương ứng

- [5.8 ECR](../../5-Workshop/5.8-ECR/)
