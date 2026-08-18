---
title: "Worklog Tuần 3"
date: 2026-08-17
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### Mục tiêu tuần 3:

- Tìm hiểu các chiến lược migration lên AWS (7Rs).
- Thực hành/tìm hiểu VM Import/Export và Database Migration.
- Phân tích Dockerfile production cho project cá nhân.

### Các công việc cần triển khai trong tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Workshop / Tài liệu tham khảo |
|-----------|--------------|-----------------|-------------------------------|
| - Tìm hiểu 7Rs migration strategies <br/> - Thực hành VM Import/Export <br/> - Tìm hiểu Database Migration với SCT và DMS <br/> - Phân tích Docker production | 17-08-2026 | 22-08-2026 | Lab 14: https://000014.awsstudygroup.com/ <br/> Lab 43: https://000043.awsstudygroup.com/ <br/> AWS Docs: 7Rs Migration Strategies |

### Kết quả đạt được tuần 3:

**Tổng quan:**

Tuần này tập trung vào migration - tìm hiểu các chiến lược và công cụ để di chuyển workload lên AWS. Mặc dù project cá nhân được build từ đầu trên AWS, việc hiểu migration strategies giúp đưa ra quyết định kiến trúc phù hợp. Ngoài ra cũng bắt đầu phân tích cách đóng gói production container để chuẩn bị deploy.

**1. AWS Migration Strategies - 7Rs**

Tìm hiểu 7 chiến lược migration của AWS:

- **Rehost (Lift and Shift):** Di chuyển workload lên cloud gần như nguyên trạng, không thay đổi code hoặc kiến trúc. Phù hợp khi cần migrate nhanh hoặc workload chưa cần tối ưu ngay.

- **Relocate:** Di chuyển hạ tầng/workload (thường là VMware-based) lên AWS mà không thay đổi kiến trúc đáng kể. Sử dụng VMware Cloud on AWS để giữ nguyên môi trường vSphere.

- **Replatform (Lift and Reshape):** Tối ưu một phần để tận dụng cloud services (ví dụ: chuyển database tự quản sang RDS, hoặc dùng ELB thay reverse proxy) nhưng không thay đổi core application. Balance giữa tốc độ migrate và cloud benefits.

- **Refactor/Re-architect:** Thiết kế lại application để tận dụng cloud-native architecture (containers, serverless, microservices, managed services). Tốn effort nhưng tối ưu nhất về cost và scalability.

- **Repurchase:** Chuyển sang sản phẩm/SaaS khác thay vì self-host. Ví dụ: migrate từ on-premise CRM sang Salesforce, hoặc từ custom email server sang Microsoft 365.

- **Retire:** Loại bỏ các hệ thống không còn cần thiết hoặc không sử dụng. Giảm chi phí maintain và migration effort.

- **Retain:** Giữ lại workload tại môi trường hiện tại vì lý do compliance, technical dependencies, hoặc chưa có business case để migrate.

Với project cá nhân, chiến lược phù hợp là **Refactor** vì đây là greenfield project có thể thiết kế cloud-native từ đầu.

**2. VM Import/Export**

Qua workshop lab 14, tìm hiểu quy trình import VM từ on-premise lên AWS:

**Workflow:**
1. Export VM từ virtualization environment (VMware/Hyper-V/VirtualBox) → thu được virtual disk files (VMDK, VHD, VHDX)
2. Upload virtual disk lên S3 bucket
3. Sử dụng AWS VM Import/Export để tạo AMI từ virtual disk
4. Launch EC2 instance từ AMI đã import

**Các điểm cần lưu ý:**

- **IAM role và permissions:** Cần tạo IAM role tên `vmimport` với trust policy cho phép VM Import service và quyền truy cập S3 bucket chứa disk images. Đây là requirement bắt buộc và thường là nguyên nhân lỗi `InvalidParameter` nếu thiếu hoặc config sai.

- **Supported formats:** AWS hỗ trợ VMDK, VHD, VHDX, OVA (chứa VMDK). Virtual disk cần được export đúng format tương thích.

- **S3 bucket:** Virtual disk file cần upload lên S3 trong cùng region với EC2 instance sẽ launch. File size có thể lớn (VMs thường vài GB đến vài chục GB).

- **Import process:** Sử dụng AWS CLI `aws ec2 import-image` với parameters đầy đủ (disk containers, description, role name). Quá trình import có thể mất từ vài phút đến vài giờ tuỳ disk size.

**Workshop không đi sâu vào network/storage config phức tạp.** Sau khi có AMI, launch EC2 instance theo flow thông thường và kiểm tra instance hoạt động.

**3. Database Migration**

Qua workshop lab 43, tìm hiểu hai công cụ chính:

**AWS Schema Conversion Tool (SCT):**
- Convert database schema và code objects giữa các database engines khác nhau (Oracle → PostgreSQL, SQL Server → MySQL, etc.)
- Phân tích source schema và tự động convert phần lớn objects: tables, views, stored procedures, functions, triggers
- Tạo Assessment Report để nhận biết:
  - Objects có thể auto-convert
  - Objects cần manual action (đánh dấu "Action Required")
  - Ước lượng complexity và effort

Với các stored procedures hoặc database objects không thể tự động convert, cần đánh giá từng trường hợp: rewrite cho target engine hoặc refactor logic sang application layer nếu phù hợp với kiến trúc.

**AWS Database Migration Service (DMS):**

DMS giúp migrate data với minimal downtime. **Các kiểu migration:**

- **Full load:** Di chuyển toàn bộ dữ liệu hiện có từ source sang target. Phù hợp khi có thể afford downtime hoặc là initial load.

