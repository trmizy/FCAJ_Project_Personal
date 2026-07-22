---
title: "5.9 EC2 Deployment"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 5.9. </b> "
---

{{% notice warning %}}
Không giả định `t3.micro` thuộc Free Tier (1 vCPU, 1 GiB RAM) là đủ cho workload này. AI service phụ thuộc vào Ollama (LLM tự host) và Qdrant, cả hai đều có yêu cầu CPU/RAM thực tế. Chọn kích thước instance dựa trên những gì thực sự chạy, và ghi lại mức sử dụng đo được thực tế tại đây khi có.
{{% /notice %}}

### Chọn AMI và loại instance

- **AMI:** Ubuntu Server LTS (khuyến nghị vì tương thích tốt với Docker Engine và được hỗ trợ dài hạn).
- **Loại instance:** TODO — cần chọn dựa trên container nào thực sự chạy trên host này. Nếu `ai-service` + Ollama + Qdrant chạy cùng phần còn lại của stack MVP, tối thiểu 4 vCPU / 8 GiB RAM là điểm khởi đầu thực tế hơn so với instance Free Tier; điều này cần được xác minh dựa trên mức sử dụng đo được thực tế, không giả định.
- Nếu ràng buộc ngân sách yêu cầu instance nhỏ hơn, cân nhắc chạy AI stack (Ollama + Qdrant) riêng, hoặc để lại `ai-service` cho lần triển khai sau và ghi chú rõ đây là việc cần làm tiếp theo.

### EBS Volume

TODO: ghi lại dung lượng root volume thực tế đã chọn (volume mặc định của Ubuntu AMI thường quá nhỏ khi đã pull vài image Docker — riêng trọng số model của Ollama đã có thể vài GB).

### IAM Role

Gắn IAM Role đã tạo ở [5.11 IAM and Secrets](../5.11-IAM-Secrets/), cấp quyền least-privilege tới ECR, CloudWatch, và Secrets Manager. Không đặt access key AWS tồn tại lâu dài trên instance.

### Security Group

Gắn Security Group EC2 từ [5.6 Network Infrastructure](../5.6-Network-Infrastructure/) (mở 80/443, SSH giới hạn theo một IP cụ thể).

### User Data (Tùy chọn)

Một script user data của EC2 có thể tự động hóa việc cài Docker khi khởi động lần đầu. TODO: ghi lại script user data thực tế đã dùng (nếu có), hoặc ghi chú bước này được thực hiện thủ công.

### Kết nối tới instance

Ưu tiên **AWS Systems Manager Session Manager** thay vì SSH trực tiếp khi có thể, vì cách này tránh hoàn toàn việc mở port 22 ra internet. Nếu dùng SSH, phải giới hạn theo một IP cụ thể theo đúng thiết kế Security Group.

### Cài đặt Docker

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

### Đăng nhập ECR và pull image

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fitness-assistant/auth-service:${IMAGE_TAG}
# lặp lại cho từng service thuộc MVP
```

### Tạo file môi trường một cách an toàn

Không viết secret trực tiếp vào file `.env` dạng plaintext rồi commit vào bất kỳ repository nào. Lấy secret từ AWS Secrets Manager lúc deploy (xem [5.11 IAM and Secrets](../5.11-IAM-Secrets/)) và ghi vào file `.env` có quyền `chmod 600`, loại trừ khỏi mọi Git repository trên host.

### Chạy Docker Compose (cấu trúc production)

Xem [`/files/docker/docker-compose.aws.example.yml`](/files/docker/docker-compose.aws.example.yml) để có cấu trúc mẫu mô tả cách các service MVP kết nối trên EC2, với `DATABASE_URL` trỏ tới endpoint Amazon RDS từ [5.7 RDS PostgreSQL](../5.7-RDS-PostgreSQL/) thay vì container Postgres local.

```bash
docker compose -f docker-compose.aws.example.yml up -d
```

### Reverse proxy

Cài Nginx trên host làm reverse proxy phía trước container frontend và application gateway. TODO: đính kèm cấu hình Nginx site thực tế đã dùng sau khi hoàn thiện.

### Health check

```bash
curl -I http://localhost/
curl http://localhost:3000/health
```

### Kiểm tra container

```bash
docker compose -f docker-compose.aws.example.yml ps
docker stats --no-stream
```

TODO: ghi lại mức sử dụng CPU/RAM thực tế khi tải, để xác nhận hoặc điều chỉnh quyết định kích thước instance ở trên.

### Kiểm tra frontend / API

Mở `http://<EC2_PUBLIC_IP_OR_DNS>/` trên trình duyệt và xác nhận frontend load được và gọi được API qua gateway.

### Duy trì sau khi reboot

Đảm bảo Docker daemon và stack Compose tự khởi động lại sau khi instance reboot (service `docker` được enable qua systemd, và policy `restart: unless-stopped` trong file Compose).

### Troubleshooting

Xem [5.15 Troubleshooting](../5.15-Troubleshooting/) để biết cách xử lý `502 Bad Gateway`, "container exited", "port already in use", và các lỗi liên quan đến EC2/Docker khác.
