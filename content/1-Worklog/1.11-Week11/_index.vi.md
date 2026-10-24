---
title: "Worklog Tuần 11"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 1.11. </b> "
draft: false
---

### Mục tiêu tuần 11:

- Hoàn thiện và cải thiện frontend của project cá nhân (Gymini Fitness Assistant)
- Đảm bảo trải nghiệm người dùng mượt mà và sửa các lỗi giao diện hoặc chức năng ở mọi màn hình

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Rà soát web app của project cá nhân theo từng màn hình (Roadmap, Workout, Nutrition, Chat, Admin) và sửa các lỗi giao diện, chức năng | 12-10-2026 | 17-10-2026 | |
| Kiểm tra mọi màn hình đã chỉnh ở các độ rộng điện thoại (360, 375, 390 và 412 px) và giữ nguyên màu của theme sáng và tối hiện có | 12-10-2026 | 17-10-2026 | |
| Làm các thao tác quản lý người dùng của Admin hoạt động (xem hồ sơ, đổi vai trò, khoá và mở khoá) kèm hộp thoại xác nhận và thông báo | 12-10-2026 | 17-10-2026 | |
| Build web app và đưa lên S3 bucket đứng sau CloudFront | 12-10-2026 | 17-10-2026 | |

### Kết quả đạt được tuần 11:

**Tổng quan:**

Tuần này dành để hoàn thiện frontend của project cá nhân. Mình đi qua từng màn hình, sửa những chỗ lỗi hoặc khó hiểu, và kiểm tra mỗi thay đổi trên màn hình cỡ điện thoại trước khi đưa lên.

**Kiến thức lý thuyết học được:**

- **Nguyên tắc UI/UX:** Hiểu sâu hơn về thiết kế giao diện qua việc xử lý các vấn đề dùng thực tế, như nút bấm không làm gì và bố cục không vừa màn hình điện thoại.

- **Cải thiện lặp:** Học cách tự rà soát công việc theo checklist, sửa từng vấn đề một và kiểm tra trước khi sang việc tiếp theo.

**Hands-on labs đã thực hiện:**

- Sửa các lỗi hiện có và cải thiện độ responsive, thiết kế của các màn hình chính trong web app
- Nối menu quản lý người dùng của Admin với các API đổi vai trò, mở khoá và khoá có sẵn, đồng thời chặn thao tác trên tài khoản đang đăng nhập
- Đưa bản build mới lên S3 và kiểm tra qua địa chỉ CloudFront

**Áp dụng vào Fitness Assistant:**

**Cải thiện UI/UX đã áp dụng:**
- Kiểm tra responsive ở bốn độ rộng điện thoại
- Một theme chung cho chế độ sáng và tối, không dùng màu riêng lẻ
- Thông báo xác nhận và kết quả rõ ràng cho các thao tác rủi ro

**Tiếp theo cho Fitness Assistant:**
- Giữ web app và môi trường đã deploy đồng bộ theo từng bản phát hành
- Tiếp tục triển khai các backend service trên AWS