- **Full load + CDC (Change Data Capture):** Di chuyển dữ liệu hiện có trước, sau đó liên tục replicate các thay đổi phát sinh ở source. Đây là phương án phổ biến để **giảm downtime** - application vẫn ghi vào source DB, DMS sync changes sang target, sau đó cutover.

- **CDC only:** Chỉ replicate changes từ một thời điểm/log position xác định, không load initial data. Dùng khi target đã có data hoặc kết hợp với backup/restore riêng.

**Thành phần DMS:**
- **Source endpoint:** Kết nối đến source database (on-premise, EC2, RDS)
- **Target endpoint:** Kết nối đến target database (RDS, Aurora, Redshift, S3, DynamoDB...)
- **Replication instance:** EC2 instance chạy DMS software, thực hiện extract và load data
- **Replication task:** Định nghĩa migration type, table mappings, transformation rules

**Monitoring:**

DMS metrics quan trọng cần theo dõi qua CloudWatch:
- **CDCLatencySource:** Thời gian delay đọc/capture thay đổi từ source. Nếu tăng cao cho thấy quá trình capture bị trễ.
- **CDCLatencyTarget:** Thời gian delay apply thay đổi vào target.
- **CPU/Memory/Storage:** Của replication instance.
- **Network throughput:** Giữa source, replication instance, target.

Khi CDC latency tăng, cần troubleshoot:
- Kiểm tra CPU, memory, swap usage của replication instance
- Kiểm tra disk I/O
- Kiểm tra network bandwidth
- Xem xét workload/transaction volume tại source
- Review replication task settings
- Kiểm tra khả năng xử lý của target database

Sau khi xác định bottleneck, có thể scale replication instance size lên nếu cần.

**Multi-AZ:**

Multi-AZ cho DMS replication instance chủ yếu phục vụ **high availability và failover**, không phải là giải pháp trực tiếp để cải thiện performance hay giảm latency. Enable Multi-AZ khi cần:
- Tăng reliability cho long-running migration
- Disaster recovery capability
- Production migrations yêu cầu uptime cao

**4. Docker Production Analysis**

Với project cá nhân, cần phân tích cách đóng gói production container.

**Multi-stage Docker build:**

Multi-stage build giúp tách biệt build environment và runtime environment:

```dockerfile
# Stage 1: Builder - cài dependencies và build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Runtime - chỉ copy artifacts cần thiết
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

**Lợi ích:**
- Image size nhỏ hơn (không chứa dev dependencies, source code, build tools)
- Giảm attack surface (ít packages và tools trong production image)
- Tách biệt rõ ràng giữa build và runtime concerns

**Frontend static với Nginx:**

Với frontend build thành static files (React/Vue/Angular), pattern phổ biến:

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
# Output: /app/dist

# Runtime stage
FROM nginx:1.25-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Runtime image chỉ là Nginx serving static files, không cần Node.js runtime.

**Base image considerations:**

**Alpine Linux:**
- Ưu điểm: image nhỏ (thường < 100MB), ít packages mặc định, giảm attack surface
- Hạn chế: sử dụng musl libc thay vì glibc, một số native modules có thể gặp compatibility issues

**Debian-based (slim variants):**
- Ưu điểm: sử dụng glibc, compatibility tốt hơn, dễ debug native dependencies
- Hạn chế: image lớn hơn Alpine

Cần lựa chọn dựa trên trade-off giữa size và compatibility.

**Node.js version lifecycle:**

Khi chọn Node.js base image cho production tháng 08/2026, cần ưu tiên phiên bản còn trong LTS (Long Term Support) hoặc ít nhất là Active support. Kiểm tra [Node.js release schedule](https://nodejs.org/en/about/previous-releases) để đảm bảo version đang dùng còn nhận security updates.

Node 18 đã End-of-Life vào tháng 04/2025, không nên dùng cho production mới. Node 20 LTS còn support đến tháng 04/2026. Nếu project dùng Node 20, cần đánh giá khả năng upgrade lên Node 22 LTS (active đến 2027) sau khi test compatibility.

**Các vấn đề có thể gặp và lưu ý:**

- **.dockerignore:** Cần có để tránh copy `node_modules`, `.env`, `.git`, build artifacts vào build context. Giảm build time và tránh leak sensitive data.

- **Non-root user:** Nên chạy application với non-root user trong container để tăng security. Thêm `USER node` (hoặc tạo custom user) trước CMD.

- **Health checks:** Thêm HEALTHCHECK instruction để container orchestrator (ECS, Kubernetes) biết container status.

- **Secrets management:** Không hardcode credentials vào Dockerfile hoặc image. Dùng environment variables hoặc AWS Secrets Manager khi deploy.

### Bài học rút ra:

- Migration không chỉ là di chuyển dữ liệu mà cần lựa chọn strategy phù hợp với từng workload.
- VM migration yêu cầu quan tâm IAM permissions, disk formats và S3 setup đúng.
- Database migration cần tách biệt schema conversion (SCT) và data migration (DMS).
- CDC giúp giảm downtime nhưng cần monitoring để đảm bảo không bị lag.
- Multi-AZ phục vụ availability, không phải performance scaling.
- Multi-stage Docker build giúp tối ưu production images.
- Base image selection cần balance giữa size, compatibility và security lifecycle.
- Việc phân tích production container requirements giúp chuẩn bị tốt hơn cho deployment phase.

### Tài liệu tham khảo:

- Workshop VM Import/Export: https://000014.awsstudygroup.com/
- Workshop Database Migration: https://000043.awsstudygroup.com/
- AWS Migration Strategies (7Rs): https://docs.aws.amazon.com/prescriptive-guidance/latest/large-migration-guide/migration-strategies.html
- AWS VM Import/Export: https://docs.aws.amazon.com/vm-import/latest/userguide/what-is-vmimport.html
- AWS DMS: https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html
- AWS SCT: https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html
