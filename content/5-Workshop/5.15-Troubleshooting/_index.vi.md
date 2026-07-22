---
title: "5.15 Troubleshooting"
date: 2026-07-15
weight: 15
chapter: false
pre: " <b> 5.15. </b> "
---

| Lỗi | Nguyên nhân có thể | Lệnh kiểm tra | Cách xử lý |
|---|---|---|---|
| `no basic auth credentials` (ECR) | Phiên đăng nhập Docker vào ECR hết hạn hoặc chưa từng chạy | `docker info` / thử đăng nhập lại | Chạy lại `aws ecr get-login-password ...` rồi pipe vào `docker login` |
| `Error response from daemon: pull access denied` / không tìm thấy image | Sai URI repository ECR, sai tag, hoặc image chưa được push | `aws ecr list-images --repository-name <repo>` | Xác nhận đúng tên repository/tag theo [5.8 ECR](../5.8-ECR/) |
| Container thoát ngay lập tức | Crash lúc khởi động — thường do biến môi trường thiếu/sai | `docker compose logs <service>` | So sánh biến môi trường bắt buộc của service (xem `.env.example` trong source) với những gì thực sự được inject |
| Port đã được sử dụng | Có process hoặc container khác đã bind port đó | `sudo lsof -i :<port>` hoặc `docker ps` | Dừng process/container đang xung đột, hoặc đổi port publish |
| Frontend không gọi được backend | `VITE_API_URL` nhúng cứng lúc build không khớp URL backend đã triển khai | Kiểm tra bundle frontend đã build / kiểm tra build ARG đã dùng | Build lại image frontend với đúng build ARG `VITE_API_URL`/`VITE_SOCKET_URL`/`VITE_CHAT_WS_URL` |
| Lỗi CORS trên console trình duyệt | `CORS_ORIGIN` của gateway/service không khớp origin thật của frontend | Kiểm tra biến môi trường `CORS_ORIGIN` | Đặt `CORS_ORIGIN` đúng scheme+host+port đang phục vụ frontend |
| RDS connection timeout | Security Group không cho phép Security Group của EC2 truy cập port 5432, hoặc sai routing subnet | `telnet <rds-endpoint> 5432` từ EC2 host | Sửa rule inbound của Security Group RDS theo [5.6 Network Infrastructure](../5.6-Network-Infrastructure/) |
| `password authentication failed` (Postgres) | Sai credential, hoặc `DATABASE_URL` trỏ sai tên database | Kiểm tra lại giá trị lấy từ Secrets Manager | Sửa credential/secret; không bao giờ hard-code password dự phòng |
| Lỗi migration Prisma | Migration đã áp dụng một phần, hoặc schema bị lệch giữa các môi trường | `pnpm exec prisma migrate status` | Giải quyết theo hướng dẫn của Prisma; không tự sửa tay schema database ngoài migration |
| Sai Security Group | Rule tham chiếu theo CIDR thay vì Security Group ID, hoặc gắn sai Security Group | Xem lại Security Group thực sự đang gắn trên console | Gắn lại đúng Security Group theo [5.6 Network Infrastructure](../5.6-Network-Infrastructure/) |
| EC2 thiếu RAM | Ollama/Qdrant cùng phần còn lại của stack MVP vượt quá RAM instance | `docker stats`, `free -h` | Đổi kích thước instance theo cảnh báo ở [5.9 EC2 Deployment](../5.9-EC2-Deployment/) |
| Disk full | Image/volume Docker tích lũy mà không dọn dẹp, hoặc trọng số model Ollama chiếm hết root volume | `df -h`, `docker system df` | `docker system prune` (cẩn thận), hoặc tăng dung lượng EBS volume |
| Không thấy log trong CloudWatch | CloudWatch Agent chưa cài/cấu hình, hoặc IAM role thiếu quyền `logs:*` | `sudo systemctl status amazon-cloudwatch-agent` | Cài/cấu hình lại Agent; kiểm tra IAM policy ở [5.11 IAM and Secrets](../5.11-IAM-Secrets/) |
| Chưa nhận email SNS | Subscription chưa được xác nhận, hoặc alarm chưa thực sự chuyển sang trạng thái `ALARM` | `aws sns list-subscriptions-by-topic` | Xác nhận subscription; test thủ công bằng `aws cloudwatch set-alarm-state` |
| Health check failed | Lệnh health check của container thất bại dù process vẫn chạy (ví dụ thiếu `wget`/`curl` trong image tối giản) | `docker inspect --format='{{json .State.Health}}' <container>` | Sửa lệnh health check cho khớp với những gì thực sự có trong image |
| `502 Bad Gateway` | Reverse proxy (Nginx) không gọi được tới container application gateway upstream | `docker compose ps`, log lỗi Nginx | Xác nhận container upstream đang chạy và địa chỉ `upstream`/`proxy_pass` của proxy đúng |
