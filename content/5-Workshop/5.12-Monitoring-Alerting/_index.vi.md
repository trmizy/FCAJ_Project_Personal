---
title: "5.12 Monitoring and Alerting"
date: 2026-07-15
weight: 12
chapter: false
pre: " <b> 5.12. </b> "
---

### Chuỗi giám sát

```
Metric  -->  Alarm  -->  SNS  -->  Email
```

Mọi cảnh báo được cấu hình trong mục này phải truy vết được qua đủ bốn giai đoạn, kèm bằng chứng cho từng giai đoạn.

### CloudWatch Agent

Giám sát EC2 mặc định không báo cáo memory hay dung lượng đĩa. Cài đặt và cấu hình CloudWatch Agent để thu thập các chỉ số này, cùng với việc chuyển tiếp log container/ứng dụng.

Xem [`/files/docker/cloudwatch-agent-config.example.json`](/files/docker/cloudwatch-agent-config.example.json) để có cấu hình mẫu thu thập memory, disk, và log file.

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json
```

### Log container / ứng dụng

Logging driver `awslogs` của Docker, hoặc tính năng thu thập log file của CloudWatch Agent trỏ vào output `docker compose logs`, gửi log container tới CloudWatch Logs. TODO: ghi lại cách nào thực sự được sử dụng.

### Log Group

Tạo Log Group riêng cho từng service thay vì một group gộp chung, để việc tìm kiếm và quản lý retention dễ dàng hơn, ví dụ `/fitness-assistant/gateway`, `/fitness-assistant/auth-service`.

### Retention period

Đặt retention period tường minh (ví dụ 14 hoặc 30 ngày) cho mọi Log Group — không bao giờ để mặc định "Never expire", để kiểm soát chi phí lưu trữ.

```bash
aws logs put-retention-policy --log-group-name /fitness-assistant/gateway --retention-in-days 14
```

### Dashboard

Một CloudWatch Dashboard tổng hợp: CPU utilization của EC2, memory/disk EC2 (qua Agent), CPU utilization của RDS, số connection database của RDS, dung lượng lưu trữ trống của RDS. TODO: đính kèm screenshot sau khi tạo.

### Alarm CPU EC2

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name fitness-assistant-ec2-high-cpu \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=<TODO_INSTANCE_ID> \
  --alarm-actions <TODO_SNS_TOPIC_ARN>
```

### Alarm status check EC2

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name fitness-assistant-ec2-status-check-failed \
  --metric-name StatusCheckFailed --namespace AWS/EC2 \
  --statistic Maximum --period 60 --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=<TODO_INSTANCE_ID> \
  --alarm-actions <TODO_SNS_TOPIC_ARN>
```

### CPU / Connections / Storage của RDS

Các lệnh `put-metric-alarm` tương tự trên namespace `AWS/RDS`, metric `CPUUtilization`, `DatabaseConnections`, và `FreeStorageSpace`, gắn dimension theo `DBInstanceIdentifier`. TODO: ghi lại ngưỡng thực tế đã chọn và lý do.

### Log lỗi API

TODO: quyết định log lỗi ở tầng ứng dụng (ví dụ response 5xx từ gateway) có được đưa thành CloudWatch metric filter và alarm hay chỉ xem thủ công qua CloudWatch Logs Insights. Chưa triển khai.

### SNS Topic và subscription email

```bash
aws sns create-topic --name fitness-assistant-alerts
aws sns subscribe \
  --topic-arn <TODO_SNS_TOPIC_ARN> \
  --protocol email \
  --notification-endpoint <TODO_ALERT_EMAIL>
```

Xác nhận subscription qua email xác nhận trước khi tin tưởng vào nó.

### Test alarm

Chủ động chuyển một alarm sang trạng thái `ALARM` để xác nhận toàn bộ chuỗi hoạt động đầu-cuối:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name fitness-assistant-ec2-high-cpu \
  --state-value ALARM \
  --state-reason "Manual test of the alert pipeline"
```

### Kết quả mong đợi

- Alarm test chuyển sang trạng thái `ALARM`.
- Email được nhận tại địa chỉ đã đăng ký trong vòng vài phút.
- TODO: đính kèm screenshot email đã nhận và lịch sử alarm làm bằng chứng sau khi bước này thực sự được thực hiện.
