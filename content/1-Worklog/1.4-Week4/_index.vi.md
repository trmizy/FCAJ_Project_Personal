---
title: "Tuần 4"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 1.4. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Thiết kế bản đề xuất kiến trúc AWS đầu tiên cho MVP, dựa chặt chẽ vào các service đã xác nhận ở Tuần 2–3 (không dựa vào kiến trúc mẫu chung chung).
- Tạo sơ đồ kiến trúc bằng draw.io.
- Soạn thảo kế hoạch VPC, subnet và Security Group.

### Công việc đã thực hiện

- Xem xét lại cấu trúc thực tế của `fitness-assistant` đã xác nhận trong source: frontend React/Vite, container API gateway ở tầng ứng dụng (`backend/gateway`), và nhiều microservice backend (auth, user, fitness, AI/RAG, cùng với chat/gym/payment có tồn tại trong source nhưng nặng hơn hoặc chưa có Dockerfile production).
- Quyết định service nào thuộc phạm vi MVP và service nào thuộc phần phát triển tương lai, dựa trên bằng chứng cụ thể (đã có Dockerfile production chưa? có cần thêm hạ tầng như vector database hay LLM tự host không?).
- Vẽ bản nháp sơ đồ kiến trúc AWS đầu tiên (một EC2 chạy Docker Compose, Amazon RDS for PostgreSQL, Amazon ECR lưu image).
- Bắt đầu soạn thảo bố cục VPC/subnet/Security Group.

### Kết quả đạt được

- Phạm vi MVP đã được ghi lại kèm bằng chứng cụ thể (xem [Proposal](../../2-Proposal/) phiên bản hoàn chỉnh).
- TODO: Đính kèm sơ đồ draw.io đã export sau khi hoàn thiện.

### Khó khăn

- Container `backend/gateway` nội bộ của ứng dụng rất dễ bị nhầm với **Amazon API Gateway**; sơ đồ kiến trúc cần thể hiện rõ sự khác biệt này.
- Service AI phụ thuộc vào một LLM tự host, có yêu cầu CPU/RAM thực tế cần được phản ánh trung thực trong kế hoạch chọn kích thước instance, thay vì giả định instance Free Tier là đủ.

### Cách giải quyết

- Gắn nhãn rõ ràng container gateway của ứng dụng là "Application Gateway (container backend/gateway trên EC2)" trong mọi sơ đồ và tài liệu, chỉ dùng "Amazon API Gateway" cho đúng dịch vụ AWS managed thực sự (hiện MVP này chưa sử dụng).
- Thêm cảnh báo rõ ràng về kích thước tài nguyên cho service AI/RAG trong ghi chú kiến trúc, sẽ được trình bày chi tiết hơn ở mục [EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/).

### Kỹ năng / Dịch vụ AWS đã học

- Kiến thức nền tảng thiết kế VPC (public/private subnet, route table, Internet Gateway).
- Cách chuyển đổi cấu trúc ứng dụng dựa trên docker-compose thành sơ đồ mạng AWS.

### Bằng chứng cần bổ sung

- TODO: Sơ đồ kiến trúc hoàn chỉnh (`/images/workshop/architecture/fitness-assistant-aws-architecture.png` và file `.drawio` có thể tải xuống).
- TODO: Screenshot bản nháp thiết kế VPC.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Quyết định phạm vi MVP và phần phát triển tương lai | [TODO_DATE] | [TODO_DATE] | Kết quả Tuần 2–3 |
| 2 | Soạn thảo sơ đồ kiến trúc AWS | [TODO_DATE] | [TODO_DATE] | draw.io |
| 3 | Soạn thảo kế hoạch VPC/subnet/Security Group | [TODO_DATE] | [TODO_DATE] | — |
| 4 | Rà soát bản nháp cùng mentor/checklist tự đánh giá | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã ghi lại phạm vi MVP kèm lý do
- [ ] Đã tạo bản nháp sơ đồ kiến trúc
- [ ] Đã soạn thảo kế hoạch VPC/subnet/Security Group
- [ ] Đã rà soát sơ đồ và kế hoạch

### Liên kết Workshop tương ứng

- [5.2 Architecture](../../5-Workshop/5.2-Architecture/)
