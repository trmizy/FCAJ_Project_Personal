---
title: "Tuần 9"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 1.9. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Cấu hình reverse proxy trên EC2 phía trước frontend và container application gateway.
- Xác nhận frontend, application gateway và các microservice backend đã được kết nối đúng đầu-cuối trên AWS.
- Đánh giá luồng upload file/ảnh (`multer`, lưu local disk) và ghi lại quyết định lưu trữ cho MVP.

### Công việc đã thực hiện

- Cài đặt và cấu hình Nginx trên EC2 làm reverse proxy phía trước container frontend (đã có Nginx nội bộ riêng theo `frontend/web/Dockerfile` của project) và container application gateway (`backend/gateway`, port 3000).
- Xác nhận `VITE_API_URL` (cùng các biến build-time liên quan `VITE_SOCKET_URL`, `VITE_CHAT_WS_URL`) được thiết lập đúng khi build image, vì frontend nhúng cứng URL backend vào lúc build thay vì đọc lúc runtime.
- Xác nhận luồng request: trình duyệt → reverse proxy trên EC2 → container application gateway → các service downstream (auth/user/fitness/ai) → RDS.
- Xem xét code upload hiện có của ứng dụng (`multer`, lưu vào thư mục `uploads/` local) và xác nhận **hiện source code chưa tích hợp Amazon S3**. Ghi nhận Amazon S3 ở trạng thái **Planned** thay vì đã triển khai, vì việc tích hợp S3 đòi hỏi thay đổi code thực sự trong `user-service`, nằm ngoài phạm vi trừ khi được lập trình và kiểm thử.

### Kết quả đạt được

- Đã xác nhận luồng request đầu-cuối từ trình duyệt tới database qua các container đã triển khai.
- Đã ghi lại quyết định rõ ràng, có căn cứ về lưu trữ file: tạm thời lưu trên local disk của EC2, Amazon S3 được ghi nhận là công việc tương lai.

### Khó khăn

- Vì `VITE_API_URL` được nhúng cứng vào image frontend lúc build, việc thay đổi URL backend sau này đòi hỏi build lại và push lại image frontend thay vì chỉ đổi biến môi trường lúc runtime.

### Cách giải quyết

- Ghi chú rõ ràng sự ràng buộc build-time này để các lần triển khai lại sang domain/IP khác sau này không bị nhầm là chỉ cần đổi cấu hình đơn giản.

### Kỹ năng / Dịch vụ AWS đã học

- Cấu hình reverse proxy trên EC2.
- Tầm quan trọng của việc xác minh "tính năng này đã thực sự được lập trình chưa" trước khi viết hạ tầng cho một tính năng (Amazon S3, trong trường hợp này) mà ứng dụng chưa thực sự gọi tới.

### Bằng chứng cần bổ sung

- TODO: Screenshot cấu hình reverse proxy Nginx.
- TODO: Screenshot/video frontend gọi thành công tới backend qua stack đã triển khai.
- TODO: Ghi chú xác nhận quyết định lưu trữ cuối cùng cho file upload người dùng.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Cài và cấu hình reverse proxy Nginx | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 2 | Xác nhận cấu hình API URL build-time của frontend | [TODO_DATE] | [TODO_DATE] | `frontend/web/Dockerfile` |
| 3 | Xác nhận luồng request đầu-cuối | [TODO_DATE] | [TODO_DATE] | — |
| 4 | Ghi lại quyết định lưu trữ file (local disk hay S3) | [TODO_DATE] | [TODO_DATE] | [Workshop 5.10](../../5-Workshop/5.10-S3-Storage/) |

### Checklist hoàn thành

- [ ] Đã cấu hình reverse proxy trên EC2
- [ ] Frontend kết nối đúng tới application gateway và các service downstream
- [ ] Đã ghi lại quyết định lưu trữ file (S3 đánh dấu Planned, không phải Implemented)

### Liên kết Workshop tương ứng

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/)
- [5.10 S3 Storage](../../5-Workshop/5.10-S3-Storage/)
