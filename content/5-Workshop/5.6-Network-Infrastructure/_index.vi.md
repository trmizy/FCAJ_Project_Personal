---
title: "5.6 Network Infrastructure"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.6. </b> "
---

{{% notice warning %}}
Các dải CIDR bên dưới là **thiết kế mẫu (placeholder)** và cần được xác nhận trước khi khởi tạo thực tế. Chúng không đại diện cho một VPC đã được tạo sẵn.
{{% /notice %}}

### Thiết kế VPC và subnet

```
VPC:                        10.0.0.0/16
Public subnet (EC2):        10.0.1.0/24   (Availability Zone A)
Private DB subnet A:        10.0.11.0/24  (Availability Zone A)
Private DB subnet B:        10.0.12.0/24  (Availability Zone B)
```

Cần hai private subnet ở hai Availability Zone khác nhau vì DB subnet group của Amazon RDS yêu cầu tối thiểu hai AZ, kể cả với database instance chỉ chạy single-AZ.

### Internet Gateway và route table

- Một Internet Gateway được attach vào VPC.
- **Route table public:** `0.0.0.0/0` → Internet Gateway; gắn với public subnet.
- **Route table private:** không có route `0.0.0.0/0`; gắn với private DB subnet. RDS không cần truy cập internet outbound cho MVP này.

### NAT Gateway

**Không sử dụng trong MVP.** Vì private subnet chỉ host RDS (không cần truy cập internet outbound), NAT Gateway không bắt buộc và cố tình bị loại trừ để tránh chi phí theo giờ và chi phí xử lý dữ liệu theo GB. Nếu trong tương lai có service nào trong private subnet cần truy cập internet outbound, cần bổ sung NAT Gateway và tính đến chi phí — xem cảnh báo chi phí ở [5.14 Security and Cost Optimization](../5.14-Security-Cost/).

### DB Subnet Group

Một DB subnet group của RDS trải trên hai private subnet (`10.0.11.0/24`, `10.0.12.0/24`) ở hai Availability Zone.

### Bảng ma trận Security Group

| Tài nguyên | Port | Nguồn | Mục đích |
| --- | --- | --- | --- |
| EC2 (ứng dụng) | 80 | `0.0.0.0/0` | Truy cập HTTP tới frontend/reverse proxy |
| EC2 (ứng dụng) | 443 | `0.0.0.0/0` | Truy cập HTTPS (khi đã cấu hình TLS) |
| EC2 (ứng dụng) | 22 | `[TODO_ADMIN_IP]/32` | Quản trị SSH — chỉ một IP cụ thể, **không bao giờ** dùng `0.0.0.0/0` |
| RDS PostgreSQL | 5432 | Security Group ứng dụng của EC2 (tham chiếu theo ID, không theo CIDR) | Truy cập database chỉ từ tầng ứng dụng |

{{% notice warning %}}
Port 22 (SSH) không bao giờ được mở cho `0.0.0.0/0` trong thiết kế này. Port 5432 (PostgreSQL) trên RDS chỉ được chấp nhận traffic từ Security Group ứng dụng của EC2, tham chiếu theo Security Group ID, không theo dải CIDR.
{{% /notice %}}

### Tóm tắt luồng inbound / outbound

- **Inbound tới EC2:** chỉ 80/443 từ internet, và 22 từ IP quản trị viên.
- **Outbound từ EC2:** được phép (cần thiết để pull image từ ECR, gọi Anthropic API, gửi log tới CloudWatch, và publish tới SNS).
- **Inbound tới RDS:** chỉ 5432 từ Security Group của EC2.
- **Outbound từ RDS:** không áp dụng / không cần thiết cho MVP này.

### Nguyên tắc Least Privilege

Mọi rule ở trên đều được giới hạn ở nguồn hẹp nhất mà vẫn đảm bảo ứng dụng hoạt động: RDS chỉ truy cập được từ Security Group của chính ứng dụng, không bao giờ từ internet công cộng hay một dải CIDR tùy ý; SSH giới hạn ở một IP quản trị viên duy nhất, không phải một dải rộng.

