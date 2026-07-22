---
title: "Tuần 5"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 1.5. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Xây dựng nền tảng mạng cho MVP: VPC, public subnet và private subnet, route table, Internet Gateway và Security Group.
- Áp dụng nguyên tắc least privilege ngay từ tài nguyên mạng đầu tiên được tạo.

### Công việc đã thực hiện

- Tạo VPC với CIDR block đã lên kế hoạch ở Tuần 4.
- Tạo một public subnet (cho EC2) và hai private subnet ở hai Availability Zone khác nhau (cho DB subnet group của RDS).
- Tạo và attach Internet Gateway, cấu hình route table (route table public → Internet Gateway; route table private không có route ra internet trực tiếp).
- Tạo Security Group: một cho EC2 chạy ứng dụng, một cho RDS, theo đúng bảng ma trận đã soạn ở [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/).

### Kết quả đạt được

- VPC hoạt động với bố cục subnet đã lên kế hoạch.
- TODO: Xác nhận dải CIDR cuối cùng đã sử dụng và ghi lại (có thể khác với placeholder thiết kế).

### Khó khăn

- Cân nhắc có nên tạo NAT Gateway cho MVP này hay không, do chi phí theo giờ và chi phí xử lý dữ liệu liên tục, so với việc giữ private subnet hoàn toàn cách ly (không có đường ra internet) cho tầng database.

### Cách giải quyết

- Với MVP này, private subnet của DB không cần truy cập internet ra ngoài (RDS không cần gọi ra ngoài), nên NAT Gateway được xem là thành phần optional/future thay vì mặc định trong MVP, để giữ chi phí dễ dự đoán.

### Kỹ năng / Dịch vụ AWS đã học

- Amazon VPC, subnet, route table, Internet Gateway.
- Thiết kế Security Group như một allow-list có trạng thái (stateful), ánh xạ trực tiếp theo các port thực tế mà ứng dụng sử dụng (xem bảng port chi tiết ở [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/)).

### Bằng chứng cần bổ sung

- TODO: Screenshot console VPC thể hiện VPC và subnet đã tạo.
- TODO: Screenshot route table.
- TODO: Screenshot rule của Security Group.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Tạo VPC và subnet | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 2 | Tạo và attach Internet Gateway, cấu hình route table | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 3 | Tạo Security Group cho EC2 và RDS | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 4 | Kiểm tra tổng thể bố cục mạng | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã tạo VPC và subnet
- [ ] Đã attach Internet Gateway và cấu hình route table
- [ ] Đã tạo Security Group theo nguyên tắc least privilege
- [ ] Đã ghi lại bố cục mạng kèm bằng chứng

### Liên kết Workshop tương ứng

- [5.6 Network Infrastructure](../../5-Workshop/5.6-Network-Infrastructure/)
