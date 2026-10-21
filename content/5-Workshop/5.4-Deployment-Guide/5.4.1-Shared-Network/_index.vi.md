---
title: "5.4.1 Hạ tầng mạng dùng chung"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.4.1. </b> "
---

Mọi service chạy trên Lambda dùng chung một VPC và một Lambda security group; Chat Service thêm security group riêng ở [5.4.10](../5.4.10-Chat-Service-ECS/).

Trong mọi ảnh ở các trang triển khai, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của thao tác được viết ngay phía trên ảnh. Với thao tác mà runbook không có ảnh chụp, phần văn bản sẽ ghi rõ.

#### Điểm xuất phát

VPC nền, hai private application subnet, các private DB subnet, cluster Aurora và Secrets Manager VPC endpoint đã tồn tại trước bước đầu tiên được ghi trong runbook, nên việc tạo chúng không được trình bày ở đây. Bảng dưới là tham chiếu cho mọi bước sau.

| Resource | Tên | Chi tiết |
|---|---|---|
| VPC | `fitness-assistant-dev-vpc` | `10.0.0.0/16`, `ap-southeast-1` |
| Private app subnet A | `fitness-assistant-dev-private-app-a` | `10.0.10.0/24`, `ap-southeast-1a` — nơi đặt Lambda và Fargate |
| Private app subnet B | `fitness-assistant-dev-private-app-b` | `10.0.11.0/24`, `ap-southeast-1b` |
| Private DB subnets | DB subnet group | Route table `fitness-assistant-dev-private-db-rt`, **không** có route NAT hay internet |
| Lambda security group | `fitness-assistant-dev-lambda-sg` | Dùng chung cho mọi Lambda function |
| Aurora security group | `fitness-assistant-dev-aurora-sg` | Inbound 5432 chỉ từ Lambda SG (và sau này là Chat SG) |
| VPC endpoint security group | `fitness-assistant-dev-vpce-sg` | Inbound 443 từ Lambda SG; dùng cho endpoint Secrets Manager và OpenSearch |

Các bước dưới đây được bổ sung trong lúc triển khai User Service, khi Lambda đầu tiên cần truy cập internet ra ngoài (để gọi API Gateway, Bedrock và các AWS API khác) từ bên trong private subnet.

#### Bước 1 — Tạo và gắn Internet Gateway

**1.1 — Tạo gateway.** Mở **VPC → Internet gateways → Create internet gateway**, nhập name tag `fitness-assistant-dev-igw` rồi bấm **Create internet gateway**.

![Create internet gateway: name tag fitness-assistant-dev-igw, rồi Create](/images/workshop/runbook/img023.jpg)

**1.2 — Gắn vào VPC.** Mở gateway vừa tạo và chọn **Actions → Attach to a VPC → `fitness-assistant-dev-vpc`**. *Runbook không có ảnh chụp thao tác này.*

#### Bước 2 — Tạo public subnet cho NAT Gateway

**2.1 — Điền thông tin subnet.** Mở **VPC → Subnets → Create subnet** và nhập: VPC `fitness-assistant-dev-vpc`, subnet name `fitness-assistant-dev-public-a`, Availability Zone `ap-southeast-1a`, IPv4 subnet CIDR block `10.0.1.0/24`. Sau đó cuộn xuống và bấm **Create subnet**.

![Create subnet: VPC, tên public-a, ap-southeast-1a, CIDR 10.0.1.0/24](/images/workshop/runbook/img024.jpg)

Auto-assign public IPv4 để tắt — NAT Gateway dùng Elastic IP riêng. Một public subnet là đủ cho một NAT Gateway trong DEV.

#### Bước 3 — Tạo public route table

**3.1 — Tạo bảng.** Mở **VPC → Route tables → Create route table**, đặt tên `fitness-assistant-dev-public-rt`, chọn VPC `fitness-assistant-dev-vpc` và bấm **Create route table**. *Runbook không có ảnh chụp thao tác này.*

**3.2 — Thêm route ra internet.** Chọn bảng vừa tạo, mở **Routes → Edit routes → Add route**, nhập destination `0.0.0.0/0`, chọn target **Internet Gateway** `fitness-assistant-dev-igw`, rồi bấm **Save changes**.

