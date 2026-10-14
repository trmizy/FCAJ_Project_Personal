---
title: "5.5.5 Trạng thái kiểm thử và việc còn mở"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.5.5. </b> "
---

#### Trạng thái ở checkpoint gần nhất

| Thành phần | AWS deployment | Migration | Kiểm thử end-to-end | Trạng thái |
|---|---|---|---|---|
| Hạ tầng dùng chung (VPC, subnet, SG, NAT, IGW) | Complete | — | — | **Complete** |
| Aurora PostgreSQL | Complete | 7/7 database đã restore | Verified | **Complete** |
| Auth Service | Deployed | Complete | Passed (kèm fix transaction-atomicity) | **Complete** |
| User Service | Deployed | Complete | Passed | **Complete** |
| Fitness Service | Deployed | Complete | Đang chờ | Cần xác nhận |
| Gym Service | Deployed | Complete | Đang chờ | Cần xác nhận |
| Payment Service | Deployed | Complete | Đang chờ | Cần xác nhận |
| AI / Worker / Jobs | Deployed | Complete | Đang chờ | Cần xác nhận |
| Chat Service (REST + Socket.IO) | Deployed | Complete | Đang chờ | Cần xác nhận |
| Frontend (S3) | Deployed | — | Chờ tích hợp đầy đủ | Cần xác nhận |
| CI/CD | Chưa xây dựng | — | — | **Incomplete** |

#### Kế hoạch hoàn tất các việc còn mở

| Việc | Bài kiểm tra cụ thể cần pass |
|---|---|
| E2E Fitness | Tạo kế hoạch tập, ghi một workout, xem thống kê; reminder xuất hiện trong log của jobs |
| E2E Gym | Xem danh sách gym/PT, tạo và quét một QR check-in, chủ phòng xem danh sách thành viên |
| E2E Payment | Cấu hình credential sandbox VNPAY, thanh toán một hợp đồng PT, nhận return/webhook, thấy job reconciliation xác nhận giao dịch |
| AI / Worker / Jobs | `POST /ai/ask` trả lời từ Nova Pro; một lần tạo kế hoạch hoàn tất qua SQS; job tri thức đầu tiên bootstrap các index OpenSearch 1024 chiều; auto-accept chạy |
| E2E Chat | Kiểm tra C6 và C8 ở [5.5.3](../5.5.3-Chat-Health-SocketIO/) |
| Tích hợp frontend | Mọi trang trong luồng người dùng và admin chạy được với backend trên AWS (kiểm tra T5–T7 ở [5.5.2](../5.5.2-Auth-Frontend-Smoke-Test/)) |
| Lỗi phát hiện khi E2E | Sửa, deploy lại và kiểm thử lại |
| CI/CD | Pipeline build artifact/image và deploy thay cho việc upload thủ công trên console |
| Kiểm soát chi phí | Chế độ "sleep" cho DEV: Aurora về 0 ACU khi idle, Chat service về 0 task ngoài giờ, NAT Gateway chỉ bật khi cần |
| Monitoring | CloudWatch alarm cho lỗi/throttle của Lambda, độ sâu DLQ, capacity của Aurora và health của Chat target, gửi thông báo qua e-mail |

#### Cố ý hoãn lại (không phải blocker cho DEV)

- Xoay vòng credential ADMIN.
- Xử lý nốt 12 seed account còn lại.
- HTTPS cho frontend và Chat ALB (cần domain và chứng chỉ ACM), với CloudFront + Origin Access Control đứng trước S3 bucket.
