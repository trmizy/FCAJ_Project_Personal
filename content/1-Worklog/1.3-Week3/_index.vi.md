---
title: "Worklog Tuần 3"
date: 2026-08-17
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### Mục tiêu tuần 3:

- Tìm hiểu các chiến lược migration lên AWS (7Rs).
- Thực hành VM Import/Export và Database Migration.
- Phân tích Dockerfile production.

### Các công việc cần triển khai trong tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Workshop / Tài liệu tham khảo |
|-----------|--------------|-----------------|-------------------------------|
| - Tìm hiểu 7Rs migration <br/> - Practice VM Import/Export <br/> - Research Database Migration <br/> - Phân tích Docker production | 17-08-2026 | 22-08-2026 | Lab 14: https://000014.awsstudygroup.com/ <br/> Lab 43: https://000043.awsstudygroup.com/ |

### Kết quả đạt được tuần 3:

**Tổng quan:**

Tuần này học về migration - các cách chuyển hệ thống lên AWS. Mặc dù project mình build mới hoàn toàn nhưng hiểu migration vẫn có ích, đặc biệt phần DMS có thể xài sau này. Ngoài ra bắt đầu tìm hiểu cách đóng gói Docker cho production.

**Kiến thức đã học:**

**1. AWS Migration - 7Rs**

AWS có 7 chiến lược migrate:
- **Rehost:** Move nguyên xi lên cloud, nhanh nhưng chưa tối ưu
- **Relocate:** Chuyển VMware workload lên VMware Cloud on AWS
- **Replatform:** Sửa một tí để dùng managed services (RDS...)
- **Refactor:** Viết lại app cloud-native (containers, serverless)
- **Repurchase:** Đổi sang SaaS thay vì self-host
- **Retire:** Tắt app không dùng
- **Retain:** Giữ on-premise

Project mình thì Refactor từ đầu vì làm mới.

**2. VM Import/Export**

Qua lab 14 hiểu flow import VM lên AWS:
1. Export VM từ VMware/Hyper-V → virtual disk (VMDK, VHD)
2. Upload disk lên S3
3. Dùng `aws ec2 import-image` tạo AMI
4. Launch EC2 từ AMI

Điểm cần lưu ý:
- IAM role `vmimport` phải có trust policy và quyền S3, thiếu sẽ lỗi InvalidParameter
- Disk format phải support (VMDK, VHD, VHDX, OVA)
- S3 bucket cùng region với EC2

**3. Database Migration**

**AWS SCT:**
- Convert schema giữa các DB engines (Oracle → PostgreSQL...)
- Assessment report cho biết convert được gì, manual action là gì
- Stored procedure phức tạp thường phải rewrite thủ công

**AWS DMS:**

DMS có 3 kiểu migration:
- **Full load:** Migrate toàn bộ data, dùng khi có downtime
- **Full load + CDC:** Migrate data trước, sau đó sync changes liên tục để giảm downtime
- **CDC only:** Chỉ sync changes từ 1 thời điểm

Thành phần DMS:
- Source/Target endpoints
- Replication instance (EC2 chạy DMS)
- Replication task

**Monitoring:**

Metrics quan trọng:
- **CDCLatencySource/Target:** Độ trễ capture/apply changes
- CPU/Memory/Disk I/O của replication instance
- Network throughput

Nếu CDC latency cao, cần check CPU, memory, I/O, network, source workload rồi mới quyết định scale instance.

**Multi-AZ:** Chỉ để high availability, không phải fix performance.

**4. Docker Production**

**Multi-stage build:**

Pattern tách build và runtime:

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci && npm run build

# Runtime stage  
FROM node:20-alpine
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

Image nhỏ hơn vì không chứa dev deps và source code.

**Frontend static + Nginx:**

```dockerfile
FROM node:20-alpine AS builder
RUN npm ci && npm run build

FROM nginx:1.25-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

Runtime chỉ cần Nginx, không cần Node.

**Base image:**
- **Alpine:** Nhỏ nhưng dùng musl libc, đôi khi native module lỗi
- **Debian slim:** Lớn hơn nhưng compatibility tốt

**Node version:**
- Node 18 EOL rồi (04/2025), không xài production
- Node 20 LTS đến 04/2026
- Nên cân nhắc Node 22 LTS

**Lưu ý:**
- Phải có `.dockerignore`
- Chạy non-root user
- Không hardcode secrets vào image

### Bài học:

- Migration cần chọn strategy đúng với từng workload
- VM import quan trọng nhất là IAM role vmimport
- Database migration tách schema conversion và data migration
- CDC giúp giảm downtime nhưng phải monitor
- Multi-AZ = availability, không phải performance
- Multi-stage build giúp image nhỏ và secure hơn
- Base image cần cân nhắc size vs compatibility

### Tài liệu tham khảo:

- Lab 14 VM Import: https://000014.awsstudygroup.com/
- Lab 43 Database Migration: https://000043.awsstudygroup.com/
- AWS 7Rs: https://docs.aws.amazon.com/prescriptive-guidance/latest/large-migration-guide/migration-strategies.html
