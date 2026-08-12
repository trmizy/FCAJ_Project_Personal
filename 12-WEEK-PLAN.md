# Kế hoạch 12 tuần — Cloud-Native AI Fitness Assistant on AWS (FCAJ Internship)

> File này là kế hoạch làm việc cá nhân, **không phải nội dung report** (không nằm trong `content/`, không được Hugo build). Dùng để theo dõi tiến độ thực tế; xoá hoặc để ngoài git trước khi nộp bài nếu không muốn kèm theo.
>
> Cấu trúc tuần bám theo đúng danh sách đã có sẵn ở `content/1-Worklog/_index.md` (Week 1 → Week 12), chỉ khai triển thành checklist hành động + gắn với thang điểm ở mục 4 của quy định (`hcm-rules.awsfcaj.com/3-project`).

## Điều kiện để nhận mộc thực tập (theo dõi xuyên suốt 12 tuần)

- [ ] Thời gian thực tập đủ tối thiểu 3 tháng
- [ ] Lên văn phòng đủ **10 buổi** — ghi lại ngày mỗi lần lên (gợi ý: rải đều ~1 buổi/tuần, dư ra 2 tuần buffer)
- [ ] Đăng đủ **3 bài blog** lên nhóm AWS Study Group — gợi ý mốc: cuối Tuần 4, cuối Tuần 8, cuối Tuần 12
- [ ] Hoàn thành Project cá nhân (Workshop mục 5, tự triển khai, không copy mẫu)
- [ ] Hoàn thành báo cáo đầy đủ song ngữ (EN/VI)

## Thang điểm cần nhắm tới (tổng 6.0)

| Mục | Điểm | Tuần liên quan chính |
|---|---|---|
| 4.1 Ý tưởng & mục tiêu | 1.0 | Tuần 1, 4 |
| 4.2 Kiến trúc & thiết kế | 2.0 | Tuần 4, 5, 6, 7 |
| 4.3 Triển khai & lab step-by-step | 2.0 | Tuần 5–10 |
| 4.4 Tài liệu & trình bày | 0.5 | Xuyên suốt, chốt ở Tuần 12 |
| 4.5 Đóng góp cá nhân | 0.5 | Tuần 11–12 (reflection) |

---

## Tuần 1 — Research, requirements, chạy thử app local
**Report tương ứng:** `1-Worklog/1.1-Week1`, `5.1-Overview`, `5.3-Prerequisites`

- [ ] Đọc kỹ quy định FCAJ (`hcm-rules.awsfcaj.com/3-project`) — đã xong, lưu bằng chứng (screenshot trang quy định)
- [ ] Clone `fitness-assistant`, đọc README, liệt kê services/ports/DB thật (không đoán theo microservices "kiểu chung")
- [ ] Chạy thử app local end-to-end, chụp ảnh + lưu terminal output
- [ ] Chốt scope MVP (service nào deploy lên AWS, service nào bỏ qua vì thiếu Dockerfile production)
- [ ] Điền ngày thật vào bảng Day-by-Day của Week 1 (thay `[TODO_DATE]`)

## Tuần 2 — Phân tích codebase & kiến trúc microservices
**Report tương ứng:** `1-Worklog/1.2-Week2`

- [ ] Vẽ sơ đồ luồng request giữa các service (frontend → gateway → service → DB)
- [ ] Xác định biến môi trường bắt buộc cho từng service (đối chiếu `.env.example` thật của source)
- [ ] Ghi chú các quirk kỹ thuật cần xử lý khi lên AWS (vd: service không tự chạy migration)
- [ ] Cập nhật Evidence còn thiếu của Week 2

## Tuần 3 — Production Dockerfile & tối ưu image
**Report tương ứng:** `1-Worklog/1.3-Week3`, `5.5-Production-Containers`

- [ ] Viết/hoàn thiện Dockerfile production (multi-stage) cho từng service trong scope
- [ ] Kiểm tra chạy bằng non-root user, thêm HEALTHCHECK
- [ ] Đo kích thước image, chạy image scan cơ bản (vd `docker scout` / `trivy`)
- [ ] Build + chạy thử bằng `docker-compose` local, chụp ảnh container healthy

## Tuần 4 — Thiết kế kiến trúc AWS (chốt Proposal)
**Report tương ứng:** `1-Worklog/1.4-Week4`, `2-Proposal`, `5.2-Architecture`
**Blog #1 nộp cuối tuần này**

- [ ] Chốt danh sách service AWS sẽ dùng (≥3, hiện đã có EC2/RDS/ECR/S3/IAM/CloudWatch) + lý do chọn từng service
- [ ] Vẽ sơ đồ kiến trúc thật bằng draw.io, export PNG, thay 2 file placeholder
- [ ] Điền AWS Region thật vào Proposal + Prerequisites
- [ ] Viết/hoàn thiện Blog 1 (containerization/ECR), đăng lên AWS Study Group, điền URL + ngày thật

## Tuần 5 — Network Infrastructure (VPC, Subnet, Security Group)
**Report tương ứng:** `1-Worklog/1.5-Week5`, `5.6-Network-Infrastructure`

- [ ] Tạo VPC, public/private subnet, route table, NAT (hoặc quyết định bỏ NAT để tiết kiệm chi phí — ghi rõ lý do)
- [ ] Tạo Security Group theo nguyên tắc least-privilege (chỉ mở port cần thiết)
- [ ] Chụp ảnh console xác nhận cấu hình network
- [ ] Cập nhật phần "Planned → Implemented" cho mục network trong Proposal

