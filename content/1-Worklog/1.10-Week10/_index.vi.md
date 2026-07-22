---
title: "Tuần 10"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 1.10. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Thiết lập logging tập trung với Amazon CloudWatch Logs.
- Cấu hình metric và alarm cơ bản cho EC2 và RDS.
- Thiết lập Amazon SNS topic kèm thông báo qua email cho alarm.

### Công việc đã thực hiện

- Cài đặt và cấu hình CloudWatch Agent trên EC2 để gửi log container/ứng dụng và metric cấp host (memory, disk) không có sẵn mặc định từ basic EC2 monitoring.
- Tạo CloudWatch Log Group với retention period tường minh (không để "Never expire") để kiểm soát chi phí.
- Tạo CloudWatch Dashboard tổng hợp CPU EC2, memory (qua Agent), dung lượng đĩa, và CPU/connections/storage của RDS.
- Tạo CloudWatch Alarm cho CPU EC2 cao và một alarm cho lỗi status check của EC2.
- Tạo Amazon SNS topic, đăng ký một địa chỉ email và xác nhận subscription.
- Gắn alarm để publish tới SNS topic, gửi thông báo test để xác nhận toàn bộ chuỗi: **Metric → Alarm → SNS → Email**.

### Kết quả đạt được

- Pipeline log từ container tới CloudWatch Logs hoạt động.
- Alarm đã cấu hình và (đang chờ kiểm tra) được xác nhận gửi thông báo qua email.
- TODO: Xác nhận alarm test thực sự kích hoạt và email đã nhận được; đính kèm bằng chứng.

### Khó khăn

- Basic EC2 monitoring không báo cáo memory hoặc dung lượng đĩa — cần dùng CloudWatch Agent thay vì chỉ dựa vào metric mặc định của EC2.

### Cách giải quyết

- Cài đặt và cấu hình CloudWatch Agent với file cấu hình JSON (xem `cloudwatch-agent-config.example.json`) để thu thập metric memory và disk bên cạnh metric CPU/network mặc định.

### Kỹ năng / Dịch vụ AWS đã học

- Amazon CloudWatch (Logs, Metrics, Alarms, Dashboards), cấu hình CloudWatch Agent, Amazon SNS topic và subscription email.

### Bằng chứng cần bổ sung

- TODO: Screenshot CloudWatch Dashboard.
- TODO: Screenshot alarm đã kích hoạt.
- TODO: Screenshot/email thể hiện đã nhận thông báo SNS.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Cài và cấu hình CloudWatch Agent | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |
| 2 | Tạo Log Group với chính sách retention | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |
| 3 | Tạo CloudWatch Alarm (CPU EC2, status check, RDS) | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |
| 4 | Tạo SNS topic, đăng ký email, kiểm tra chuỗi alarm | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |

### Checklist hoàn thành

- [ ] Đã cài CloudWatch Agent và gửi log/metric
- [ ] Đã tạo Log Group với retention period xác định
- [ ] Đã tạo alarm cho EC2 và RDS
- [ ] Đã tạo SNS topic, đăng ký email, xác nhận thông báo test

### Liên kết Workshop tương ứng

- [5.12 Monitoring and Alerting](../../5-Workshop/5.12-Monitoring-Alerting/)
