---
title: "5.8 ECR"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 5.8. </b> "
---

### Biến shell

Dùng biến môi trường thay vì hard-code thông tin tài khoản ở bất kỳ script hay tài liệu nào:

```bash
export AWS_ACCOUNT_ID=<YOUR_AWS_ACCOUNT_ID>
export AWS_REGION=<YOUR_AWS_REGION>
export IMAGE_TAG=$(date +%Y-%m-%d)
```

### Repository cần tạo (phạm vi MVP)

Một Amazon ECR repository cho mỗi service thuộc MVP:

```bash
for ECR_REPOSITORY in frontend gateway auth-service user-service fitness-service ai-service payment-service gym-service; do
  aws ecr create-repository \
    --repository-name "fitness-assistant/${ECR_REPOSITORY}" \
    --region "$AWS_REGION" \
    --image-scanning-configuration scanOnPush=true
done
```

{{% notice note %}}
`chat-service` được cố tình loại trừ ở đây — ngoài phạm vi MVP (xem [Proposal §9](../../2-Proposal/#9-thành-phần-không-nằm-trong-mvp)). `gym-service` và `payment-service` ĐƯỢC đưa vào: cả hai đã có Dockerfile production kể từ khi mục này được viết lần đầu (xem [5.5 Production Containers](../5.5-Production-Containers/)).
{{% /notice %}}

### Đăng nhập ECR

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
```

### Build, tag, push

```bash
docker build -t fitness-assistant/auth-service:${IMAGE_TAG} \
  -f backend/services/auth-service/Dockerfile .

docker tag fitness-assistant/auth-service:${IMAGE_TAG} \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fitness-assistant/auth-service:${IMAGE_TAG}

docker push \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fitness-assistant/auth-service:${IMAGE_TAG}
```

Lặp lại cho từng service thuộc MVP, điều chỉnh đường dẫn Dockerfile và build context (xem ghi chú về build context ở [5.5 Production Containers](../5.5-Production-Containers/)).

### Xác minh

```bash
aws ecr list-images --repository-name fitness-assistant/auth-service --region "$AWS_REGION"
```

TODO: đính kèm screenshot thật của ECR console thể hiện image đã được push sau khi xác minh.

### Quy ước đặt tên image

`fitness-assistant/<service-name>:<YYYY-MM-DD>` và thêm tag `:latest` để thuận tiện. Không chỉ dựa vào `:latest` cho mục đích rollback.

### Lifecycle policy

Khuyến nghị, để kiểm soát chi phí lưu trữ: hết hạn image không có tag sau một số ngày nhất định, và chỉ giữ N image có tag gần nhất cho mỗi repository. TODO: áp dụng và ghi lại nội dung JSON lifecycle policy thực tế đã dùng, sau khi quyết định.

### Troubleshooting

| Lỗi | Nguyên nhân có thể | Lệnh kiểm tra | Cách xử lý |
| --- | --- | --- | --- |
| `no basic auth credentials` | Phiên đăng nhập ECR hết hạn hoặc chưa đăng nhập | `docker info` không thấy ECR registry đã đăng nhập | Chạy lại `aws ecr get-login-password ...` rồi pipe vào `docker login ...` |
| `repository does not exist` | Repository chưa được tạo, hoặc sai region/account trong URI | `aws ecr describe-repositories` | Tạo repository hoặc sửa lại URI |
| `denied: requested access to the resource is denied` | IAM identity thiếu quyền `ecr:*`, hoặc sai account ID trong tag image | So sánh IAM policy với [5.11 IAM and Secrets](../5.11-IAM-Secrets/) | Sửa IAM policy hoặc account ID trong tag |
