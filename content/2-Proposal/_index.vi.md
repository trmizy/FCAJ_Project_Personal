---
title: "Proposal"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 2. </b> "
---

# Gymini — Trợ lý thể hình AI trên AWS
## Triển khai kiến trúc microservices serverless với AI managed trên Amazon Bedrock

### 1. Tóm tắt dự án {#summary}

Gymini (dự án open-source Fitness Assistant) là một pnpm monorepo gồm frontend React/Vite và bảy service Node.js/TypeScript — Auth, User, Fitness, Gym, Payment, AI và Chat — trước đây chỉ chạy trên máy của developer bằng Docker Compose. Dự án thực tập này thiết kế và triển khai ứng dụng lên AWS dưới dạng môi trường DEV theo hướng serverless tại region Asia Pacific (Singapore), được ghi lại từng bước để có thể review, làm lại và sau này tự động hoá.

Mỗi service chạy trên dịch vụ AWS phù hợp với đặc điểm của nó: sáu service request/response chạy trên AWS Lambda phía sau Amazon API Gateway, service Chat real-time chạy trên Amazon ECS Fargate phía sau Application Load Balancer, một cluster Amazon Aurora PostgreSQL Serverless v2 với một logical database cho mỗi service, Amazon Bedrock (Nova Pro, Cohere Embed) và Amazon OpenSearch Serverless cho AI coach, cùng Amazon SQS và EventBridge Scheduler cho các tác vụ nền. Frontend tĩnh được phục vụ từ Amazon S3; credential nằm trong AWS Secrets Manager; mỗi function có IAM role least-privilege riêng và chạy trong private subnet.

Ở checkpoint gần nhất, mọi service đã được deploy, 7 database local đã được restore vào Aurora với toàn bộ 23 foreign key đã audit được xác nhận, và Auth cùng User đã pass kiểm thử end-to-end. Phần việc còn lại — E2E cho các service khác, CI/CD, alarm, HTTPS và chế độ "sleep" tự động để tiết kiệm chi phí — đã được lên kế hoạch và theo dõi trong [Workshop](../5-Workshop/5.5-Test-Validation/5.5.5-Status-Open-Items/).

### 2. Phát biểu vấn đề {#problem}

#### Vấn đề hiện tại

- **Chỉ chạy được ở local.** Toàn bộ stack (PostgreSQL, Redis, Qdrant, model Ollama self-host và bảy service) chạy bằng Docker Compose trên một laptop: không có endpoint công khai, không backup, không cô lập giữa các thành phần.
- **Secret nằm trong file `.env`.** Mật khẩu database, JWT secret, secret service-to-service và key của payment provider đều là plaintext trên ổ đĩa.
- **AI self-host nặng.** AI coach cần LLM và vector database chạy local trên một máy bật liên tục; lần thử sizing EC2 trước đó cho thấy instance free tier không chạy nổi.
- **Tác vụ nền gắn với process.** Reminder, settlement và reconciliation chạy bằng timer trong process, thứ không tồn tại trên compute serverless.
- **Chat real-time.** Socket.IO cần kết nối sống lâu dài mà nền tảng request/response không giữ được.

#### Giải pháp đề xuất

Chuyển từng phần lên dịch vụ managed phù hợp, điều chỉnh code khi cần:

- Service request/response → AWS Lambda với handler HTTP API (payload 2.0), handler jobs riêng và handler migration đọc `DATABASE_SECRET_ID`; lời gọi nội bộ chuyển thành direct Lambda invoke thay vì HTTP qua application gateway.
- Chat real-time → ECS Fargate phía sau ALB, REST đi qua API Gateway.
- PostgreSQL → Aurora Serverless v2, mỗi service một logical database, dữ liệu restore từ dump local.
- AI → Amazon Bedrock cho chat, vision và embedding; OpenSearch Serverless cho vector; các generation dài được đưa vào hàng đợi SQS và xử lý bởi worker.
- Timer → các schedule EventBridge Scheduler gọi function jobs.
- Frontend → S3 static website (CloudFront và HTTPS là bước tiếp theo).

#### Lợi ích

Môi trường DEV chủ yếu trả tiền theo mức sử dụng, không có server nào phải vá cho sáu trong bảy service, AI coach không còn cần host model, network mặc định là private và quyền là least-privilege, và toàn bộ quá trình triển khai được ghi thành runbook có thể làm lại bằng tay hoặc chuyển thành pipeline.

### 3. Kiến trúc giải pháp {#architecture}