## Tuần 6 — Amazon RDS PostgreSQL
**Report tương ứng:** `1-Worklog/1.6-Week6`, `5.7-RDS-PostgreSQL`

- [ ] Tạo RDS PostgreSQL instance trong private subnet
- [ ] Chạy migration thật (Prisma), xử lý quirk `user-service` không tự migrate
- [ ] Test kết nối từ EC2/container tới RDS
- [ ] Chụp ảnh: RDS console, kết quả migration, kết nối thành công

## Tuần 7 — Amazon ECR & IAM Roles
**Report tương ứng:** `1-Worklog/1.7-Week7`, `5.8-ECR`, `5.11-IAM-Secrets`

- [ ] Tạo ECR repository, push image thật (gắn với evidence Tuần 3)
- [ ] Tạo IAM Role/Policy least-privilege cho EC2 (chỉ quyền pull ECR, đọc Secrets Manager cần thiết)
- [ ] Xác nhận không hard-code access key ở bất kỳ đâu (`git grep` kiểm tra)
- [ ] Chụp ảnh IAM policy JSON + ECR repository

## Tuần 8 — Amazon EC2 Deployment
**Report tương ứng:** `1-Worklog/1.8-Week8`, `5.9-EC2-Deployment`
**Blog #2 nộp cuối tuần này**

- [ ] Chọn instance type + EBS size thật (điền vào chỗ TODO), viết user-data script
- [ ] Deploy EC2, pull image từ ECR, chạy container thật
- [ ] Đo CPU/RAM usage thực tế, chụp ảnh instance running + app accessible
- [ ] Viết/hoàn thiện Blog 2 (RDS/migration hoặc EC2 deployment), đăng lên AWS Study Group

## Tuần 9 — Reverse proxy, service wiring, file storage (S3)
**Report tương ứng:** `1-Worklog/1.9-Week9`, `5.10-S3-Storage`

- [ ] Cấu hình reverse proxy/gateway nối các service trên EC2
- [ ] Cấu hình S3 bucket (nếu dùng cho upload/static asset), áp policy least-privilege
- [ ] Test toàn bộ luồng end-to-end qua domain/IP public
- [ ] Chụp ảnh S3 console + test upload/download thật

## Tuần 10 — CloudWatch & SNS Monitoring
**Report tương ứng:** `1-Worklog/1.10-Week10`, `5.12-Monitoring-Alerting`

- [ ] Bật CloudWatch log cho EC2/container, tạo dashboard cơ bản
- [ ] Tạo alarm (vd CPU cao, RDS storage thấp) + SNS topic báo qua email
- [ ] Test alarm thật (cố tình trigger), chụp ảnh email/alarm state
- [ ] Điền threshold thật thay cho TODO trong `5.12`

## Tuần 11 — Testing, Security review, Cost review
**Report tương ứng:** `1-Worklog/1.11-Week11`, `5.13-Testing-Validation`, `5.14-Security-Cost`
**Blog #3 nộp cuối tuần này (đủ điều kiện 3 blogs)**

- [ ] Chạy đủ 18 test case ở `5.13`, điền PASS/FAIL kèm log/ảnh thật
- [ ] Bật HTTPS/TLS (đang ghi rõ là chưa cấu hình) — làm và cập nhật `5.14`
- [ ] Rà chi phí thực tế trên Cost Explorer/Billing, so với ước tính ở Proposal
- [ ] Viết/hoàn thiện Blog 3, đăng lên AWS Study Group → đủ điều kiện "3 bài blog"
- [ ] Bắt đầu viết nháp Self-evaluation dựa trên bằng chứng thật đã có (không chờ đến tuần cuối mới viết)

## Tuần 12 — Clean-up, hoàn thiện report, self-evaluation & feedback
**Report tương ứng:** `1-Worklog/1.12-Week12`, `5.16-Cleanup`, `5.17-Conclusion`, `6-Self-evaluation`, `7-Feedback`

- [ ] Chạy Clean-up thật theo đúng 20 bước ở `5.16` (xoá EC2, RDS, ECR image không cần, S3, alarm...), xác nhận billing về 0
- [ ] Viết `5.17-Conclusion` thật (Kết quả, Khó khăn, Cách xử lý, Đóng góp cá nhân, Reflection)
- [ ] Điền 3 Event thật (`4-EventParticipated`) — tên/thời gian/địa điểm/vai trò/bài học + ảnh chứng minh
- [ ] Hoàn thiện Self-evaluation (8 tiêu chí, Tốt/Khá/Trung bình + nhận xét có dẫn chứng cụ thể)
- [ ] Hoàn thiện Feedback (cảm nhận, mức hài lòng, điểm cải thiện, có giới thiệu bạn bè)
- [ ] Rà lại toàn bộ Worklog 12 tuần: thay hết `[TODO_DATE]`, đính kèm evidence còn thiếu
- [ ] Chạy `hugo server -D` click qua từng trang, chạy `hugo --minify --printPathWarnings`
- [ ] Kiểm tra lại Pre-Submission Checklist trong `README.md`
- [ ] Xác nhận đủ điều kiện mộc thực tập (3 tháng, 10 buổi văn phòng, 3 blog) rồi mới nộp
