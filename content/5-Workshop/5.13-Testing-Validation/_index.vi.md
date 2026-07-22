---
title: "5.13 Testing and Validation"
date: 2026-07-15
weight: 13
chapter: false
pre: " <b> 5.13. </b> "
---

{{% notice warning %}}
Không test case nào bên dưới được đánh dấu `PASS` cho đến khi thực sự được thực hiện trên một bản triển khai thật kèm bằng chứng. Trạng thái mặc định là `TODO / Not executed` — không thay đổi nếu không có screenshot, trích đoạn log, hoặc output lệnh đi kèm.
{{% /notice %}}

### Bảng test case

| ID | Test | Điều kiện tiên quyết | Các bước | Kết quả mong đợi | Bằng chứng | Trạng thái |
|----|------|----------------------|----------|-------------------|------------|------------|
| TC-01 | Frontend truy cập được | EC2 đã triển khai, biết DNS/IP | Mở `http://<EC2_IP>/` | Frontend load không lỗi | TODO | TODO / Not executed |
| TC-02 | Đăng ký người dùng | Frontend + auth-service truy cập được | Gửi form đăng ký với tài khoản mới | Tài khoản được tạo; phản hồi thành công từ `auth-service` | TODO | TODO / Not executed |
| TC-03 | Đăng nhập | Đã có tài khoản đăng ký | Gửi form đăng nhập | JWT được cấp; chuyển hướng tới khu vực đã xác thực | TODO | TODO / Not executed |
| TC-04 | Endpoint được bảo vệ bằng JWT | JWT hợp lệ từ TC-03 | Gọi API route được bảo vệ kèm JWT | Phản hồi 200 với dữ liệu mong đợi | TODO | TODO / Not executed |
| TC-05 | Hồ sơ người dùng | Đã đăng nhập | Xem/cập nhật hồ sơ | Dữ liệu hồ sơ được lưu đúng | TODO | TODO / Not executed |
| TC-06 | Danh mục bài tập | Đã đăng nhập | Duyệt danh mục bài tập | Danh sách load được từ `fitness-service` | TODO | TODO / Not executed |
| TC-07 | Lịch tập | Đã đăng nhập | Tạo/xem lịch tập | Lịch tập được lưu và hiển thị đúng | TODO | TODO / Not executed |
| TC-08 | Log tập luyện | Đã đăng nhập | Ghi log một buổi tập đã hoàn thành | Bản ghi được lưu và hiển thị trong lịch sử | TODO | TODO / Not executed |
| TC-09 | Tính bền vững dữ liệu trên RDS | Dữ liệu đã tạo ở TC-02–TC-08 | Restart container ứng dụng | Dữ liệu vẫn còn sau khi restart (chứng minh dữ liệu nằm ở RDS, không phải bộ nhớ container) | TODO | TODO / Not executed |
| TC-10 | Redis/cache | `ai-service`/`fitness-service` đang chạy | Kích hoạt một job hàng đợi (ví dụ ingest knowledge hoặc request bị rate-limit) | Queue/rate-limit dựa trên Redis hoạt động đúng như mong đợi | TODO | TODO / Not executed |
| TC-11 | Upload S3 | Chỉ áp dụng nếu S3 thực sự được triển khai | N/A | N/A | N/A | **N/A — S3 đang ở trạng thái Planned, chưa Implemented (xem [5.10](../5.10-S3-Storage/))** |
| TC-12 | Request không được xác thực | Không có | Gọi endpoint được bảo vệ mà không có token | 401 Unauthorized | TODO | TODO / Not executed |
| TC-13 | Token không hợp lệ | Không có | Gọi endpoint được bảo vệ với JWT sai định dạng/hết hạn | Bị từ chối 401/403 | TODO | TODO / Not executed |
| TC-14 | Lỗi database | RDS tạm thời không truy cập được (ví dụ gỡ rule Security Group trong test có kiểm soát) | Gọi endpoint cần database | Phản hồi lỗi rõ ràng, không crash/treo | TODO | TODO / Not executed |
| TC-15 | Container restart | Stack đang chạy | `docker compose restart <service>` | Service phục hồi và tham gia lại stack | TODO | TODO / Not executed |
| TC-16 | Log CloudWatch | CloudWatch Agent đã cấu hình | Kích hoạt hoạt động của ứng dụng | Log tương ứng xuất hiện trong CloudWatch Logs | TODO | TODO / Not executed |
| TC-17 | Alarm CloudWatch | Alarm đã cấu hình | Kích hoạt điều kiện alarm (hoặc dùng `set-alarm-state`) | Alarm chuyển sang trạng thái `ALARM` | TODO | TODO / Not executed |
| TC-18 | Email SNS | Subscription SNS đã xác nhận | Kích hoạt TC-17 | Email được nhận tại địa chỉ đã đăng ký | TODO | TODO / Not executed |

### Cách cập nhật bảng này

Với mỗi test thực sự được thực hiện: đổi cột Trạng thái thành `PASS` hoặc `FAIL`, và thêm link/đường dẫn tới bằng chứng (screenshot, trích đoạn log, hoặc output lệnh lưu trong `static/images/workshop/testing/`). Không bao giờ đổi Trạng thái thành `PASS` mà không có mục Bằng chứng tương ứng.
