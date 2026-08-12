---
title: "Worklog Tuần 3"
date: 2026-08-17
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### Mục tiêu tuần 3:

- Học và thực hành các bài lab về migration: VM Import/Export và Database Migration.
- Nghiên cứu các chiến lược migrate lên AWS (Rehost, Replatform, Refactor).
- Tiếp tục phân tích source code project cá nhân, chuẩn bị viết Dockerfile cho production.

### Các công việc cần triển khai trong tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Workshop / Tài liệu tham khảo |
|-----------|--------------|-----------------|-------------------------------|
| - Học các bài lab về VM Import/Export và Database Migration <br/> - Nghiên cứu chiến lược migration <br/> - Phân tích Dockerfile hiện có trong project | 17-08-2026 | 22-08-2026 | 14: https://000014.awsstudygroup.com/ <br/> 43: https://000043.awsstudygroup.com/ |

### Kết quả đạt được tuần 3:

**Tổng quan:**

Tuần này học về migration - các cách di chuyển hệ thống từ on-premise hoặc cloud khác lên AWS. Mặc dù project cá nhân là build từ đầu trên AWS nhưng hiểu về migration vẫn quan trọng, đặc biệt là phần Database Migration Service (DMS) có thể dùng cho việc sync data sau này. Ngoài ra cũng bắt đầu tìm hiểu Dockerfile để chuẩn bị containerize app.

**Kiến thức đã học:**

- **VM Import/Export:** Cách import máy ảo (VMware, Hyper-V, VirtualBox) lên AWS EC2. Hiểu format OVA/OVF và các điều kiện để import thành công. Trong thực tế dự án mình build mới nên không cần import VM, nhưng biết concept này giúp hiểu cách AWS xử lý virtualization.

- **AWS Schema Conversion Tool (SCT):** Tool để convert database schema từ engine này sang engine khác (ví dụ Oracle → PostgreSQL, SQL Server → MySQL). SCT phân tích code và báo những gì có thể auto convert, những gì phải sửa tay. Rất hữu ích khi migrate database giữa các platform.

- **AWS Database Migration Service (DMS):** Service migrate data giữa databases với downtime tối thiểu. Có 2 mode: full load (migrate toàn bộ) và CDC (change data capture - sync liên tục). DMS support nhiều source/target: MySQL, PostgreSQL, Oracle, MongoDB, S3...

- **Migration Strategies (6R):** Học về 6 chiến lược migration phổ biến:
  - **Rehost (Lift and Shift):** Move nguyên si lên cloud, nhanh nhưng không tối ưu
  - **Replatform (Lift and Reshape):** Sửa một chút (RDS thay self-managed DB) nhưng không đổi core
  - **Refactor/Re-architect:** Viết lại để tận dụng cloud-native (serverless, containers)
  - **Repurchase:** Đổi sang SaaS thay vì tự host
  - **Retire:** Tắt app không dùng nữa
  - **Retain:** Giữ on-premise vì lý do đặc biệt

**Thực hành:**

- Làm lab VM Import/Export (lab 14) - practice import VM image lên EC2, config network và storage.
- Làm lab Database Migration (lab 43) - dùng DMS migrate data từ source DB sang target DB trên RDS. Setup replication instance, tạo endpoint, monitor migration task.
- Đọc Dockerfile hiện có trong project cá nhân (nếu có) để hiểu cách app được containerize. Note lại base image, dependencies, exposed port, entrypoint.
- Research multi-stage Docker build để giảm kích thước image production. Dev image thường to vì có nhiều build tools, production chỉ cần runtime.

**Khó khăn gặp phải:**

1. **VM Import troubleshooting:** Import VM lên EC2 bị lỗi "InvalidParameter" vì OVA file không đúng format. Phải dùng VMware/VirtualBox export lại đúng chuẩn OVF 1.0 hoặc 2.0.

2. **DMS replication lag:** Khi setup CDC (continuous replication), target DB bị lag so với source. Monitor CloudWatch metrics thấy CDCLatencySource tăng cao. Phải tune replication instance size.

3. **Schema conversion complexity:** SCT không auto convert được một số stored procedure phức tạp. Assessment report báo "Action Required", phải rewrite manually. Tốn thời gian nếu DB có nhiều logic.

4. **Docker multi-stage build:** Lần đầu viết multi-stage Dockerfile hơi confuse về cách copy artifact từ stage này sang stage khác. Build stage cần build tools (npm, webpack) nhưng production stage chỉ cần runtime (node).

5. **Dockerfile base image choice:** Chọn base image nào cho Node.js? `node:18`, `node:18-alpine`, hay `node:18-slim`? Alpine nhỏ nhất (50MB) nhưng dùng musl thay glibc, đôi khi có compatibility issue.

**Cách giải quyết:**

- **VM Import:** Đọc AWS docs về VM Import requirements. Export VM đúng format, disable virtual hardware features không support (USB controller, audio). Dùng `aws ec2 import-image` với đầy đủ parameters.

- **DMS lag:** Tăng replication instance size từ `dms.t3.micro` lên `dms.t3.small`. Enable Multi-AZ nếu cần high availability. Monitor metrics CloudWatch thường xuyên.

- **Schema conversion:** Chạy SCT assessment trước khi migrate để biết workload. Với stored procedure phức tạp, có thể refactor logic sang application layer thay vì giữ trong DB. Modern practice là thin database, thick application.

- **Multi-stage build:** Học pattern: stage 1 (builder) install dev deps + build, stage 2 (production) chỉ copy artifact từ builder.Ví dụ:
  ```dockerfile
  FROM node:18 AS builder
  COPY package*.json ./
  RUN npm ci
  COPY . .
  RUN npm run build
  
  FROM node:18-slim
  COPY --from=builder /app/dist ./dist
  CMD ["node", "dist/index.js"]
  ```

- **Base image:** Với project cá nhân dùng `node:18-slim` là balance tốt: nhỏ hơn full image, ổn định hơn alpine. Alpine để sau khi đã test kỹ, vì có thể gặp issue với native modules.
