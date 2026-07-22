---
title: "Proposal"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

{{% notice warning %}}
Proposal này mô tả một kiến trúc **dự kiến (planned)**. Không nội dung nào bên dưới được xem là "đã triển khai" trừ khi mục [Workshop](../5-Workshop/) tương ứng có bằng chứng đã xác minh. Region, số liệu chi phí và ngày tháng đều là placeholder cho đến khi được xác nhận.
{{% /notice %}}

# Xây dựng và triển khai Trợ lý Thể hình AI trên AWS
## Triển khai ứng dụng mã nguồn mở Fitness Assistant trên hạ tầng AWS

### 1. Tên project

**Cloud-Native AI Fitness Assistant on AWS** — project thực tập nhằm thiết kế, đóng gói container và triển khai ứng dụng mã nguồn mở [Fitness Assistant](https://github.com/trmizy/fitness-assistant) trên AWS.

### 2. Executive Summary (Tóm tắt điều hành)

Fitness Assistant là một ứng dụng mã nguồn mở đã tồn tại và đang được phát triển tích cực: một pnpm monorepo gồm frontend React/Vite, một application gateway ở tầng ứng dụng, và nhiều microservice Node.js/TypeScript backend (xác thực, hồ sơ người dùng, dữ liệu thể hình/bài tập, và một service AI huấn luyện viên dựa trên LLM tự host). Hiện ứng dụng chạy hoàn toàn qua Docker Compose trên máy của developer. Mục tiêu của project này **không phải** là xây dựng ứng dụng mới, mà là lấy codebase hiện có, đã được xác minh, để thiết kế và triển khai một phiên bản cloud tối thiểu (MVP) trên AWS — bao gồm đóng gói container cho production, thiết kế mạng, database managed, lưu trữ image, compute, và giám sát — đồng thời nêu rõ những gì thuộc phạm vi MVP và những gì để lại cho tương lai.

### 3. Bối cảnh

Fitness Assistant đã có sẵn các chức năng đăng ký/đăng nhập, quản lý hồ sơ, danh mục bài tập, lịch tập, ghi log tập luyện, và tính năng hỗ trợ AI kết hợp một LLM tự host (Ollama, model mặc định `llama3.2:3b`) với pipeline Retrieval-Augmented Generation (RAG) dựa trên vector database Qdrant. Một tính năng riêng biệt — trích xuất chỉ số cơ thể từ ảnh InBody — gọi trực tiếp Anthropic Claude API để hiểu ảnh. Ở trạng thái hiện tại, ứng dụng được thiết kế cho phát triển local, chưa cho vận hành trên cloud: chưa có cấu hình AWS, Terraform, hay Kubernetes, chưa có bước deploy trong CI/CD, và 2 trong số 7 backend service (`gym-service`, `payment-service`) hiện chỉ có Dockerfile dạng development, chưa có bản build production.

### 4. Bài toán

Việc vận hành Fitness Assistant vượt ra ngoài laptop của một developer đòi hỏi giải quyết những vấn đề mà source code không tự giải quyết: database đặt ở đâu và được backup như thế nào, image container được build và phân phối ra sao, ứng dụng được truy cập qua internet như thế nào, secret được quản lý ra sao thay vì nằm trong file `.env` cục bộ, và làm sao biết khi có sự cố ở production. Nếu không thực hiện các bước này, ứng dụng chỉ có thể trình bày dưới dạng source code, không thể demo, chia sẻ hay đánh giá như một hệ thống đã triển khai thực tế.

### 5. Đối tượng sử dụng

- Người dùng cuối của ứng dụng Fitness Assistant (người theo dõi luyện tập, mục tiêu và nhận gợi ý huấn luyện từ AI).
- Mentor/người đánh giá FCAJ xem xét kết quả kỹ thuật của đợt thực tập này.
- Người đóng góp trong tương lai muốn mở rộng phần triển khai AWS (ví dụ: thêm Auto Scaling, CI/CD, hoặc Amazon Bedrock).

### 6. Mục tiêu tổng quát

Triển khai một phiên bản MVP hoạt động được của Fitness Assistant trên AWS, tái hiện các chức năng cốt lõi đã xác minh (xác thực, hồ sơ người dùng, bài tập/lịch tập, huấn luyện AI) trên hạ tầng AWS managed và self-managed, có giám sát, cảnh báo cơ bản và thực hành bảo mật được ghi lại đầy đủ — đồng thời ghi chép từng bước để có thể tái hiện và xem xét lại.

### 7. Mục tiêu cụ thể

1. Đóng gói container cho các service thuộc MVP bằng Dockerfile hướng production (multi-stage build, không chạy dev watcher, không nhúng secret vào image).
2. Thiết kế và khởi tạo VPC với public/private subnet và Security Group theo nguyên tắc least privilege.
3. Di chuyển database PostgreSQL từ container Docker sang Amazon RDS for PostgreSQL, áp dụng đúng migration Prisma của ứng dụng cho từng service.
4. Lưu trữ và quản lý phiên bản image container trên Amazon ECR.
5. Triển khai stack MVP trên Amazon EC2 với Docker Compose, phía sau một reverse proxy.
6. Thiết lập logging tập trung và cảnh báo với Amazon CloudWatch và Amazon SNS.
7. Áp dụng IAM least privilege và AWS Secrets Manager cho credential thay vì file `.env` dạng plaintext trên host.
8. Ghi chép, kiểm thử và dọn dẹp phần triển khai theo cách có thể tái hiện, dựa trên bằng chứng.

### 8. Phạm vi MVP

MVP bao gồm các service vừa cốt lõi với luồng sử dụng chính của ứng dụng, vừa đã có Dockerfile hướng production trong repository nguồn:

- **Frontend** (`frontend/web`, React + Vite, build và phục vụ qua Nginx).
- **Application Gateway** (`backend/gateway`) — một service Express/Node.js đóng vai trò reverse-proxy nội bộ của ứng dụng. Đây **không phải** dịch vụ Amazon API Gateway do AWS quản lý; xem ghi chú ở [Mục 12](#12-kiến-trúc-giải-pháp).
- **Auth Service** (`backend/services/auth-service`) — đăng ký, đăng nhập, cấp/xác thực JWT.
- **User Service** (`backend/services/user-service`) — hồ sơ và bản ghi InBody (bao gồm tính năng trích xuất bằng Anthropic Claude Vision).
- **Fitness Service** (`backend/services/fitness-service`) — bài tập, lịch tập, log tập luyện.
- **AI Service** (`backend/services/ai-service`) — chat/huấn luyện dựa trên Ollama và truy vấn RAG dựa trên Qdrant.
- **PostgreSQL** — di chuyển sang Amazon RDS (database-per-service, khớp với thiết kế schema Prisma hiện có của ứng dụng).
- **Redis** — giữ dưới dạng container trên EC2 cho MVP (BullMQ queue, rate limiting); Amazon ElastiCache được liệt kê ở phần tương lai, không thuộc MVP.
- **Qdrant** và **Ollama** — giữ dưới dạng container trên EC2 cho MVP; cả hai đều có yêu cầu CPU/RAM thực tế cần được ước lượng trung thực (xem [Mục 11](#11-non-functional-requirements)).

### 9. Thành phần không nằm trong MVP

- **Chat Service, Gym Service, Payment Service** — có trong repository nguồn, nhưng `gym-service` và `payment-service` hiện chưa có Dockerfile production, còn `chat-service` bổ sung độ phức tạp hạ tầng realtime (Socket.IO). Để lại cho phần Hướng phát triển.
- **Amazon S3 cho file upload** — ứng dụng hiện lưu file người dùng tải lên (ảnh InBody, ảnh hồ sơ, tài liệu đăng ký PT) trên local disk qua `multer`. Hiện chưa có S3 client trong source code. Việc tích hợp S3 đòi hỏi thay đổi code thực sự trong `user-service`, nằm ngoài phạm vi trừ khi được lập trình và xác minh. Đánh dấu **Planned**, không phải **Implemented**.
- **Amazon ElastiCache for Redis** — Optional; Redis chạy dưới dạng container cho MVP.
- **Amazon Bedrock** — lựa chọn thay thế/bổ sung tương lai cho Ollama tự host.
- **Amazon CloudFront, Route 53, Application Load Balancer, Auto Scaling** — Optional/Future, sau khi MVP một EC2 được xác nhận hoạt động ổn định.
- **CI/CD pipeline, Infrastructure as Code (Terraform/CDK)** — công việc tương lai; MVP được xây dựng thủ công và ghi chép từng bước cho mục đích học tập.

### 10. Functional Requirements (Yêu cầu chức năng)

| ID | Yêu cầu | Nguồn |
| --- | --- | --- |
| FR-1 | Người dùng đăng ký và đăng nhập | `auth-service` |
| FR-2 | Người dùng xem/cập nhật hồ sơ | `user-service` |
| FR-3 | Người dùng tải ảnh InBody và nhận chỉ số cơ thể đã trích xuất | `user-service` (qua Anthropic Claude Vision) |
| FR-4 | Người dùng xem danh mục bài tập và lịch tập | `fitness-service` |
| FR-5 | Người dùng ghi log buổi tập đã hoàn thành | `fitness-service` |
| FR-6 | Người dùng nhận gợi ý huấn luyện AI dựa trên kiến thức truy xuất (RAG) | `ai-service` (Ollama + Qdrant) |
| FR-7 | Toàn bộ traffic API được xác thực qua JWT, xác minh tập trung tại gateway | `backend/gateway` + `auth-service` |

### 11. Non-functional Requirements (Yêu cầu phi chức năng)

- **Availability (tính sẵn sàng):** MVP một EC2 không có redundancy tích hợp; ghi nhận đây là giới hạn đã biết của MVP, không khẳng định là highly available.
- **Bảo mật:** IAM least privilege, RDS private, không commit secret vào source hay nhúng vào image, hạn chế truy cập SSH.
- **Hiệu năng/Kích thước tài nguyên:** AI service phụ thuộc Ollama (LLM tự host) và Qdrant, thực tế cần nhiều CPU/RAM hơn instance `t3.micro` thuộc Free Tier. Cần đo đạc và kiểm chứng, không giả định.
- **Khả năng quan sát:** log và metric quan trọng phải được gửi tới CloudWatch, alarm được định tuyến qua SNS tới email.
- **Khả năng dự đoán chi phí:** tài nguyên phải được right-size và có thể dừng; không tài nguyên nào chạy mà không được giám sát về chi phí.
- **An toàn dữ liệu:** bật automated backup cho database; migration chạy qua công cụ Prisma của ứng dụng, không viết SQL thủ công.

### 12. Kiến trúc giải pháp

{{% notice warning %}}
`backend/gateway` là một service Node.js/Express **ở tầng ứng dụng** (router HTTP nội bộ và reverse proxy riêng) đi kèm trong source code Fitness Assistant. Đây **không phải** dịch vụ **Amazon API Gateway** do AWS quản lý. MVP này không sử dụng Amazon API Gateway; `backend/gateway` chạy như một container trên EC2, còn việc sử dụng Amazon API Gateway (nếu có) chỉ được liệt kê trong phần Hướng phát triển.
{{% /notice %}}

![Sơ đồ kiến trúc AWS của Fitness Assistant — TODO: thay bằng sơ đồ thật đã export](/images/workshop/architecture/fitness-assistant-aws-architecture.png)

File tải xuống: [fitness-assistant-aws-architecture.drawio](/files/architecture/fitness-assistant-aws-architecture.drawio) — TODO: file này hiện là placeholder; hãy thay bằng sơ đồ draw.io thật trước khi nộp báo cáo.

**Kiến trúc MVP hiện tại (dự kiến):**

```
Internet
   │
   ▼
EC2 (public subnet) — Nginx reverse proxy
   ├── Container Frontend (React build, phục vụ qua Nginx)
   └── Container Application Gateway (backend/gateway, Node.js/Express)
             │  (xác thực JWT qua HTTP call tới auth-service)
             ▼
   ┌─────────┴─────────┬─────────────┬─────────────┐
   ▼                    ▼             ▼             ▼
Auth Service      User Service   Fitness Service   AI Service
(container)       (container)    (container)       (Ollama + Qdrant,
                                                     container)
   │                    │             │                  │
   └────────────────────┴─────────────┴──────────────────┘
                         │
                         ▼
          Amazon RDS for PostgreSQL (private subnet)
                         │
                 Amazon CloudWatch  ──►  Amazon SNS ──► Email
```

Redis, Qdrant và Ollama chạy dưới dạng container cùng các container ứng dụng khác trên cùng một EC2 host cho MVP. Amazon ECR lưu toàn bộ image container; AWS Secrets Manager lưu credential database, JWT secret và `ANTHROPIC_API_KEY`; một IAM Role gắn với EC2 instance cấp quyền least-privilege tới ECR, CloudWatch và Secrets Manager.

### 13. Mô tả luồng dữ liệu

1. Request từ trình duyệt đến reverse proxy Nginx trên EC2.
2. Tài nguyên tĩnh của frontend được phục vụ trực tiếp; các API call được chuyển tiếp tới container `backend/gateway`.
3. Gateway trích xuất header `Authorization: Bearer <token>` và gọi endpoint `/auth/verify` của `auth-service` để xác thực, sau đó chuyển tiếp request xuống downstream kèm header `x-user-id`/`x-user-email`/`x-user-role`.
4. Service downstream (user/fitness/ai) xử lý request, đọc/ghi database logic riêng trên cùng instance Amazon RDS PostgreSQL thông qua Prisma.
5. `ai-service` truy vấn thêm Qdrant để lấy ngữ cảnh liên quan và gọi endpoint `/api/chat` của container Ollama để sinh phản hồi; `user-service` gọi Anthropic API bên ngoài để trích xuất ảnh InBody khi tính năng này được sử dụng.
6. Log ứng dụng và container được gửi tới Amazon CloudWatch Logs qua CloudWatch Agent; các metric quan trọng kích hoạt CloudWatch Alarm, publish tới Amazon SNS topic, gửi email cho người trực/người đánh giá.

### 14. Danh sách AWS services

| Service | Vai trò | Lý do lựa chọn | Trạng thái |
|---------|---------|----------------|------------|
| Amazon EC2 | Host stack Docker Compose cho MVP | Mô hình compute đơn giản nhất để học nền tảng triển khai container trước khi dùng ECS/EKS | Planned |
| Amazon ECR | Lưu trữ image container có phiên bản theo từng service | Tích hợp sẵn với IAM role của EC2; tránh giới hạn rate limit của Docker Hub | Planned |
| Amazon RDS for PostgreSQL | Database managed, thay thế container `postgres` của Docker | Automated backup, network private, khớp với thiết kế PostgreSQL/Prisma hiện có của ứng dụng | Planned |
| Amazon VPC | Cách ly mạng, public/private subnet | Nền tảng bắt buộc cho thiết kế mạng least-privilege | Planned |
| AWS IAM | Role/policy để EC2 truy cập ECR, CloudWatch, Secrets Manager | Tránh nhúng credential AWS tồn tại lâu dài trên host | Planned |
| AWS Secrets Manager | Lưu credential DB, JWT secret, `ANTHROPIC_API_KEY` | Tránh file `.env` dạng plaintext trên EC2 | Planned |
| Amazon CloudWatch | Log, metric, dashboard, alarm | Giám sát tập trung mà không cần thêm công cụ bên thứ ba | Planned |
| Amazon SNS | Cảnh báo qua email từ CloudWatch Alarm | Đường dẫn thông báo đơn giản, native cho MVP | Planned |
| Amazon S3 | Lưu trữ tương lai cho ảnh/tài liệu người dùng tải lên | Chưa được tích hợp trong source ứng dụng; cần thay đổi code | Planned |
| Amazon ElastiCache for Redis | Thay thế managed tương lai cho container Redis | Không bắt buộc cho MVP; container Redis đã đủ ở quy mô này | Optional |
| Amazon Bedrock | Lựa chọn managed thay thế/bổ sung tương lai cho Ollama tự host | Giúp loại bỏ nhu cầu chọn kích thước EC2 cho LLM nhúng kèm | Optional |
| Amazon CloudFront | CDN/edge caching tương lai cho frontend | Chưa cần thiết cho tới khi có traffic thực từ bên ngoài | Optional |
| Amazon Route 53 | Quản lý domain/DNS tùy chỉnh tương lai | Chưa đăng ký domain cho project này | Optional |
| Elastic Load Balancing | Load balancing tương lai khi có nhiều hơn một EC2 host | MVP một host chưa cần đến | Optional |
| AWS CDK / Terraform | Infrastructure as Code tương lai | MVP được xây thủ công trước cho mục đích học tập | Optional |

### 15. Lý do lựa chọn từng service (tóm tắt)

Mỗi service ở trạng thái "Planned" phía trên được chọn vì nó thay thế trực tiếp một khoảng trống cụ thể trong setup Docker Compose hiện tại (Postgres chỉ chạy container, secret nằm trong file `.env`, chưa có pipeline logging) chứ không phải vì đó là "stack AWS mặc định". Mỗi service "Optional" bị loại khỏi phạm vi MVP một cách có chủ đích vì ứng dụng hiện tại chưa thực sự cần — ví dụ S3 chỉ optional vì source code chưa có S3 client, không phải vì lưu trữ file không quan trọng.

### 16. Bảo mật

- IAM least privilege: instance role của EC2 chỉ giới hạn ở các action ECR/CloudWatch/Secrets Manager thực sự cần dùng.
- RDS không public; chỉ Security Group của ứng dụng mới được phép truy cập port 5432.
- Truy cập SSH (port 22) giới hạn ở một IP/CIDR cụ thể, không bao giờ dùng `0.0.0.0/0` trong thiết kế khuyến nghị.
- Secret (`JWT_SECRET`, credential trong `DATABASE_URL`, `ANTHROPIC_API_KEY`) lưu trong AWS Secrets Manager, không commit vào source hay nhúng vào Docker image.
- Các cơ chế bảo vệ sẵn có ở tầng ứng dụng được giữ nguyên, không bị làm yếu đi: xác thực dựa trên JWT, rate limiting phía gateway (`express-rate-limit`), băm mật khẩu bằng bcrypt.

### 17. Khả năng mở rộng

MVP cố tình chạy trên một EC2 duy nhất để giữ phạm vi học tập ở mức quản lý được. Kiến trúc được thiết kế sao cho nếu traffic tăng, ứng dụng (gateway) và các service stateless có thể chuyển sang Amazon ECS/Fargate phía sau Application Load Balancer với Auto Scaling, mà không cần thay đổi nền tảng RDS/Secrets Manager/ECR đã xây dựng.

### 18. Monitoring (Giám sát)

CloudWatch Logs (qua CloudWatch Agent) cho log container/ứng dụng, CloudWatch Metrics/Alarms cho CPU EC2, status check EC2, và CPU/connections/storage của RDS, kèm thông báo email qua SNS. Chi tiết đầy đủ ở [Workshop 5.12](../5-Workshop/5.12-Monitoring-Alerting/).

### 19. Backup và khôi phục

Amazon RDS automated backup với retention window xác định; snapshot thủ công trước bất kỳ thay đổi schema rủi ro nào. EBS volume trên EC2 không được xem là nơi lưu dữ liệu bền vững (trạng thái ứng dụng nằm ở RDS, không nằm trên host).

### 20. Timeline 12 tuần

| Tuần | Trọng tâm |
|------|-----------|
| 1 | Nghiên cứu, phân tích yêu cầu, chạy thử ứng dụng local |
| 2 | Phân tích source code và kiến trúc microservices |
| 3 | Dockerfile production và tối ưu image |
| 4 | Thiết kế kiến trúc AWS |
| 5 | Hạ tầng mạng (VPC, subnet, route, security group) |
| 6 | Amazon RDS for PostgreSQL |
| 7 | Amazon ECR và IAM Role |
| 8 | Triển khai Amazon EC2 |
| 9 | Reverse proxy, kết nối service, quyết định lưu trữ file |
| 10 | Giám sát với CloudWatch và SNS |
| 11 | Kiểm thử, bảo mật và rà soát chi phí |
| 12 | Clean-up và hoàn thiện báo cáo |

Xem chi tiết từng tuần tại [Worklog](../1-Worklog/).

### 21. Ước tính chi phí

{{% notice warning %}}
Giá AWS thay đổi theo Region và thời điểm. Cần kiểm tra [AWS Pricing Calculator](https://calculator.aws/) trước khi triển khai thực tế. Các số liệu dưới đây chỉ là placeholder phục vụ lập kế hoạch, không phải báo giá.
{{% /notice %}}

- **AWS Region (dự kiến):** `[TODO_AWS_REGION]`
- **Thành phần ước tính:** một EC2 instance được chọn kích thước phù hợp cho AI stack (xem ghi chú kích thước ở [Workshop 5.9](../5-Workshop/5.9-EC2-Deployment/)), một RDS PostgreSQL instance nhỏ, dung lượng ECR cho vài image, CloudWatch Logs/Alarms, thông báo email qua SNS.
- **TODO:** Bổ sung link ước tính thật từ AWS Pricing Calculator và số liệu hàng tháng sau khi chọn xong loại instance cuối cùng.
- Free Tier **không** chắc chắn bao phủ toàn bộ workload này — AI stack (Ollama + Qdrant) khó có thể chạy chấp nhận được trên loại instance thuộc Free Tier; cần kiểm chứng, không giả định.

### 22. Rủi ro

| Rủi ro | Khả năng | Ảnh hưởng | Biện pháp |
|--------|----------|-----------|-----------|
| EC2 instance không đủ tài nguyên cho Ollama/Qdrant | Cao | Cao | Chọn lại kích thước instance dựa trên tải đo được thực tế; ghi lại mức sử dụng CPU/RAM thực (Tuần 8/11) |
| Vô tình commit secret lên git | Trung bình | Cao | `.gitignore` cho `.env`/key, review trước khi commit, dùng Secrets Manager cho secret runtime |
| `gym-service`/`payment-service` thiếu Dockerfile production | Cao (đã biết trước) | Thấp (ngoài phạm vi MVP) | Ghi rõ để lại cho Hướng phát triển, không âm thầm bỏ qua |
| Vượt chi phí do quên tài nguyên đang chạy | Trung bình | Trung bình | Dừng/xóa tài nguyên khi không dùng; cảnh báo AWS Budgets (khuyến nghị, tùy chọn) |
| Không nhất quán khi migrate RDS (`user-service` không tự chạy `prisma migrate deploy`) | Trung bình | Trung bình | Chạy migration tường minh theo từng service; xác nhận trước khi tin tưởng auto-migration |
| Một EC2 duy nhất = điểm lỗi đơn (single point of failure) | Cao (theo thiết kế MVP) | Trung bình | Ghi nhận là giới hạn đã biết của MVP; Auto Scaling/ALB được liệt kê ở phần tương lai |

### 23. Tiêu chí đánh giá thành công

- Các service thuộc MVP ở [Mục 8](#8-phạm-vi-mvp) truy cập được đầu-cuối từ trình duyệt, dữ liệu lưu trên Amazon RDS.
- CloudWatch Alarm kích hoạt và thông báo qua SNS email ít nhất một lần trong quá trình kiểm thử (đã xác minh, không giả định).
- Không có secret nào xuất hiện trong Git repository hoặc trong image container.
- Mọi dịch vụ AWS được ghi là "Implemented" trong báo cáo này đều có bằng chứng tương ứng ở mục [Workshop](../5-Workshop/).

### 24. Deliverables (Sản phẩm bàn giao)

- Báo cáo song ngữ này (Worklog, Proposal, Blogs, Events, Workshop, Self-evaluation, Feedback).
- File Dockerfile production mẫu cho các service thuộc MVP.
- File `docker-compose.aws.example.yml` mô tả cấu trúc triển khai trên EC2.
- Sơ đồ kiến trúc (file draw.io nguồn + ảnh export) — TODO, chờ triển khai thực tế hoàn tất.
- Ví dụ IAM policy và Security Group với ARN/account ID dạng placeholder.

### 25. Hướng phát triển

- Amazon ECS/Fargate kèm Application Load Balancer và Auto Scaling.
- Amazon CloudFront + Route 53 cho domain tùy chỉnh và edge caching.
- Amazon Bedrock như lựa chọn managed thay thế/bổ sung cho Ollama tự host.
- Amazon S3 (kèm thay đổi code thực sự trong `user-service`) thay thế lưu trữ local disk.
- Amazon ElastiCache for Redis, thay thế container Redis.
- Pipeline CI/CD (GitHub Actions) build và deploy tự động mỗi lần merge.
- Infrastructure as Code (Terraform hoặc AWS CDK) thay vì thao tác thủ công trên console.
- Dockerfile production và triển khai cho `gym-service`, `payment-service`, và `chat-service`.

### 26. Tài liệu tham khảo

- Quy định project FCAJ: https://hcm-rules.awsfcaj.com/3-project/
- Template báo cáo: https://github.com/thienluhoan/fcj-workshop-template
- Source code ứng dụng: https://github.com/trmizy/fitness-assistant
