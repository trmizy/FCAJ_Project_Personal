---
title: "5.11 IAM and Secrets"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 5.11. </b> "
---

### IAM Role cho EC2

Một IAM Role duy nhất gắn với instance profile của EC2, giới hạn đúng những gì MVP thực sự cần: pull image từ ECR, ghi log/metric vào CloudWatch, và đọc secret từ Secrets Manager.

Xem [`/files/policies/ec2-ecr-policy.example.json`](/files/policies/ec2-ecr-policy.example.json) để có policy mẫu dùng ARN placeholder.

### Least Privilege

- Không dùng `"Action": "*"` và không dùng `"Resource": "*"` khi có thể chỉ định ARN cụ thể.
- Quyền ECR giới hạn ở đúng ARN repository đã tạo ở [5.8 ECR](../5.8-ECR/), không phải toàn bộ ECR.
- Quyền Secrets Manager giới hạn ở đúng ARN secret được dùng trong lần triển khai này.

### Quyền pull ECR

`ecr:GetAuthorizationToken` (bắt buộc phải là `Resource: "*"` — action cụ thể này không hỗ trợ giới hạn ở cấp resource), cộng với `ecr:BatchGetImage` và `ecr:GetDownloadUrlForLayer` giới hạn ở ARN repository thuộc MVP.

### Quyền CloudWatch

`logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, `cloudwatch:PutMetricData` — giới hạn ở các log group dùng cho project này, ở những chỗ mô hình IAM của CloudWatch cho phép giới hạn theo resource.

### Quyền S3

Không gắn cho role EC2 trong MVP, vì ứng dụng hiện chưa sử dụng S3 (xem [5.10 S3 Storage](../5.10-S3-Storage/), trạng thái Planned). Chỉ thêm khi tích hợp S3 thực sự được triển khai, giới hạn ở đúng một ARN bucket — xem [`/files/policies/s3-access-policy.example.json`](/files/policies/s3-access-policy.example.json).

### Quyền Secrets Manager

`secretsmanager:GetSecretValue` giới hạn ở đúng ARN secret chứa credential `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, và `ANTHROPIC_API_KEY` — không bao giờ dùng wildcard cho toàn bộ secret trong tài khoản.

### Quyền theo cấp resource

Mọi statement trong policy ở trên nên tham chiếu một mẫu ARN cụ thể (`arn:aws:ecr:<region>:<account-id>:repository/fitness-assistant/*`, `arn:aws:secretsmanager:<region>:<account-id>:secret:fitness-assistant/*`) thay vì `*`, để một instance role bị xâm phạm không thể chạm tới tài nguyên không liên quan trong cùng tài khoản.

### Không dùng wildcard khi có thể tránh

`ecr:GetAuthorizationToken` là ngoại lệ đã được ghi nhận (AWS yêu cầu `Resource: "*"` cho đúng action này) — mọi quyền khác trong policy mẫu đều giới hạn theo một mẫu ARN cụ thể.

### Không hard-code AWS credentials

IAM role của EC2 cung cấp credential tạm thời, tự động xoay vòng qua instance metadata service — không bao giờ đặt `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` tồn tại lâu dài vào file `.env`, Dockerfile, hay commit vào source.

### Không commit `.env`

`.gitignore` trong repository này và trong source ứng dụng loại trừ `.env`, `.env.*` (trừ `.env.example`), `*.pem`, và `*.key`. Kiểm tra bằng `git status` trước mỗi lần commit.

### Xoay vòng secret (rotation)

Chưa triển khai trong MVP; được liệt kê ở phần công việc tương lai. AWS Secrets Manager hỗ trợ tự động xoay vòng credential cho RDS, đây sẽ là bước tiếp theo hợp lý khi MVP đã ổn định.

### Ví dụ policy least-privilege

Xem [`/files/policies/ec2-ecr-policy.example.json`](/files/policies/ec2-ecr-policy.example.json) — dùng placeholder `<YOUR_AWS_ACCOUNT_ID>` và `<YOUR_AWS_REGION>`, không bao giờ dùng account ID thật.
