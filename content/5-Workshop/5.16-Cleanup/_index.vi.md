---
title: "5.16 Cleanup"
date: 2026-07-15
weight: 16
chapter: false
pre: " <b> 5.16. </b> "
---

{{% notice warning %}}
Thực hiện theo đúng thứ tự này. Xóa tài nguyên sai thứ tự (ví dụ xóa VPC trước Security Group của nó, hoặc xóa IAM role khi vẫn đang gắn với instance đang chạy) sẽ thất bại hoặc để lại tài nguyên mồ côi. Mỗi bước bên dưới ghi rõ phụ thuộc và ảnh hưởng chi phí dự kiến.
{{% /notice %}}

Xem thêm [`/files/scripts/cleanup-checklist.md`](/files/scripts/cleanup-checklist.md) để có phiên bản checklist có thể copy của các bước bên dưới.

1. **Dừng và xóa container** — `docker compose down` trên EC2 host. *Console:* không áp dụng (SSH/Session Manager). *Kết quả mong đợi:* không còn container chạy. *Ảnh hưởng chi phí:* dừng compute bên trong instance, nhưng bản thân instance vẫn tính phí cho đến khi được dừng/terminate.
2. **Xóa CloudWatch Alarm** — Console: CloudWatch → Alarms → Delete. CLI: `aws cloudwatch delete-alarms --alarm-names <name>`. *Phụ thuộc:* không chặn gì, nhưng nên làm trước khi xóa SNS topic mà alarm tham chiếu, để tránh action treo lơ lửng.
3. **Xóa SNS subscription và topic** — Console: SNS → Subscriptions/Topics → Delete. CLI: `aws sns unsubscribe --subscription-arn <arn>` rồi `aws sns delete-topic --topic-arn <arn>`.
4. **Xóa CloudWatch Log Group** (nếu không cần lưu trữ) — Console: CloudWatch → Log groups → Delete. CLI: `aws logs delete-log-group --log-group-name <name>`. *Cảnh báo:* thao tác này xóa vĩnh viễn lịch sử log; giữ lại nếu vẫn cần làm bằng chứng cho báo cáo này.
5. **Xóa object và bucket S3** (chỉ nếu đã tạo bucket S3 để kiểm thử theo [5.10 S3 Storage](../5.10-S3-Storage/)) — làm rỗng bucket trước, sau đó xóa bucket. CLI: `aws s3 rm s3://<bucket> --recursive` rồi `aws s3api delete-bucket --bucket <bucket>`.
6. **Xóa image và repository ECR** — Console: ECR → Repositories → Delete. CLI: `aws ecr delete-repository --repository-name <name> --force`. *Ảnh hưởng chi phí:* dừng chi phí lưu trữ ECR cho các image này.
7. **Xóa RDS instance** — Console: RDS → Databases → Delete. CLI: `aws rds delete-db-instance --db-instance-identifier fitness-assistant-db --skip-final-snapshot` (hoặc bỏ `--skip-final-snapshot` nếu muốn tạo snapshot cuối). *Cảnh báo chi phí:* chi phí RDS chỉ dừng khi instance đã bị xóa hoàn toàn, không phải khi chỉ dừng (stop).
8. **Quyết định: có tạo final snapshot hay không** — nếu bản triển khai này có thể được tiếp tục sau này, hãy tạo final snapshot trước khi xóa instance; nếu không, bỏ qua để tránh chi phí lưu trữ snapshot liên tục.
9. **Xóa EC2 instance** — Console: EC2 → Instances → Terminate. CLI: `aws ec2 terminate-instances --instance-ids <id>`. *Phụ thuộc:* phải thực hiện trước khi xóa Security Group hoặc gỡ liên kết IAM instance profile của nó.
10. **Giải phóng Elastic IP** (nếu đã cấp phát) — Console: EC2 → Elastic IPs → Release. CLI: `aws ec2 release-address --allocation-id <id>`. *Cảnh báo chi phí:* một Elastic IP không gắn với instance vẫn tiếp tục phát sinh chi phí cho đến khi được giải phóng.
11. **Xóa Load Balancer và Target Group** (chỉ nếu đã tạo cho công việc tương lai/tùy chọn) — không thuộc MVP; xóa nếu tồn tại.
12. **Xóa NAT Gateway** (chỉ nếu đã tạo) — mặc định không dùng trong thiết kế MVP này; xóa nếu có, và giải phóng Elastic IP liên quan.
13. **Xóa route table tùy chỉnh** — Console: VPC → Route Tables → Delete. *Phụ thuộc:* subnet không còn tham chiếu tới route table đó.
14. **Xóa subnet** — Console: VPC → Subnets → Delete. *Phụ thuộc:* không còn tài nguyên đang chạy (EC2, RDS) tham chiếu tới subnet.
15. **Xóa Internet Gateway** — detach khỏi VPC trước, sau đó mới xóa.
16. **Xóa Security Group tùy chỉnh** — Console: VPC → Security Groups → Delete. *Phụ thuộc:* không còn ENI nào (ví dụ instance EC2/RDS vẫn đang chạy) tham chiếu tới Security Group.
17. **Xóa VPC** — Console: VPC → Your VPCs → Delete. *Phụ thuộc:* toàn bộ mục trên (subnet, IGW, route table, Security Group) phải được xóa trước.
18. **Xóa secret trong Secrets Manager** — Console: Secrets Manager → Delete. CLI: `aws secretsmanager delete-secret --secret-id <id> --recovery-window-in-days 7` (dùng recovery window thay vì xóa ngay lập tức, phòng trường hợp nhầm lẫn).
19. **Xóa IAM policy/role tự tạo** — Console: IAM → Roles/Policies → Delete. *Phụ thuộc:* role không còn gắn với bất kỳ instance profile/tài nguyên nào.
20. **Kiểm tra Billing và Resource Explorer** — Console: Billing Dashboard và AWS Resource Explorer, để xác nhận không còn tài nguyên nào chạy ngoài dự kiến trong tài khoản/Region này sau khi dọn dẹp.

{{% notice warning %}}
Không bao giờ chạy lệnh xóa với wildcard trên toàn bộ tài khoản AWS. Mọi lệnh ở trên đều nhắm tới một tài nguyên cụ thể, có tên rõ ràng. Kiểm tra kỹ resource ID/ARN trước khi chạy bất kỳ lệnh `delete-*` hay `terminate-*` nào.
{{% /notice %}}
