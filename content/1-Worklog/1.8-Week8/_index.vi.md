---
title: "Tuần 8"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 1.8. </b> "
draft: false
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức. Không tự thay bằng ngày bịa đặt.
{{% /notice %}}

# WORKLOG TUẦN 8

### Mục tiêu tuần 8:

- Hoàn thành Module 7: AI/ML on AWS, hiểu cách AWS cung cấp hạ tầng machine learning managed thông qua Amazon SageMaker.
- Tham gia workshop SageMaker Immersion Day (Lab 200) để trải nghiệm thực tế một managed ML workflow, làm điểm so sánh với cách self-host LLM đang dùng ở `ai-service` của Fitness Assistant.
- Hoàn thành buổi lên văn phòng thứ 3 (trong tổng 10 buổi bắt buộc).
- Tiếp tục personal project: deploy MVP container stack lên EC2, dựa trên ECR image và IAM Role đã tạo ở Tuần 7.

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Học và hoàn thành Module 7: AI/ML on AWS, bao gồm SageMaker Immersion Day | [TODO_DATE] | [TODO_DATE] | 200: https://000200.awsstudygroup.com/ |
| Deploy MVP stack lên EC2 (personal project) | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |

### Kết quả đạt được tuần 8:

**Tổng quan:**

Tuần này chia làm hai phần: chương trình FCJ (Module 7: AI/ML on AWS) và phần AI của chính personal project. Học về managed ML infrastructure của SageMaker hoá ra lại là điểm đối chiếu hữu ích cho một quyết định đã có sẵn trong project Fitness Assistant: `ai-service` đang self-host LLM (Ollama, model mặc định `llama3.2:3b`) và vector database (Qdrant) thay vì gọi một managed AWS ML endpoint.

**Kiến thức lý thuyết học được:**

- **Amazon SageMaker fundamentals:** SageMaker giúp bỏ qua phần "undifferentiated heavy lifting" khi provision hạ tầng training/inference — managed notebook instance, built-in algorithm, và deploy model lên hosted endpoint chỉ với vài thao tác.
- **Đánh đổi giữa managed vs self-hosted inference:** SageMaker endpoint tính phí theo instance-hour trong lúc chạy và scale qua cấu hình, trong khi self-host LLM trên EC2 có chi phí cố định nhưng người vận hành phải tự chọn size và quản lý instance — liên quan trực tiếp tới bài toán sizing của `ai-service` đã đặt ra trong project này.

**Hands-on labs đã thực hiện:**

- Hoàn thành workshop SageMaker Immersion Day (Lab 200): tạo notebook instance, train một model mẫu, và deploy lên real-time inference endpoint.
- Tham dự buổi lên văn phòng thứ 3.
- Tiếp tục phần EC2 deployment của personal project: khởi tạo EC2 instance trong public subnet, gắn IAM Role đã tạo ở Tuần 7, và áp dụng Security Group EC2 từ Tuần 5.
- Cài đặt Docker Engine và Docker Compose plugin, đăng nhập ECR, pull image MVP.
- Viết file `docker-compose.aws.example.yml` mô tả cách các service MVP (frontend, gateway, auth-service, user-service, fitness-service, ai-service) kết nối với nhau trên EC2, trỏ `DATABASE_URL` tới endpoint RDS từ Tuần 6 thay vì container Postgres local.
- Khởi động stack và kiểm tra trạng thái, log của container.

**Áp dụng vào Fitness Assistant:**

Làm qua lab SageMaker giúp dễ giải thích bằng văn bản hơn lý do project chọn self-host LLM thay vì dùng managed endpoint: ở quy mô hiện tại, một EC2 instance chi phí cố định chạy Ollama rẻ hơn so với trả theo giờ cho SageMaker endpoint, đồng thời giữ được toàn quyền kiểm soát model gợi ý tập luyện. Đánh đổi được nêu rõ khi size EC2 instance tuần này là: instance giờ phải tính đủ cho cả AI workload chứ không chỉ phần còn lại của stack — `ai-service` phụ thuộc vào Ollama và Qdrant, cả hai đều cần nhiều CPU/RAM hơn hẳn so với `t3.micro`.