Sơ đồ thể hiện các thành phần đã deploy và luồng request giữa chúng. Mô tả đầy đủ — luồng request, lựa chọn dịch vụ, bảo mật, khả năng mở rộng và chi phí — nằm ở [Workshop 5.2](../5-Workshop/5.2-Architecture-Description/).

{{< mermaid >}}
graph LR
    User[Browser]

    subgraph Edge ["Public AWS endpoints"]
        FE["Amazon S3<br/>static website"]
        GW["API Gateway<br/>HTTP API"]
    end

    subgraph VPC ["VPC fitness-assistant-dev-vpc, ap-southeast-1"]
        subgraph Public ["Public subnets"]
            ALB["Chat ALB<br/>HTTP 80"]
            NAT["NAT Gateway"]
        end
        subgraph Private ["Private app subnets"]
            L["Lambda HTTP functions<br/>Auth, User, Fitness, Gym, Payment, AI"]
            J["Lambda jobs functions"]
            W["Lambda AI Worker"]
            C["ECS Fargate<br/>Chat Service, port 3005"]
            VPCE["Interface VPC endpoints<br/>Secrets Manager, OpenSearch"]
        end
        subgraph DB ["Private DB subnets"]
            A[("Aurora PostgreSQL Serverless v2<br/>7 logical databases")]
        end
    end

    SQS[["Amazon SQS<br/>ai-tasks + DLQ"]]
    EB[["EventBridge Scheduler<br/>13 schedules"]]
    BR[["Amazon Bedrock<br/>Nova Pro, Cohere Embed"]]
    OS[("OpenSearch Serverless<br/>vector collection")]

    User --> FE
    User -->|REST with JWT| GW
    User -->|Socket.IO| ALB
    GW --> L
    GW -->|chat REST routes| ALB
    ALB --> C
    L --> A
    J --> A
    W --> A
    C --> A
    L -->|SendMessage| SQS
    SQS --> W
    EB --> J
    L --> NAT
    W --> NAT
    J --> NAT
    NAT --> BR
    L --> VPCE
    W --> VPCE
    J --> VPCE
    VPCE --> OS
{{< /mermaid >}}

- **Edge và frontend** — bản build React được phục vụ từ S3 website endpoint. API Gateway (HTTP API) là điểm vào REST duy nhất với các route prefix tường minh và throttling cho route AI; Socket.IO đi thẳng tới Chat ALB.
- **Xác thực** — Auth service phát hành JWT; mỗi service tự verify token (AI service bằng cách invoke Auth). Lời gọi service-to-service dùng direct Lambda invoke kèm internal secret dùng chung, và route `/internal/*` không bao giờ được public.
- **Ứng dụng** — 12 Lambda function (Node.js 22.x, 1024 MB) cho HTTP API, scheduled jobs của sáu service và AI worker, tất cả nằm trong hai private application subnet.
- **Real-time** — Chat service chạy một Fargate task (0.5 vCPU / 1 GB) trong private subnet phía sau ALB internet-facing, có stickiness và idle timeout 120 giây.
- **Xử lý bất đồng bộ** — SQS (kèm dead-letter queue) cấp việc cho AI worker; 13 schedule EventBridge Scheduler điều khiển settlement, reminder, payout, reconciliation và knowledge ingestion.
- **AI** — Bedrock Nova Pro qua APAC inference profile cho chat và vision, Cohere Embed Multilingual v3 cho embedding 1024 chiều, OpenSearch Serverless (0–2 OCU) làm vector store.
- **Dữ liệu** — Aurora PostgreSQL Serverless v2 với bảy logical database; S3 cho upload private, artifact deploy và dump migration; Secrets Manager cho credential.
- **Network và bảo mật** — VPC `10.0.0.0/16` với private app subnet và DB subnet, một NAT Gateway, interface endpoint cho Secrets Manager và OpenSearch, security group tham chiếu lẫn nhau, mỗi function hoặc task một IAM role.
- **Quan sát** — CloudWatch Logs cho mọi function và task; alarm đang được lên kế hoạch.

### 4. Dịch vụ AWS sử dụng {#services}

