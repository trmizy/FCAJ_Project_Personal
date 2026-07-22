---
title: "Tuần 11"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 1.11. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Chạy kiểm thử đầu-cuối và kiểm thử lỗi trên MVP đã triển khai.
- Rà soát IAM policy và rule Security Group để phát hiện quyền hạn dư thừa.
- Rà soát chi phí và xác định cơ hội tối ưu trước khi kết thúc thực tập.

### Công việc đã thực hiện

- Thực hiện các test case đã định nghĩa ở [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/), bao gồm đăng ký, đăng nhập, endpoint được bảo vệ, tính bền vững dữ liệu trên RDS, khả năng phục hồi khi container restart, và giám sát/cảnh báo.
- Kiểm thử các luồng lỗi: request không có token, request với JWT không hợp lệ/hết hạn, và hành vi khi database tạm thời không truy cập được.
- Rà soát IAM Role gắn với EC2 so với quyền thực tế đang sử dụng, loại bỏ những quyền rộng hơn cần thiết (không dùng resource wildcard `*` khi có thể chỉ định ARN cụ thể).
- Rà soát rule Security Group để xác nhận SSH (port 22) không mở cho `0.0.0.0/0` và port 5432 của RDS chỉ chấp nhận traffic từ Security Group ứng dụng.
- Rà soát tài nguyên đang chạy so với ước tính chi phí trong [Proposal](../../2-Proposal/), ghi chú loại instance, dung lượng lưu trữ hoặc tài nguyên nhàn rỗi cần điều chỉnh kích thước hoặc dừng khi không dùng.

### Kết quả đạt được

- Bản ghi kết quả kiểm thử kèm trạng thái pass/fail theo từng test case (xem [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/); các test chưa thực hiện được đánh dấu `Not executed`, không phải `PASS`).
- Danh sách rút gọn các hành động cần siết chặt IAM/Security Group.
- TODO: Ghi lại số liệu thực tế từ AWS Cost Explorer sau khi có ít nhất một chu kỳ billing đầy đủ.

### Khó khăn

- Mô phỏng các kịch bản lỗi thực tế (ví dụ database tạm thời không truy cập được) mà không gây downtime ngoài ý muốn cho các hoạt động kiểm thử khác đang diễn ra.

### Cách giải quyết

- Lên lịch kiểm thử các luồng lỗi trong khung bảo trì riêng thay vì xen kẽ với các kiểm thử khác, và ghi lại hành vi mong đợi so với thực tế cho từng trường hợp.

### Kỹ năng / Dịch vụ AWS đã học

- Kỹ thuật rà soát IAM least-privilege thực tế (so sánh quyền đã cấp với các API call thực sự được dùng).
- Đọc AWS Cost Explorer / Billing dashboard để đối chiếu tài nguyên đang chạy với ước tính chi phí.

### Bằng chứng cần bổ sung

- TODO: Bảng test case hoàn chỉnh kèm link bằng chứng.
- TODO: Screenshot ghi chú/diff rà soát IAM policy.
- TODO: Screenshot AWS Cost Explorer cho chu kỳ billing của project.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Thực hiện test case chức năng đầu-cuối | [TODO_DATE] | [TODO_DATE] | [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/) |
| 2 | Thực hiện test case luồng lỗi | [TODO_DATE] | [TODO_DATE] | [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/) |
| 3 | Rà soát IAM policy và Security Group | [TODO_DATE] | [TODO_DATE] | [Workshop 5.14](../../5-Workshop/5.14-Security-Cost/) |
| 4 | Rà soát chi phí so với ước tính | [TODO_DATE] | [TODO_DATE] | [Workshop 5.14](../../5-Workshop/5.14-Security-Cost/) |

### Checklist hoàn thành

- [ ] Đã thực hiện và ghi lại test case chức năng
- [ ] Đã thực hiện và ghi lại test case luồng lỗi
- [ ] Đã hoàn thành rà soát IAM/Security Group
- [ ] Đã hoàn thành rà soát chi phí so với ước tính trong Proposal

### Liên kết Workshop tương ứng

- [5.13 Testing and Validation](../../5-Workshop/5.13-Testing-Validation/)
- [5.14 Security and Cost Optimization](../../5-Workshop/5.14-Security-Cost/)