![Edit routes: 0.0.0.0/0 tới Internet Gateway, Save changes](/images/workshop/runbook/img025.jpg)

**3.3 — Gắn public subnet.** Mở **Subnet associations → Edit subnet associations**, tick `fitness-assistant-dev-public-a` và bấm **Save associations**.

![Edit subnet associations: tick public-a, Save associations](/images/workshop/runbook/img026.jpg)

#### Bước 4 — Tạo NAT Gateway

**4.1 — Điền thông tin gateway.** Mở **VPC → NAT gateways → Create NAT gateway** và nhập: name `fitness-assistant-dev-nat-a`, availability mode **Zonal**, subnet `fitness-assistant-dev-public-a`, connectivity type **Public**, và một Elastic IP (bấm **Allocate Elastic IP** để lấy). Sau đó bấm **Create NAT gateway**.

![Create NAT gateway: name, Zonal, subnet public-a, Public, Elastic IP, Create](/images/workshop/runbook/img027.jpg)

Chờ trạng thái chuyển từ *Pending* sang *Available* rồi mới sửa private route table.

#### Bước 5 — Định tuyến private app subnet qua NAT Gateway

**5.1 — Thêm route NAT.** Mở **VPC → Route tables → `fitness-assistant-dev-private-app-rt` → Routes → Edit routes → Add route**, nhập destination `0.0.0.0/0`, chọn target **NAT Gateway** `fitness-assistant-dev-nat-a`, rồi bấm **Save changes**.

![Private app route table: 0.0.0.0/0 tới NAT Gateway, Save changes](/images/workshop/runbook/img028.jpg)

Route table giờ chứa:

```
10.0.0.0/16   → local
0.0.0.0/0     → fitness-assistant-dev-nat-a
```

Cả hai private app subnet dùng route table này, nên mọi Lambda đặt trong đó đều có truy cập ra ngoài:

```
Lambda → Private App Subnet → NAT Gateway → Internet Gateway → API Gateway / Bedrock / AWS APIs
```

{{% notice warning %}}
**Không** thêm route NAT vào `fitness-assistant-dev-private-db-rt`. Các DB subnet phải hoàn toàn private.
{{% /notice %}}

#### Bước 6 — Thêm public subnet thứ hai (Chat ALB cần ở bước sau) {#second-public-subnet}

Một Application Load Balancer internet-facing cần subnet ở ít nhất hai Availability Zone. Khi triển khai Chat Service, một public subnet thứ hai đã được thêm.

**6.1 — Tạo subnet.** Mở **VPC → Subnets → Create subnet** và nhập: VPC `fitness-assistant-dev-vpc`, subnet name `fitness-assistant-dev-public-b`, Availability Zone `ap-southeast-1b`, IPv4 subnet CIDR block `10.0.2.0/24`. Sau đó bấm **Create subnet**.

![Create subnet: VPC, tên public-b, ap-southeast-1b, CIDR 10.0.2.0/24, Create subnet](/images/workshop/runbook/img305.jpg)

**6.2 — Mở phần gắn route table.** Chọn subnet mới và chọn **Actions → Edit route table association**.

![Danh sách Subnets: menu Actions, Edit route table association](/images/workshop/runbook/img306.jpg)

**6.3 — Dùng public route table.** Chọn `fitness-assistant-dev-public-rt`, cùng bảng với `public-a` (local + `0.0.0.0/0` → IGW), rồi bấm **Save**.

![Edit route table association: fitness-assistant-dev-public-rt, Save](/images/workshop/runbook/img307.jpg)

#### Kết quả

| Subnet | CIDR | AZ | Route table | Chứa |
|---|---|---|---|---|
| `public-a` | 10.0.1.0/24 | 1a | `public-rt` (→ IGW) | NAT Gateway, Chat ALB |
| `public-b` | 10.0.2.0/24 | 1b | `public-rt` (→ IGW) | Chat ALB |
| `private-app-a` | 10.0.10.0/24 | 1a | `private-app-rt` (→ NAT) | Lambda, Fargate task |
| `private-app-b` | 10.0.11.0/24 | 1b | `private-app-rt` (→ NAT) | Lambda, Fargate task |
| private DB subnets | — | 1a/1b | `private-db-rt` (không internet) | Aurora |
