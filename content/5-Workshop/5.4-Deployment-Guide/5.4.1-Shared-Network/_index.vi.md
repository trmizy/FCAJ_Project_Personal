---
title: "5.4.1 Hạ tầng mạng dùng chung"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.4.1. </b> "
---

Mọi service chạy trên Lambda dùng chung một VPC và một Lambda security group; Chat Service thêm security group riêng ở [5.4.10](../5.4.10-Chat-Service-ECS/).

#### Điểm xuất phát

VPC gốc, hai private application subnet, private DB subnet, cluster Aurora và Secrets Manager VPC endpoint đã có sẵn trước bước đầu tiên được ghi trong runbook, nên việc tạo chúng không được trình bày ở đây. Bảng dưới là tham chiếu cho mọi bước sau.

| Resource | Tên | Chi tiết |
|---|---|---|
| VPC | `fitness-assistant-dev-vpc` | `10.0.0.0/16`, `ap-southeast-1` |
| Private app subnet A | `fitness-assistant-dev-private-app-a` | `10.0.10.0/24`, `ap-southeast-1a` — nơi đặt Lambda và Fargate |
| Private app subnet B | `fitness-assistant-dev-private-app-b` | `10.0.11.0/24`, `ap-southeast-1b` |
| Private DB subnet | DB subnet group | Route table `fitness-assistant-dev-private-db-rt`, **không có** route NAT hay internet |
| Lambda security group | `fitness-assistant-dev-lambda-sg` | Dùng chung cho mọi Lambda function |
| Aurora security group | `fitness-assistant-dev-aurora-sg` | Inbound 5432 chỉ từ Lambda SG (và sau này từ Chat SG) |
| VPC endpoint security group | `fitness-assistant-dev-vpce-sg` | Inbound 443 từ Lambda SG; dùng cho endpoint Secrets Manager và OpenSearch |

Các bước dưới đây được thêm trong lúc triển khai User Service, khi Lambda đầu tiên cần truy cập internet outbound (gọi API Gateway, Bedrock và các AWS API khác) từ trong private subnet.

#### Bước 1 — Tạo và gắn Internet Gateway

**VPC → Internet gateways → Create internet gateway**, đặt tên `fitness-assistant-dev-igw`, sau đó **Actions → Attach to a VPC → `fitness-assistant-dev-vpc`**.

![Internet Gateway fitness-assistant-dev-igw đã gắn vào VPC](/images/workshop/runbook/img023.jpg)

#### Bước 2 — Tạo public subnet cho NAT Gateway

**VPC → Subnets → Create subnet**: VPC `fitness-assistant-dev-vpc`, tên `fitness-assistant-dev-public-a`, AZ `ap-southeast-1a`, CIDR `10.0.1.0/24`. Không bật auto-assign public IPv4 — NAT Gateway dùng Elastic IP riêng. Một public subnet là đủ cho một NAT Gateway ở DEV.

![Public subnet fitness-assistant-dev-public-a (10.0.1.0/24)](/images/workshop/runbook/img024.jpg)

#### Bước 3 — Tạo public route table

**VPC → Route tables → Create route table**: tên `fitness-assistant-dev-public-rt`, VPC `fitness-assistant-dev-vpc`. Trong **Routes → Edit routes**, thêm `0.0.0.0/0 → Internet Gateway fitness-assistant-dev-igw`.

![Public route table với 0.0.0.0/0 trỏ tới Internet Gateway](/images/workshop/runbook/img025.jpg)

Trong **Subnet associations → Edit subnet associations**, gắn `fitness-assistant-dev-public-a`.

![Gắn subnet fitness-assistant-dev-public-a](/images/workshop/runbook/img026.jpg)

#### Bước 4 — Tạo NAT Gateway

**VPC → NAT gateways → Create NAT gateway**: tên `fitness-assistant-dev-nat-a`, subnet `fitness-assistant-dev-public-a`, connectivity type **Public**, và **Allocate Elastic IP**. Chờ trạng thái chuyển từ *Pending* sang *Available* rồi mới sửa private route table.

![NAT Gateway fitness-assistant-dev-nat-a với Elastic IP](/images/workshop/runbook/img027.jpg)

#### Bước 5 — Cho private app subnet đi internet qua NAT Gateway

**VPC → Route tables → `fitness-assistant-dev-private-app-rt` → Routes → Edit routes**, thêm `0.0.0.0/0 → NAT Gateway fitness-assistant-dev-nat-a`.

![Private app route table: 10.0.0.0/16 local và 0.0.0.0/0 qua NAT Gateway](/images/workshop/runbook/img028.jpg)

Route table lúc này có:

```
10.0.0.0/16   → local
0.0.0.0/0     → fitness-assistant-dev-nat-a
```

Cả hai private app subnet đều dùng route table này, nên mọi Lambda đặt trong đó đều có đường ra ngoài:

```
Lambda → Private App Subnet → NAT Gateway → Internet Gateway → API Gateway / Bedrock / AWS APIs
```

{{% notice warning %}}
**Không** thêm route NAT vào `fitness-assistant-dev-private-db-rt`. DB subnet phải hoàn toàn private.
{{% /notice %}}

#### Bước 6 — Thêm public subnet thứ hai (Chat ALB cần dùng sau này) {#second-public-subnet}

Application Load Balancer internet-facing cần subnet ở ít nhất hai Availability Zone. Khi triển khai Chat Service, một public subnet thứ hai được thêm: **VPC → Subnets → Create subnet**, tên `fitness-assistant-dev-public-b`, AZ `ap-southeast-1b`, CIDR `10.0.2.0/24`.

![Tạo fitness-assistant-dev-public-b (10.0.2.0/24) ở ap-southeast-1b](/images/workshop/runbook/img305.jpg)

Sau đó chọn subnet mới → **Actions → Edit route table association** và chọn `fitness-assistant-dev-public-rt`, cùng route table với `public-a`.

![Edit route table association cho public subnet mới](/images/workshop/runbook/img306.jpg)

![public-b đã gắn với fitness-assistant-dev-public-rt (local + 0.0.0.0/0 → IGW)](/images/workshop/runbook/img307.jpg)

#### Kết quả

| Subnet | CIDR | AZ | Route table | Chứa |
|---|---|---|---|---|
| `public-a` | 10.0.1.0/24 | 1a | `public-rt` (→ IGW) | NAT Gateway, Chat ALB |
| `public-b` | 10.0.2.0/24 | 1b | `public-rt` (→ IGW) | Chat ALB |
| `private-app-a` | 10.0.10.0/24 | 1a | `private-app-rt` (→ NAT) | Lambda, Fargate task |
| `private-app-b` | 10.0.11.0/24 | 1b | `private-app-rt` (→ NAT) | Lambda, Fargate task |
| private DB subnet | — | 1a/1b | `private-db-rt` (không ra internet) | Aurora |
