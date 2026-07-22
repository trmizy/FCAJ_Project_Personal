---
title: "Tuần 2"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 1.2. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Phân tích chi tiết frontend, backend và các microservices (nếu có) trong `fitness-assistant`.
- Xác định port, dependency và biến môi trường cần thiết của từng service dựa trên source thực tế (không giả định mặc định).
- Vẽ luồng request giữa frontend, tầng backend/API và database.

### Công việc đã thực hiện

- Đọc source backend (routes, controllers/services, file schema ORM) để xác định ranh giới service thực tế.
- Xem xét file `.env.example` (hoặc tương đương) nếu có, để liệt kê chính xác các biến môi trường cần thiết.
- Xem xét source frontend để xác định framework, build tool, và cách gọi API tới backend (base API URL, cấu hình proxy).
- Phác thảo sơ đồ luồng request: trình duyệt → frontend → (các) service backend → database/cache.

### Kết quả đạt được

- Bản đồ đã xác minh về service/port/biến môi trường, dựa trên các file thực tế trong repository.
- TODO: Bổ sung sơ đồ luồng request hoàn chỉnh (draw.io hoặc tương đương) sau khi xác nhận bằng cách chạy local thành công.

### Khó khăn

- Phân biệt giữa API routing nội bộ của ứng dụng (ví dụ router Express/Node thông thường) và dịch vụ **Amazon API Gateway** thực sự — đây là hai khái niệm khác nhau và không được nhầm lẫn khi mô tả kiến trúc.

### Cách giải quyết

- Ghi chú rõ ràng, với mỗi thành phần dạng "gateway" tìm thấy trong source, liệu đó là code ứng dụng (ví dụ reverse proxy hoặc router nội bộ) hay là dịch vụ AWS managed thực sự, và giữ sự phân biệt này xuyên suốt các mục Workshop và Proposal.

### Kỹ năng / Dịch vụ AWS đã học

- Ôn lại khái niệm reverse proxy so với API Gateway.
- Kỷ luật ghi chú khi chuyển đổi một codebase có sẵn thành sơ đồ hạ tầng chính xác.

### Bằng chứng cần bổ sung

- TODO: Screenshot cấu trúc codebase (IDE hoặc output lệnh `tree`).
- TODO: Sơ đồ luồng request đã export.
- TODO: Danh sách biến môi trường đã xác nhận theo từng service.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Xem xét routes/services/schema ORM backend | [TODO_DATE] | [TODO_DATE] | Source `fitness-assistant` |
| 2 | Xem xét cấu trúc frontend và cấu hình base API URL | [TODO_DATE] | [TODO_DATE] | Source `fitness-assistant` |
| 3 | Liệt kê biến môi trường đã xác nhận theo từng service | [TODO_DATE] | [TODO_DATE] | File `.env.example` |
| 4 | Phác thảo sơ đồ luồng request | [TODO_DATE] | [TODO_DATE] | draw.io |

### Checklist hoàn thành

- [ ] Đã xác định ranh giới service backend từ source
- [ ] Đã xác nhận framework frontend và base API URL
- [ ] Đã liệt kê biến môi trường theo từng service
- [ ] Đã tạo bản nháp sơ đồ luồng request

### Liên kết Workshop tương ứng

- [5.2 Architecture](../../5-Workshop/5.2-Architecture/)
