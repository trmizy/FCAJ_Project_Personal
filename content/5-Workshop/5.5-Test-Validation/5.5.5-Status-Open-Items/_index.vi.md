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
| Frontend (S3 + CloudFront) | Deployed | — | Chờ tích hợp đầy đủ | Cần xác nhận |
| CI/CD — CI (validate PR) | Đã deploy, đang hoạt động | — | Thật (mỗi lần push) | **Complete** |
| CI/CD — CD (pipeline deploy) | Active, đã chạy thật | — | Thật (Lambda, ECS và hạ tầng đều đã thử) | **Complete** |

#### CI/CD — chính xác những gì đã thật hôm nay

| Phần | Trạng thái | Bằng chứng |
|---|---|---|
| `pr-validation.yml` (lint, typecheck, unit test, lint IaC, build Docker) | **Active**, chạy mỗi PR | Run GitHub Actions thật, xanh |
| `docker-test.yml` (fast Docker test + Critical DB Integration) | **Active**, chạy mỗi push | Run GitHub Actions thật, xanh |
| `dev-build.yml` (Gate 1 — build/hash zip Lambda, không đụng AWS) | **Active**, tự chạy khi push lên `aws-deploy` | Chạy tự động thật, skip đúng khi không service Lambda nào đổi |
| `dev-deploy.yml` (Gate 2 — deploy code Lambda thật) | **Active**, chạy tay, có cổng duyệt | **Đã thực thi thật**: 1 lần dry-run, rồi 1 lần deploy thật cho service `ai` (3 function cập nhật, smoke test qua) |
| `chat-deploy.yml` (Gate 3 — deploy image ECS Fargate) | **Active**, chạy tay, có cổng duyệt | **Đã chạy thật** từ 16/10/2026 — task definition hiện ở revision 9 |
| `infra-plan.yml` / `infra-deploy.yml` (Gate 4–5 — thay đổi CloudFormation API Gateway) | **Active**, chạy tay, có cổng duyệt | **Đã chạy thật**: một lệnh `execute-change-set` thật đã thành công và stack khớp với template |

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
| Tài khoản admin | **Xong 21/10/2026** (xem [5.4.13 Bước 12](../../5.4-Deployment-Guide/5.4.13-CD-Pipeline-Activation/)): đã có một đăng nhập ADMIN trên app đã deploy. Chủ sở hữu đổi mật khẩu tạm trong app sau lần đăng nhập đầu. |
| Kiểm soát chi phí | Chế độ "sleep" cho DEV: Aurora về 0 ACU khi idle, Chat service về 0 task ngoài giờ, NAT Gateway chỉ bật khi cần |
| Monitoring | CloudWatch alarm cho lỗi/throttle của Lambda, độ sâu DLQ, capacity của Aurora và health của Chat target, gửi thông báo qua e-mail |

#### Cố ý hoãn lại (không phải blocker cho DEV)

- Xử lý nốt 12 seed account còn lại.
- HTTPS riêng cho Chat ALB (cần domain và chứng chỉ ACM — bản thân ALB hiện vẫn chỉ có listener HTTP:80). **Frontend đã có HTTPS thật** qua CloudFront đứng trước S3 bucket, đã xác nhận đang sống; phần đó của mục này coi như xong, không còn hoãn.
