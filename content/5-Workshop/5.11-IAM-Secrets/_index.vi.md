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

### Câu lệnh thiết lập thật

**1. Trust policy và IAM Role:**

```bash
export AWS_ACCOUNT_ID=<YOUR_AWS_ACCOUNT_ID>
export AWS_REGION=<YOUR_AWS_REGION>

cat > /tmp/ec2-trust-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name fitness-assistant-ec2-role \
  --assume-role-policy-document file:///tmp/ec2-trust-policy.json
```

**2. Gắn policy least-privilege** (điền account ID/region thật vào [`/files/policies/ec2-ecr-policy.example.json`](/files/policies/ec2-ecr-policy.example.json) trước, lưu thành `ec2-ecr-policy.json`):

```bash
aws iam put-role-policy \
  --role-name fitness-assistant-ec2-role \
  --policy-name fitness-assistant-ecr-cloudwatch-secrets \
  --policy-document file://ec2-ecr-policy.json
```

**3. Instance profile** (EC2 gắn instance *profile*, không gắn trực tiếp role):

```bash
aws iam create-instance-profile --instance-profile-name fitness-assistant-ec2-profile
aws iam add-role-to-instance-profile \
  --instance-profile-name fitness-assistant-ec2-profile \
  --role-name fitness-assistant-ec2-role
```

Gắn `fitness-assistant-ec2-profile` khi launch EC2 instance (`aws ec2 run-instances --iam-instance-profile Name=fitness-assistant-ec2-profile ...`) — xem [5.9 EC2 Deployment](../5.9-EC2-Deployment/).

**4. Tạo secret trong Secrets Manager** (mỗi credential một secret, hoặc gộp thành một JSON blob — ở đây minh họa gộp thành 1 secret cho gọn; điều chỉnh cho khớp cách `docker-compose.aws.example.yml` đọc chúng):

```bash
aws secretsmanager create-secret \
  --name fitness-assistant/database \
  --secret-string '{"username":"<TODO_DATABASE_USER>","password":"<TODO_REAL_PASSWORD>","host":"<TODO_RDS_ENDPOINT>"}' \
  --region "$AWS_REGION"

aws secretsmanager create-secret \
  --name fitness-assistant/jwt \
  --secret-string '{"JWT_SECRET":"<TODO_REAL_VALUE>","JWT_REFRESH_SECRET":"<TODO_REAL_VALUE>"}' \
  --region "$AWS_REGION"

aws secretsmanager create-secret \
  --name fitness-assistant/anthropic \
  --secret-string '{"ANTHROPIC_API_KEY":"<TODO_REAL_KEY>"}' \
  --region "$AWS_REGION"
```

**5. Lấy secret tại thời điểm deploy** (chạy lệnh này trên EC2 instance, dùng credential mà instance profile đã cấp sẵn — không cần access key):

```bash
aws secretsmanager get-secret-value --secret-id fitness-assistant/database --region "$AWS_REGION" --query SecretString --output text
```

Dùng JSON lấy được để điền vào file `.env` mà `docker-compose.aws.example.yml` đọc (xem [5.9 EC2 Deployment](../5.9-EC2-Deployment/)), ghi với `chmod 600` và không bao giờ commit.

### Xác minh

```bash
aws iam get-role --role-name fitness-assistant-ec2-role
aws iam list-role-policies --role-name fitness-assistant-ec2-role
aws secretsmanager list-secrets --region "$AWS_REGION" --query 'SecretList[].Name'
```

TODO: đính kèm screenshot IAM Role/policy thật (che account ID) và xác nhận instance thực sự lấy được từng secret sau khi deploy.