| Dịch vụ | Vai trò trong hệ thống |
|---|---|
| Amazon S3 | Host frontend tĩnh; upload private (presigned URL); artifact deploy Lambda; dump migration database |
| Amazon API Gateway (HTTP API) | Điểm vào REST công khai với route tường minh, CORS, throttling route AI và HTTP proxy tới Chat ALB |
| AWS Lambda | Các service Auth, User, Fitness, Gym, Payment và AI (function HTTP, jobs, worker) và migration schema của từng service |
| Amazon ECS trên AWS Fargate | Chat service (REST + Socket.IO) và task migrator database chạy một lần |
| Amazon ECR | Image container private cho Chat và migrator |
| Elastic Load Balancing (ALB) | Điểm vào Socket.IO/WebSocket cho Chat, health check `/health`, stickiness, rule ẩn các path nội bộ |
| Amazon Aurora PostgreSQL Serverless v2 | Dữ liệu quan hệ cho mọi service, mỗi service một logical database |
| Amazon Bedrock | Nova Pro cho chat và vision; Cohere Embed Multilingual v3 cho embedding |
| Amazon OpenSearch Serverless | Vector search cho RAG và truy xuất tri thức |
| Amazon SQS | Hàng đợi AI task và dead-letter queue |
| Amazon EventBridge Scheduler | Schedule cho settlement, reminder, payout, reconciliation và AI job |
| AWS Secrets Manager | Credential database, database URL của Chat và internal secret dùng chung |
| AWS IAM | Execution role cho từng function, task/execution role cho ECS, scheduler role |
| Amazon VPC | Cô lập network: subnet, route table, security group |
| NAT Gateway và Internet Gateway | Truy cập internet outbound cho private subnet |
| VPC interface endpoint | Truy cập private tới Secrets Manager và OpenSearch Serverless |
| Amazon CloudWatch Logs | Log cho mọi function, Chat task và migrator |
| AWS Marketplace | Subscription một lần cho model Cohere trên Bedrock |

### 5. Thiết kế thành phần {#components}

- **Frontend (React/Vite)** — S3 website; gọi REST tới API Gateway kèm Bearer token; Socket.IO tới Chat ALB; xử lý thông báo cho người dùng khi route AI trả 429/408/504.
- **Auth service** — đăng ký, xác minh, đăng nhập, refresh, logout, quản trị người dùng; database `fitness_assistant`.
- **User service** — hồ sơ, onboarding, InBody, hồ sơ ứng tuyển PT, hợp đồng, buổi tập, lịch rảnh, thông báo; upload vào các prefix S3 private; jobs: session settlement, auto-confirm, reschedule expiry; database `fitness_assistant_user`.
- **Fitness service** — bài tập, workout, dinh dưỡng, thực phẩm, chu kỳ tập, dữ liệu coach, thiết bị, import/export, template, thống kê; jobs: nhắc workout sắp tới và workout chưa hoàn thành; database `fitness_assistant_fitness`.
- **Gym service** — phòng gym, danh sách PT, công cụ cho chủ phòng và admin, hợp tác, QR check-in có chữ ký; jobs: membership payout, referral settlement; database `fitness_assistant_gym`.
- **Payment service** — thanh toán, ví, ví PT, rút tiền, quản trị thanh toán, callback của provider (mặc định VNPAY; code hỗ trợ MoMo, PayOS, ZaloPay); job: reconciliation mỗi 5 phút; database `fitness_assistant_payment`.
- **AI service** — function HTTP (`/ai`, `/plans`, `/marketplace`, `/admin/ai`), SQS worker cho các generation dài, function jobs cho auto-accept và knowledge ingestion hằng đêm; Bedrock và OpenSearch; database `fitness_assistant_ai`.
- **Chat service** — hội thoại và nhắn tin real-time trên Fargate; database `fitness_assistant_chat`.
- **Migration** — mỗi service một migration function (Prisma `migrate deploy`) và một Fargate task đã restore dữ liệu local.
- **Aurora cluster** — `fitness-assistant-dev-aurora`, bảy logical database.
- **Vector collection** — `fitness-assistant-dev-ai-vectors` với các index `exercises`, `fitness_knowledge`, `fitness_faq` và `fitness_evidence` (1024 chiều, FAISS/HNSW, cosine similarity).

### 6. Triển khai kỹ thuật {#implementation}

#### Các giai đoạn triển khai

