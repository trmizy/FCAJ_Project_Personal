---
title: "Tuần 3"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Xem xét (các) Dockerfile hiện có trong `fitness-assistant` và xác định đó là dev-only hay đã sẵn sàng cho production.
- Soạn thảo Dockerfile hướng production (multi-stage build, không chạy dev watcher, có `.dockerignore`, dùng non-root user nếu tương thích).
- Kiểm tra container ở local bằng Docker Compose trước khi chuyển sang AWS.

### Công việc đã thực hiện

- Kiểm tra (các) Dockerfile hiện có theo từng service/app về base image, các bước build và CMD/ENTRYPOINT.
- Soạn thảo `Dockerfile.production.example` cho các service cần thiết, dựa trên công cụ build thực tế tìm thấy trong source (ví dụ tên script `npm run build` thực tế).
- Thêm file `.dockerignore` mẫu để tránh copy `node_modules`, `.env` và các artifact local khác vào image.
- Chạy thử build Docker Compose ở local để xác nhận image kiểu production khởi động và phục vụ đúng port mong đợi.

### Kết quả đạt được

- Bản nháp Dockerfile production build thành công ở local.
- TODO: Ghi lại kích thước image trước/sau khi tối ưu.

### Khó khăn

- Đảm bảo bước build production khớp đúng với tên script được định nghĩa trong `package.json`/cấu hình build thực tế của project, thay vì đoán chung chung.

### Cách giải quyết

- Đọc đúng các script trong `package.json` (hoặc tương đương) trước khi viết bất kỳ bước `RUN` build nào, để Dockerfile chỉ gọi các lệnh thực sự tồn tại trong repository.

### Kỹ năng / Dịch vụ AWS đã học

- Best practice đóng gói container liên quan trực tiếp đến yêu cầu của Amazon ECR (gắn tag, giảm số layer, không nhúng secret vào image).

### Bằng chứng cần bổ sung

- TODO: Output lệnh `docker build`.
- TODO: Output lệnh `docker images` thể hiện kích thước image.
- TODO: Screenshot container chạy ở local theo chế độ production.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Xem xét (các) Dockerfile hiện có | [TODO_DATE] | [TODO_DATE] | Source `fitness-assistant` |
| 2 | Soạn thảo `Dockerfile.production.example` theo từng service | [TODO_DATE] | [TODO_DATE] | — |
| 3 | Thêm `.dockerignore` và kiểm tra không copy secret vào image | [TODO_DATE] | [TODO_DATE] | — |
| 4 | Kiểm tra bằng Docker Compose ở local | [TODO_DATE] | [TODO_DATE] | — |

### Checklist hoàn thành

- [ ] Đã xem xét Dockerfile hiện có
- [ ] Đã tạo bản nháp Dockerfile production theo từng service
- [ ] Đã có `.dockerignore`
- [ ] Đã kiểm tra build/run bằng Docker Compose ở local

### Liên kết Workshop tương ứng

- [5.5 Production Containers](../../5-Workshop/5.5-Production-Containers/)
