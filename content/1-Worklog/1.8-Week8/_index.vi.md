---
title: "Tuần 8"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 1.8. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Khởi tạo EC2 instance để host container ứng dụng.
- Cài Docker và Docker Compose, đăng nhập ECR, pull image và khởi động stack MVP.

### Công việc đã thực hiện

- Khởi tạo EC2 instance trong public subnet, gắn IAM Role đã tạo ở Tuần 7, và áp dụng Security Group EC2 từ Tuần 5.
- Cài đặt Docker Engine và Docker Compose plugin trên instance.
- Đăng nhập ECR từ EC2 và pull image MVP.
- Viết file `docker-compose.aws.example.yml` mô tả cách các service MVP (frontend, gateway, auth-service, user-service, fitness-service, ai-service) kết nối với nhau trên EC2, trỏ `DATABASE_URL` tới endpoint RDS từ Tuần 6 thay vì container Postgres local.
- Khởi động stack và kiểm tra trạng thái, log của container.
- Chọn kích thước instance có tính đến service AI/RAG: `ai-service` phụ thuộc vào Ollama (LLM tự host, model mặc định `llama3.2:3b`) và Qdrant, cả hai đều cần nhiều CPU và RAM hơn đáng kể so với `t3.micro`.

### Kết quả đạt được

- Container MVP chạy trên EC2, kết nối tới RDS.
- TODO: Xác nhận loại instance cuối cùng được chọn và ghi lại mức sử dụng CPU/RAM thực tế khi tải.

### Khó khăn

- `t3.micro` (1 vCPU, 1 GiB RAM) không thực tế để chạy Ollama cùng với phần còn lại của stack — đây được xác định là rủi ro về tài nguyên, không bị bỏ qua.

### Cách giải quyết

- Ghi lại kích thước instance tối thiểu khuyến nghị cho toàn bộ AI stack ở [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/), và ghi chú rằng instance nhỏ hơn (ví dụ Free Tier) chỉ thực tế chạy được MVP nếu không có service AI dùng Ollama, hoặc AI service được trỏ tới một endpoint LLM từ xa/managed khác.

### Kỹ năng / Dịch vụ AWS đã học

- Cấu hình khởi tạo EC2 (AMI, instance type, IAM Role, Security Group, EBS).
- Đánh đổi thực tế khi chọn kích thước instance cho workload container có LLM nhúng kèm.

### Bằng chứng cần bổ sung

- TODO: Screenshot chi tiết EC2 instance.
- TODO: Output lệnh `docker ps` thể hiện container đang chạy.
- TODO: Trích đoạn `docker compose logs` cho thấy khởi động thành công.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Khởi tạo EC2, gắn IAM Role và Security Group | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 2 | Cài Docker và Docker Compose | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 3 | Pull image từ ECR và deploy `docker-compose.aws.example.yml` | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 4 | Kiểm tra container và mức sử dụng tài nguyên | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã khởi tạo EC2 với đúng IAM Role và Security Group
- [ ] Đã cài Docker/Docker Compose
- [ ] Đã pull image từ ECR và khởi động stack
- [ ] Đã ghi lại rủi ro kích thước instance cho Ollama/AI service

### Liên kết Workshop tương ứng

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/)