1. **Phân tích và điều chỉnh code** — audit từng service; thêm handler Lambda cho HTTP, jobs và migration; đọc credential qua `DATABASE_SECRET_ID`; thay lời gọi HTTP nội bộ bằng direct Lambda invoke; thêm provider SQS, Bedrock và OpenSearch; build artifact có kèm Prisma Linux engine.
2. **Nền tảng dùng chung** — VPC, subnet, security group, NAT và Internet Gateway, Aurora Serverless v2, Secrets Manager endpoint.
3. **Service đầu tiên và các điểm vào** — Auth Lambda, API Gateway với route tường minh, S3 website, CORS.
4. **Các service lõi** — User, Fitness, Gym và Payment cùng function jobs và schedule, sau đó nối Gym ↔ Payment.
5. **AI** — model Bedrock, SQS worker, function jobs, OpenSearch Serverless, schedule tri thức, route AI có throttling, kích hoạt Payment → AI.
6. **Real-time và dữ liệu** — Chat trên ECS Fargate phía sau ALB; restore 7 database local bằng Fargate migrator.
7. **Kiểm thử và hardening** — kiểm thử end-to-end, alarm, CI/CD, HTTPS với CloudFront, tự động hoá chế độ "sleep" tiết kiệm chi phí.

Các bước console chính xác của giai đoạn 2–6, kèm screenshot và IAM policy, nằm trong [Hướng dẫn triển khai](../5-Workshop/5.4-Deployment-Guide/).

#### Yêu cầu kỹ thuật

- **Compute** — Lambda Node.js 22.x trên x86_64 với 1024 MB; timeout 30 giây cho HTTP, 1 phút cho jobs, 300 giây cho AI worker, 600 giây cho AI jobs và tới 15 phút cho migration; Fargate task 0.5 vCPU / 1 GB.
- **API** — HTTP API với payload format 2.0; không có route `/internal/*`, `/metrics` hay catch-all; throttling 1 request/giây (burst 3) cho route AI.
- **Dữ liệu** — Prisma migration áp dụng theo từng service; mỗi service một logical database; SQS visibility timeout 600 giây, chuyển DLQ sau 2 lần nhận.
- **AI** — Bedrock tại `ap-southeast-1` qua APAC inference profile; embedding 1024 chiều; OpenSearch FAISS/HNSW với cosine similarity.
- **Bảo mật** — IAM least-privilege cho từng function; credential trong Secrets Manager; private subnet và rule security-group-tới-security-group; không có secret trong artifact, image hay tài liệu.
- **Vận hành** — CloudWatch Logs; mọi bước thủ công đều được ghi lại, sẽ được thay bằng CI/CD pipeline.

### 7. Lộ trình & cột mốc {#timeline}

Thời gian thực tập từ 3/8 đến 19/10/2026. Các mốc ngày bên dưới lấy theo ngày tạo resource trong runbook triển khai.

| Giai đoạn | Thời gian | Hoạt động chính |
|---|---|---|
| 1. Học và phân tích | Tháng 8/2026 (tuần 1–3) | Kiến thức nền AWS (các module FCJ), audit ứng dụng, chạy local, thiết kế triển khai |
| 2. Nền tảng và service đầu tiên | 26–27/8/2026 | VPC và NAT, Aurora, Auth Lambda, API Gateway, frontend S3; database và role của User |
| 3. Các service lõi | 2–8/9/2026 | Fitness (2/9), Gym và Payment (8/9) cùng jobs và schedule |
| 4. AI | 15/9/2026 | Bedrock, SQS worker, jobs, OpenSearch Serverless, schedule tri thức, route AI |
| 5. Chat và dữ liệu | 22–23/9/2026 | Chat trên ECS Fargate phía sau ALB; image migrator và restore 7 database |
| 6. Kiểm thử và báo cáo | Tháng 10/2026 (tuần 10–12) | Kiểm thử end-to-end và sửa lỗi, CI/CD, alarm, kiểm soát chi phí, báo cáo và dọn dẹp |

### 8. Ước tính ngân sách {#budget}

