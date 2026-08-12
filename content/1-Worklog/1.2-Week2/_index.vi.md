---
title: "Worklog Tuần 2"
date: 2026-08-10
weight: 2
chapter: false
pre: " <b> 1.2. </b> "
---

### Mục tiêu tuần 2:

- Tìm hiểu repo Workshop mẫu để biết cách viết báo cáo đúng format.
- Tiếp tục học các bài lab AWS quan trọng: IAM Role, S3, Lightsail, Auto Scaling, CloudWatch, Route 53, AWS CLI.
- Bắt đầu phân tích source code project cá nhân để chuẩn bị thiết kế kiến trúc AWS.

### Các công việc cần triển khai trong tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Workshop / Tài liệu tham khảo |
|-----------|--------------|-----------------|-------------------------------|
| - Phân tích repo Workshop mẫu <br/> - Học các bài lab về IAM Role, S3, CloudWatch, Auto Scaling <br/> - Đọc source code project để hiểu cấu trúc | 10-08-2026 | 15-08-2026 | 48: https://000048.awsstudygroup.com/ <br/> 57: https://000057.awsstudygroup.com/ <br/> 45: https://000045.awsstudygroup.com/ <br/> 06: https://000006.awsstudygroup.com/ <br/> 08: https://000008.awsstudygroup.com/ <br/> 10: https://000010.awsstudygroup.com/ <br/> 11: https://000011.awsstudygroup.com/ |
| - Lên văn phòng làm việc <br/> - Nghiên cứu bài blog về Docker và Amazon ECR | 12-08-2026 | 12-08-2026 | Blog: https://000067.awsstudygroup.com/ (Monolith to Microservices) <br/> hoặc https://000015.awsstudygroup.com/ (Deploy on Docker Container) |

### Kết quả đạt được tuần 2:

**Tổng quan:**

Tuần này có 2 mảng chính: một là học tiếp các bài lab AWS để nắm thêm các service quan trọng, hai là bắt đầu đọc hiểu source code project để sau này dễ thiết kế kiến trúc lên AWS. Ngoài ra mình cũng tìm hiểu repo workshop mẫu để biết cách viết báo cáo cho đúng format FCAJ yêu cầu.

**Kiến thức đã học:**

- **IAM Roles cho Application:** Tuần trước học IAM user thì tuần này học IAM Role - cách cho EC2 hoặc Lambda truy cập service khác (S3, RDS...) mà không cần hardcode access key. Best practice quan trọng để bảo mật.

- **Amazon S3:** Hiểu S3 là object storage, khác với block storage (EBS). Làm lab tạo bucket, upload file, config public access, versioning. S3 rẻ và tiện nhưng cần cẩn thận với permission.

- **Cost Optimization & Lightsail:** Học các cách tiết kiệm tiền khi dùng AWS (Reserved Instance, Spot Instance, S3 Intelligent-Tiering). Lightsail thì giống như VPS đơn giản hơn EC2, fix giá theo tháng, phù hợp cho app nhỏ.

- **Auto Scaling:** Cơ chế tự động tăng/giảm số lượng EC2 dựa trên load. Kết hợp với Load Balancer để đảm bảo app luôn available khi traffic tăng đột ngột. Khái niệm Launch Template và scaling policy.

- **Amazon CloudWatch:** Service giám sát metrics (CPU, memory, network) và tạo alarm. Quan trọng để biết khi nào app bị lỗi hoặc quá tải. Có thể gửi notification qua SNS.

- **Route 53:** Service DNS của AWS, tìm hiểu cách tạo hosted zone, record A, CNAME. Có tính năng Hybrid DNS với Route 53 Resolver để kết nối DNS on-premise với AWS.

- **AWS CLI:** Practice nhiều lệnh CLI để quản lý resource thay vì dùng Console. Nhanh hơn và có thể script automation. Học cách config credential, dùng --query để filter output JSON.

**Thực hành:**

- Phân tích repo workshop mẫu, hiểu cấu trúc folder: content/, static/, config.toml. Biết cách dùng Hugo để generate static site.
- Làm xong 7 bài lab từ 000048 đến 000011, practice với IAM Role, S3, Lightsail, Auto Scaling, CloudWatch, Route 53 và AWS CLI.
- Đọc source code project cá nhân (fitness-assistant hoặc project tương tự), note lại tech stack: frontend dùng gì (React/Vue?), backend (Node/Python?), database (PostgreSQL/MySQL?).
- List các service/port: frontend chạy port nào, backend API port nào, có microservices không hay monolith.
- Lên văn phòng làm việc vào thứ 3 ngày 12/8, làm quen môi trường và setup workspace.
- Đọc và nghiên cứu bài blog "Từ Development Container đến Production-ready Microservices với Docker và Amazon ECR" để chuẩn bị cho việc containerize project sau này. Bài này hay vì giải thích rõ flow từ dev local với Docker đến push image lên ECR và deploy production.

**Khó khăn gặp phải:**

1. **Route 53 domain cost:** Muốn practice Route 53 đầy đủ cần mua domain nhưng domain trên Route 53 hơi đắt ($.12+ cho .com). Thử dùng Freenom free domain nhưng không integrate tốt với Route 53.

2. **Auto Scaling policy confuse:** Có nhiều loại scaling policy: target tracking, step scaling, simple scaling. Chưa rõ khi nào dùng cái nào, config threshold ra sao cho hợp lý.

3. **CloudWatch custom metrics:** CloudWatch mặc định chỉ có basic metrics (CPU, network). Để monitor app-level metrics (request count, error rate) phải tự push custom metrics, hơi phức tạp.

4. **Source code không có .env.example:** Khi đọc source code project thì không có file `.env.example`, phải đọc code để đoán xem cần những biến môi trường gì. Mất thời gian và dễ nhầm.

5. **Phân biệt API routing vs API Gateway:** Trong code có Express router (routing nội bộ) nhưng AWS có service tên là API Gateway. Lúc đầu nhầm lẫn giữa 2 khái niệm này khi vẽ kiến trúc.

**Cách giải quyết:**

- **Route 53 domain:** Tạm thời practice với subdomain trên domain free hoặc dùng domain đã có sẵn. Phần DNS chủ yếu là hiểu concept hosted zone, record type, TTL.

- **Auto Scaling policy:** Đọc AWS docs và best practice. Với app web thông thường, dùng target tracking policy với CPU 70% là đơn giản và hiệu quả nhất. Step scaling dành cho pattern phức tạp hơn.

- **CloudWatch custom metrics:** Tìm hiểu cách dùng CloudWatch agent hoặc SDK để push metrics từ app. Nhưng cho giai đoạn MVP thì dùng basic metrics kết hợp với application logs cũng đủ.

- **Biến môi trường:** List tất cả biến env bằng cách grep trong code: `grep -r "process.env" .` hoặc `grep -r "os.getenv" .`. Tạo file note riêng để track.

- **API Gateway:** Ghi chú rõ: Express router = code logic route request trong app. API Gateway = AWS managed service làm API endpoint, authentication, rate limiting. Hai thứ khác nhau hoàn toàn.