### Câu lệnh thiết lập thật

Biến shell dùng xuyên suốt (điền giá trị thật — `AWS_REGION` phải khớp region đã chọn ở [Proposal §21](../../2-Proposal/#21-ước-tính-chi-phí)):

```bash
export AWS_REGION=<YOUR_AWS_REGION>
export MY_IP=$(curl -s https://checkip.amazonaws.com)/32
```

**1. Tạo VPC:**

```bash
export VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=fitness-assistant-vpc}]' \
  --region "$AWS_REGION" --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames "{\"Value\":true}" --region "$AWS_REGION"
```

**2. Tạo 3 subnet** (1 public, 2 private ở 2 AZ khác nhau — bắt buộc vì RDS DB subnet group cần tối thiểu 2 AZ):

```bash
export AZ_A="${AWS_REGION}a"
export AZ_B="${AWS_REGION}b"

export PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone "$AZ_A" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fitness-assistant-public-a}]' \
  --region "$AWS_REGION" --query 'Subnet.SubnetId' --output text)

export PRIVATE_SUBNET_A_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.11.0/24 --availability-zone "$AZ_A" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fitness-assistant-private-a}]' \
  --region "$AWS_REGION" --query 'Subnet.SubnetId' --output text)

export PRIVATE_SUBNET_B_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block 10.0.12.0/24 --availability-zone "$AZ_B" \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fitness-assistant-private-b}]' \
  --region "$AWS_REGION" --query 'Subnet.SubnetId' --output text)

# Public subnet phải tự gán IP public thì EC2 instance mới truy cập được từ internet
aws ec2 modify-subnet-attribute --subnet-id "$PUBLIC_SUBNET_ID" --map-public-ip-on-launch --region "$AWS_REGION"
```

**3. Internet Gateway và route table cho public subnet:**

```bash
export IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=fitness-assistant-igw}]' \
  --region "$AWS_REGION" --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION"

export PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=fitness-assistant-public-rt}]' \
  --region "$AWS_REGION" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$PUBLIC_RT_ID" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID" --region "$AWS_REGION"
aws ec2 associate-route-table --route-table-id "$PUBLIC_RT_ID" --subnet-id "$PUBLIC_SUBNET_ID" --region "$AWS_REGION"
```

Private subnet chỉ giữ route "local" ngầm định của VPC — không tạo route table riêng hay NAT Gateway cho chúng (xem phần NAT Gateway ở trên).

**4. Security group:**

```bash
export EC2_SG_ID=$(aws ec2 create-security-group \
  --group-name fitness-assistant-ec2-sg --description "Fitness Assistant app server" \
  --vpc-id "$VPC_ID" --region "$AWS_REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$EC2_SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$AWS_REGION"
aws ec2 authorize-security-group-ingress --group-id "$EC2_SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$AWS_REGION"
aws ec2 authorize-security-group-ingress --group-id "$EC2_SG_ID" --protocol tcp --port 22 --cidr "$MY_IP" --region "$AWS_REGION"

export RDS_SG_ID=$(aws ec2 create-security-group \
  --group-name fitness-assistant-rds-sg --description "RDS PostgreSQL" \
  --vpc-id "$VPC_ID" --region "$AWS_REGION" --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$RDS_SG_ID" --protocol tcp --port 5432 \
  --source-group "$EC2_SG_ID" --region "$AWS_REGION"
```

### Xác minh

```bash
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region "$AWS_REGION" --query 'Vpcs[0].State'
aws ec2 describe-route-tables --route-table-ids "$PUBLIC_RT_ID" --region "$AWS_REGION"
```

TODO: đính kèm screenshot console thật xác nhận VPC, subnet, route table và Security Group sau khi tạo xong.