Ước tính theo tháng cho môi trường DEV tại `ap-southeast-1` chạy 24×7 với lưu lượng kiểm thử nhẹ. Các con số là giá on-demand niêm yết gần đúng và thay đổi theo thời gian — cần xác nhận lại bằng [AWS Pricing Calculator](https://calculator.aws/); hoá đơn thật trong Cost Explorer của account là số liệu tham chiếu.

| Nhóm chi phí | Cấu hình ước tính | Chi phí tháng (USD) |
|---|---|---|
| NAT Gateway | 1 gateway × 730 giờ, cộng dữ liệu xử lý | ~43 + dữ liệu |
| Aurora PostgreSQL Serverless v2 | Floor 0.5 ACU × 730 giờ (≈365 ACU-giờ), storage nhỏ | ~45–60 |
| ECS Fargate (Chat) | 0.5 vCPU + 1 GB × 730 giờ | ~22 |
| Application Load Balancer | 1 ALB × 730 giờ, LCU thấp | ~20 |
| Địa chỉ IPv4 public | Elastic IP của NAT + 2 địa chỉ của ALB × 730 giờ | ~11 |
| Interface VPC endpoint | Secrets Manager và OpenSearch, mỗi cái 2 AZ | ~30–40 |
| OpenSearch Serverless (NextGen) | 0–2 OCU, scale về 0 khi idle | tuỳ số giờ hoạt động |
| Amazon Bedrock | Nova Pro và Cohere Embed, tính theo token, lưu lượng kiểm thử | ~1–10 |
| AWS Lambda | ~40.000 lần gọi theo lịch + lưu lượng kiểm thử, 1 GB | ~0 (free tier) |
| API Gateway (HTTP API) | < 1 triệu request | ~0–1 |
| Secrets Manager | 9 secret | ~4 |
| S3, ECR, CloudWatch Logs, SQS, EventBridge | lưu lượng nhỏ | ~2–5 |

**Tổng ước tính:** khoảng **190–230 USD/tháng** nếu mọi thứ chạy 24×7. Với chế độ sleep đã lên kế hoạch — Aurora về 0 ACU, Chat service về 0 task và gỡ NAT Gateway ngoài các phiên kiểm thử — khoảng **60–90 USD/tháng**. Các khoản tính theo giờ cố định (NAT, ALB, Fargate, floor của Aurora, endpoint, IPv4) chiếm phần lớn; các dịch vụ tính theo mức dùng gần như không tốn gì ở lưu lượng DEV.

### 9. Đánh giá rủi ro {#risks}

| Rủi ro | Mức ảnh hưởng | Xác suất | Chiến lược giảm thiểu |
|---|---|---|---|
| Resource DEV idle vẫn tính tiền (NAT, floor Aurora, Fargate, ALB, endpoint) | Trung bình | Cao | Chế độ sleep, cảnh báo AWS Budgets, [quy trình dọn dẹp](../5-Workshop/5.7-Cleanup/) theo đúng thứ tự phụ thuộc |
| Chi phí Bedrock tăng vọt do client hoặc bug frontend | Trung bình | Trung bình | Throttling cho route AI, frontend xử lý 429, SQS dead-letter queue |
| Lộ secret qua screenshot, tài liệu hoặc cấu hình function | Cao | Thấp–Trung bình | Secrets Manager cho credential, che bằng chứng ở mức pixel, chuyển internal secret từ cấu hình Lambda sang Secrets Manager |
| Deploy thủ công bị lệch hoặc không lặp lại được | Trung bình | Cao | Runbook từng bước kèm screenshot; đã lên kế hoạch CI/CD |
| Migration dữ liệu ghi đè hoặc làm hỏng dữ liệu | Cao | Thấp | Preflight chỉ đọc, dump lưu trong bucket private có versioning, giữ nguyên lịch sử migration, xác nhận foreign key và row count |
| Chỉ một Chat task và endpoint chỉ có HTTP | Trung bình | Trung bình | Chấp nhận được cho DEV; adapter Socket.IO dùng chung trước khi scale; domain, chứng chỉ ACM và CloudFront cho HTTPS |

Chi phí và lỗi được xem lại trong Cost Explorer và CloudWatch Logs sau mỗi phiên kiểm thử cho tới khi có alarm.

Nếu có sự cố, frontend có thể rollback từ bản backup trên S3, Lambda có thể upload lại artifact trước đó, Fargate service có thể quay về task definition revision cũ, và database có thể dựng lại từ các dump migration.

### 10. Kết quả kỳ vọng {#outcomes}

**Kết quả trước mắt:** một môi trường DEV hoạt động trên AWS cho toàn bộ ứng dụng — frontend, sáu service Lambda, chat real-time, AI managed và dữ liệu đã restore — cùng hướng dẫn triển khai có thể làm lại và kết quả kiểm thử đã ghi nhận ([Workshop 5.5](../5-Workshop/5.5-Test-Validation/)).

**Kiến thức kỹ thuật:** kinh nghiệm thực tế với thiết kế serverless trên Lambda, API Gateway và EventBridge; container trên ECS Fargate và ECR; Aurora Serverless và migration dữ liệu; AI managed với Bedrock và OpenSearch Serverless; và các ranh giới network, IAM giữ cho toàn bộ hệ thống private và least-privilege.

**Dài hạn:** cùng thiết kế này có thể phát triển thành môi trường production bằng cách thêm CI/CD pipeline và infrastructure as code, HTTPS với CloudFront và WAF, CloudWatch alarm, auto scaling cho Chat với adapter Socket.IO dùng chung, và tách account DEV/production.
