---
title: "Worklog Tuần 1"
date: 2026-07-08
weight: 1
chapter: false
pre: " <b> 1.1. </b> "
---

### Mục tiêu tuần 1:

- Đăng ký tài khoản AWS để thực hành, nghiên cứu về Free Tier và cách quản lý chi phí.
- Học và thực hành 5 bài lab đầu tiên: IAM, VPC, EC2, RDS để nắm vững các dịch vụ nền tảng.
- Chuẩn bị môi trường để tuần sau bắt đầu phân tích source code Fitness Assistant.

### Các công việc cần triển khai trong tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Workshop / Tài liệu tham khảo |
|-----------|--------------|-----------------|-------------------------------|
| - Đăng ký tài khoản AWS Free Tier <br/> - Cấu hình IAM user, enable MFA <br/> - Học và thực hành 5 bài lab đầu tiên | 08-07-2026 | 12-07-2026 | 1: https://000001.awsstudygroup.com/ <br/> 2: https://000002.awsstudygroup.com/ <br/> 3: https://000003.awsstudygroup.com/ <br/> 4: https://000004.awsstudygroup.com/ <br/> 5: https://000005.awsstudygroup.com/ |

### Kết quả đạt được tuần 1:

**Tổng quan:**

Tuần này mình đã setup xong môi trường AWS để bắt đầu học. Phần chính là làm quen với các dịch vụ cơ bản nhất như IAM, EC2, RDS thông qua 5 bài lab trên AWS Study Group. Ban đầu hơi choáng vì nhiều khái niệm mới nhưng làm theo từng bước thì cũng hiểu dần.

**Kiến thức đã học:**

- **AWS Account & Free Tier:** Cách đăng ký tài khoản, hiểu rõ Free Tier có những gì free (EC2 750h/tháng, RDS 750h/tháng, S3 5GB). Quan trọng là phải setup Budget alert ngay từ đầu để tránh bị charge ngoài ý muốn.

- **IAM (Identity and Access Management):** Học cách tạo User, Group, Policy. Hiểu tại sao không nên dùng Root account cho công việc hàng ngày. Enable MFA cho cả Root và IAM user để bảo mật.

- **Amazon VPC:** Tìm hiểu về mạng ảo trên AWS, cách tạo VPC, Subnet, Security Group. Phần này hơi khó vì phải hiểu CIDR, routing table, nhưng cần thiết để sau này deploy app an toàn.

- **Amazon EC2:** Tạo instance đầu tiên (t2.micro trong Free Tier), SSH vào server, cài nginx thử. Thấy EC2 giống như thuê VPS nhưng linh hoạt hơn nhiều.

- **Amazon RDS:** Khởi tạo PostgreSQL database trên RDS, kết nối từ EC2. Hiểu được RDS tự động backup, Multi-AZ để high availability nhưng giá cao hơn self-managed DB.

**Thực hành:**

- Tạo tài khoản AWS thành công, verify bằng thẻ visa
- Hoàn thành cả 5 bài lab trên AWS Study Group từ 000001 đến 000005  
- Cài AWS CLI trên máy local (Windows), test được các lệnh cơ bản như `aws s3 ls`, `aws ec2 describe-instances`
- Tạo EC2 instance + RDS PostgreSQL, kết nối 2 services với nhau qua Security Group

**Khó khăn gặp phải:**

1. **Account verification pending:** Sau khi đăng ký xong, tài khoản bị pending verify gần 1 ngày. CloudShell không dùng được vì lỗi "Your account verification is in progress". Phải dùng AWS CLI làm workaround.

2. **IAM Policy JSON syntax:** Lần đầu viết custom policy bằng JSON khá rối vì nhiều field: Effect, Action, Resource, Condition. Dễ nhầm giữa `*` wildcard với ARN cụ thể.

3. **Security Group configuration:** Khái niệm Inbound/Outbound rules hơi confuse. Đặc biệt là hiểu khi nào dùng 0.0.0.0/0 (anywhere) và khi nào phải restrict theo IP cụ thể.

4. **RDS connection string:** Lúc đầu không connect được từ EC2 vào RDS vì quên config Security Group cho phép EC2 security group ID. Phải research thêm về security group chaining.

**Cách giải quyết:**

- **Account verify:** Chờ 24h tự động verify, không cần tạo support case. Trong lúc chờ thì dùng AWS CLI thay CloudShell.

- **IAM Policy:** Dùng AWS Policy Generator UI thay vì viết JSON thủ công. Tham khảo AWS Managed Policies (AdministratorAccess, PowerUserAccess) để học cấu trúc.

- **Security Group:** Vẽ diagram để hiểu luồng traffic: Internet → ALB → EC2 → RDS. Mỗi bước cần security group rule riêng. Practice principle of least privilege.

- **RDS connection:** Thay vì dùng 0.0.0.0/0 cho RDS, config security group rule cho phép source là EC2's security group ID. An toàn hơn và đúng best practice.