### Khó khăn gặp phải:

- **Đường cong học SageMaker:** console của SageMaker có nhiều thành phần (notebook instance, training job, model registry, endpoint) nên mất thời gian để map sang flow self-host đơn giản hơn đang dùng trong project.
- **Sizing EC2 cho AI workload:** `t3.micro` (1 vCPU, 1 GiB RAM) không thực tế để chạy Ollama cùng phần còn lại của stack — đây được xác định là rủi ro về tài nguyên, không bị bỏ qua.

### Cách giải quyết:

- **SageMaker:** làm hết lab Immersion Day từ đầu đến cuối thay vì lướt qua, dùng endpoint đã deploy làm điểm neo cụ thể để hình dung managed alternative sẽ trông như thế nào.
- **Sizing instance:** ghi lại kích thước instance tối thiểu khuyến nghị cho toàn bộ AI stack ở [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/), và ghi chú rằng instance nhỏ hơn (ví dụ Free Tier) chỉ thực tế chạy được MVP nếu không có AI service dùng Ollama, hoặc AI service được trỏ tới một endpoint LLM từ xa/managed khác.

### Kỹ năng / Dịch vụ AWS đã học:

**Services:**
- Amazon SageMaker (notebook instance, training job, real-time inference endpoint)
- Cấu hình khởi tạo EC2 (AMI, instance type, IAM Role, Security Group, EBS)

**Skills:**
- So sánh đánh đổi chi phí/vận hành giữa managed và self-hosted ML inference
- Ra quyết định sizing instance thực tế cho workload container có LLM nhúng kèm

### Liên kết với Fitness Assistant Architecture:

**Immediate Applications:**
- Ghi lại lý do self-host LLM thay vì dùng managed SageMaker endpoint, làm design-decision record cho Proposal.
- Container MVP hiện đã chạy trên EC2, kết nối tới RDS.

**Future Enhancements:**
- Cân nhắc lại phương án SageMaker nếu tập tính năng AI mở rộng đến mức tự vận hành Ollama/Qdrant trở thành gánh nặng lớn hơn chi phí trả cho managed endpoint.
- TODO: Xác nhận loại instance cuối cùng được chọn và ghi lại mức sử dụng CPU/RAM thực tế khi tải.

### Bằng chứng cần bổ sung:

- TODO: Screenshot notebook/endpoint của SageMaker Immersion Day.
- TODO: Screenshot chi tiết EC2 instance.
- TODO: Output lệnh `docker ps` thể hiện container đang chạy.
- TODO: Trích đoạn `docker compose logs` cho thấy khởi động thành công.
- TODO: Bằng chứng điểm danh buổi lên văn phòng thứ 3.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Học Module 7 (AI/ML on AWS) | [TODO_DATE] | [TODO_DATE] | 200: https://000200.awsstudygroup.com/ |
| 2 | Hoàn thành SageMaker Immersion Day (Lab 200) | [TODO_DATE] | [TODO_DATE] | 200: https://000200.awsstudygroup.com/ |
| 3 | Khởi tạo EC2, gắn IAM Role và Security Group | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 4 | Cài Docker/Docker Compose, pull image từ ECR, deploy `docker-compose.aws.example.yml` | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 5 | Kiểm tra container, mức sử dụng tài nguyên; buổi lên văn phòng thứ 3 | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã học Module 7 (AI/ML on AWS)
- [ ] Đã hoàn thành SageMaker Immersion Day (Lab 200)
- [ ] Đã tham dự buổi lên văn phòng thứ 3
- [ ] Đã khởi tạo EC2 với đúng IAM Role và Security Group
- [ ] Đã cài Docker/Docker Compose, pull image từ ECR, khởi động stack
- [ ] Đã ghi lại rủi ro kích thước instance cho Ollama/AI service

### Liên kết Workshop tương ứng

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/)
