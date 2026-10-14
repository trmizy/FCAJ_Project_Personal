---
title: "5.4.10 Chat Service trên ECS Fargate"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 5.4.10. </b> "
---

Chat là service duy nhất không chạy trên Lambda: Socket.IO giữ kết nối mở suốt phiên chat, không phù hợp với model theo từng lần gọi của Lambda. Service chạy như một container trên ECS Fargate, phía sau Application Load Balancer riêng.

| Mục | Giá trị |
|---|---|
| Logical database | `fitness_assistant_chat` (3 Prisma migration) |
| Secret | `fitness-assistant/dev/chat-database` (migration), `fitness-assistant/dev/chat-database-url` (runtime), `fitness-assistant/dev/internal-service-secret` |
| Image | ECR `fitness-assistant-dev-chat:dev-20260922-1` |
| Runtime | Cluster `fitness-assistant-dev-cluster`, service `fitness-assistant-dev-chat-service`, task definition `fitness-assistant-dev-chat` — 0.5 vCPU / 1 GB, container port 3005 |
| Điểm vào | Socket.IO → ALB `fitness-assistant-dev-chat-alb` (HTTP 80); REST → API Gateway `ANY /chat/{proxy+}` → ALB |

```
Internet ─:80─► chat-alb-sg ─:3005─► chat-sg (Fargate task, private subnet) ─:5432─► aurora-sg
```

#### Phần A — Database

**Bước 1 — Database secret.** Secrets Manager → *Other type of secret* → **Plaintext**, dùng lại username/password/host/port của một database secret đang chạy tốt và chỉ đổi tên database:

```json
{
  "username": "<Aurora username>",
  "password": "<Aurora password>",
  "host": "fitness-assistant-dev-aurora.cluster-<id>.ap-southeast-1.rds.amazonaws.com",
  "port": 5432,
  "database": "fitness_assistant_chat"
}
```

Tên `fitness-assistant/dev/chat-database`, mô tả "Chat Service Aurora PostgreSQL database – dev", key mặc định `aws/secretsmanager`, tắt rotation. Secret chỉ lưu thông tin kết nối — bản thân database do migration Lambda tạo.

![Danh sách secret trước khi thêm secret của Chat](/images/workshop/runbook/img236.jpg)

![Plaintext JSON với credential placeholder](/images/workshop/runbook/img237.jpg)

![Tên secret fitness-assistant/dev/chat-database](/images/workshop/runbook/img238.jpg)

![Để tắt rotation](/images/workshop/runbook/img239.jpg)

![Review và store](/images/workshop/runbook/img240.jpg)

**Bước 2 — Migration role.** `fitness-assistant-dev-chat-migrate-role` ("Execution role for Chat Service database migration Lambda") với `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole` và inline policy `fitness-assistant-dev-chat-migrate-secret` (`secretsmanager:GetSecretValue` chỉ trên `fitness-assistant/dev/chat-database*`). Không có quyền Bedrock, SQS, OpenSearch hay invoke — migration chỉ cần log, truy cập VPC và secret của nó.

![IAM → Roles → Create role](/images/workshop/runbook/img241.jpg)

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img242.jpg)

![Chọn AWSLambdaVPCAccessExecutionRole](/images/workshop/runbook/img243.jpg)

![Tên role fitness-assistant-dev-chat-migrate-role](/images/workshop/runbook/img244.jpg)

![Hai managed policy](/images/workshop/runbook/img245.jpg)

![Đã tạo role](/images/workshop/runbook/img246.jpg)

![Inline policy cho secret database của Chat](/images/workshop/runbook/img248.jpg)

![Tên policy fitness-assistant-dev-chat-migrate-secret](/images/workshop/runbook/img250.jpg)

![Role với ba permission entry](/images/workshop/runbook/img251.jpg)

**Bước 3 — Migration Lambda.** Ở thời điểm này account đã chạy 15 function:

![Danh sách Lambda function (15 function) trước khi tạo Chat migration Lambda](/images/workshop/runbook/img252.jpg)

Tạo `fitness-assistant-dev-chat-migrate` (Node.js 22.x, x86_64, role ở trên), upload `backend/services/chat-service/artifacts/chat-migrate-lambda.zip`, handler `dist/migrate-lambda.handler`, 1024 MB, 1 phút, `DATABASE_SECRET_ID=fitness-assistant/dev/chat-database`, hai private app subnet + Lambda SG.

![Create function fitness-assistant-dev-chat-migrate](/images/workshop/runbook/img253.jpg)

![Custom execution role](/images/workshop/runbook/img254.jpg)

![Handler dist/migrate-lambda.handler](/images/workshop/runbook/img255.jpg)

![Memory 1024 MB, timeout 1 phút](/images/workshop/runbook/img256.jpg)

![Chưa có environment variable](/images/workshop/runbook/img257.jpg)

![DATABASE_SECRET_ID cho database Chat](/images/workshop/runbook/img258.jpg)

![Chưa cấu hình VPC](/images/workshop/runbook/img259.jpg)

![Gắn hai private app subnet và Lambda SG](/images/workshop/runbook/img260.jpg)

**Bước 4 — Chạy migration.** Test event `chat-migrate` với `{}`. Mong đợi: `status: ok`, `database: fitness_assistant_chat`, `databaseCreated: true` (false nếu đã có từ trước), `migrateExitCode: 0`, 3 migration được áp dụng. Nếu lỗi, ghi lại lỗi thay vì chạy lại liên tục.

![Test event chat-migrate](/images/workshop/runbook/img261.jpg)

![Kết quả: status ok, đã tạo database, áp dụng 3 migration](/images/workshop/runbook/img262.jpg)

#### Phần B — Container image

**Bước 5 — ECR repository.** ECR → *Create repository*: private, tên `fitness-assistant-dev-chat`, tag mutability **Mutable** (tag được dùng lại trong DEV; production nên dùng tag theo commit như `git-a84f23c`), mã hoá AES-256, bật scan on push nếu có.

![Các private repository có sẵn (từ giai đoạn container trước)](/images/workshop/runbook/img263.jpg)

![Create repository fitness-assistant-dev-chat](/images/workshop/runbook/img264.jpg)

**Bước 6 — Push image** từ PowerShell trên máy. Chỉ build khi chưa có image:

```powershell
docker images gymini-chat-service
# chỉ khi chưa có:
docker build --platform linux/amd64 -t gymini-chat-service:aws-local -f backend/services/chat-service/Dockerfile .

aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag gymini-chat-service:aws-local <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
```

Phải thấy `Login Succeeded` trước khi tag; nếu gặp `'aws' is not recognized`, `Unable to locate credentials` hay `AccessDeniedException` thì dừng lại sửa cấu hình CLI trước.

![Image local gymini-chat-service:aws-local (146 MB nén)](/images/workshop/runbook/img265.jpg)

![docker login vào ECR: Login Succeeded](/images/workshop/runbook/img266.jpg)

![Tag image theo ECR URI](/images/workshop/runbook/img267.jpg)

![docker push: mọi layer đã được push](/images/workshop/runbook/img268.jpg)

![Image tag dev-20260922-1 trong repository](/images/workshop/runbook/img269.jpg)

#### Phần C — Log và IAM

**Bước 7 — Log group.** CloudWatch → *Create log group* `/ecs/fitness-assistant-dev-chat` (quy ước của ECS, không phải `/aws/lambda/...`), retention 30 ngày.

![Tạo log group /ecs/fitness-assistant-dev-chat, retention 1 tháng](/images/workshop/runbook/img270.jpg)

![Danh sách log group](/images/workshop/runbook/img271.jpg)

**Bước 8 — Task execution role** (do chính ECS dùng để pull image, ghi log và inject secret — không phải ứng dụng dùng). Trusted entity **Elastic Container Service → Elastic Container Service Task**, managed policy `AmazonECSTaskExecutionRolePolicy`, tên `fitness-assistant-dev-chat-execution-role`, cộng inline policy `fitness-assistant-dev-chat-execution-secrets` cho phép `secretsmanager:GetSecretValue` trên các secret của Chat.

![Danh sách IAM role](/images/workshop/runbook/img272.jpg)

![Use case: Elastic Container Service Task](/images/workshop/runbook/img273.jpg)

![AmazonECSTaskExecutionRolePolicy](/images/workshop/runbook/img274.jpg)

![Tên role fitness-assistant-dev-chat-execution-role, trust ecs-tasks.amazonaws.com](/images/workshop/runbook/img275.jpg)

![Tóm tắt permission](/images/workshop/runbook/img276.jpg)

![Đã tạo role — thêm inline policy](/images/workshop/runbook/img277.jpg)

![Inline policy cho các secret của Chat](/images/workshop/runbook/img278.jpg)

![Execution role với cả hai policy](/images/workshop/runbook/img279.jpg)

**Bước 9 — Task role** (code Chat dùng lúc runtime). Cùng trusted entity, không gắn managed policy, tên `fitness-assistant-dev-chat-task-role`, inline policy `fitness-assistant-dev-chat-service-invoke` cho phép `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-auth` và `fitness-assistant-dev-user`. Không có quyền Secrets Manager ở đây — secret được inject bởi execution role.

![Đã tạo task role fitness-assistant-dev-chat-task-role](/images/workshop/runbook/img280.jpg)

![Inline policy: invoke Auth và User Lambda](/images/workshop/runbook/img281.jpg)

![Tên policy fitness-assistant-dev-chat-service-invoke](/images/workshop/runbook/img282.jpg)

#### Phần D — Network

**Bước 10 — Security group cho task.** EC2 → Security Groups → *Create*: `fitness-assistant-dev-chat-sg` ("Security group for Chat Service Fargate tasks"), chưa có inbound rule, outbound mặc định (task gọi Auth/User Lambda, Aurora và DNS).

![Các security group trước khi có nhóm của Chat](/images/workshop/runbook/img283.jpg)

![Tạo fitness-assistant-dev-chat-sg không có inbound rule](/images/workshop/runbook/img284.jpg)

**Bước 11 — Cho task truy cập Aurora.** RDS → `fitness-assistant-dev-aurora` → *Connectivity & security* → mở security group của Aurora → *Edit inbound rules* → PostgreSQL 5432 từ **security group** `fitness-assistant-dev-chat-sg` ("Allow Chat Fargate tasks to Aurora"). Không bao giờ dùng `0.0.0.0/0` cho 5432.

![Connectivity & security của Aurora](/images/workshop/runbook/img285.jpg)

![Inbound rule của security group Aurora](/images/workshop/runbook/img286.jpg)

![Thêm 5432 từ Chat security group](/images/workshop/runbook/img287.jpg)

**Bước 12 — ECS cluster.** ECS → Clusters → *Create cluster*: `fitness-assistant-dev-cluster`, infrastructure **Fargate only**, không có EC2 capacity, không dùng Service Connect.

![Chưa có cluster](/images/workshop/runbook/img288.jpg)

![Tạo cluster fitness-assistant-dev-cluster, Fargate only](/images/workshop/runbook/img289.jpg)

![Cluster đang active](/images/workshop/runbook/img290.jpg)

#### Phần E — Secret runtime và task definition

**Bước 13 — Secret runtime.** Code Chat đọc `CHAT_DATABASE_URL`, không phải `DATABASE_URL`. Tạo `fitness-assistant/dev/chat-database-url` chứa `postgresql://USERNAME:PASSWORD@<aurora-endpoint>:5432/fitness_assistant_chat?schema=public` (URL-encode ký tự đặc biệt trong mật khẩu, ví dụ `@` → `%40`), lưu dưới JSON key `CHAT_DATABASE_URL`. Dùng lại internal secret dùng chung dưới tên `fitness-assistant/dev/internal-service-secret` (cùng giá trị Lambda đang dùng, không tạo giá trị mới). Mở rộng policy của execution role cho cả hai secret.

![Danh sách secret](/images/workshop/runbook/img291.jpg)

![Tên secret fitness-assistant/dev/chat-database-url](/images/workshop/runbook/img292.jpg)

![Policy của execution role được mở rộng cho secret mới](/images/workshop/runbook/img293.jpg)

**Bước 14 — Task definition.** ECS → Task definitions → *Create new task definition*:

| Thiết lập | Giá trị |
|---|---|
| Family | `fitness-assistant-dev-chat` |
| Launch type / OS | AWS Fargate, Linux/X86_64, network mode `awsvpc` |
| Task size | 0.5 vCPU, 1 GB |
| Task role / execution role | `fitness-assistant-dev-chat-task-role` / `fitness-assistant-dev-chat-execution-role` |
| Container | `chat-service`, essential, image `…/fitness-assistant-dev-chat:dev-20260922-1` |
| Port mapping | 3005/TCP, app protocol HTTP, tên `chat-http` |
| Environment | `NODE_ENV=production`, `CHAT_SERVICE_PORT=3005`, `CORS_ORIGIN=<S3 website URL>`, `ENABLE_REST_CORS=true`, `AUTH_LAMBDA_NAME`, `USER_LAMBDA_NAME` |
| Secret (**ValueFrom**) | `CHAT_DATABASE_URL` ← `<ARN secret chat-database-url>:CHAT_DATABASE_URL::`; `INTERNAL_API_SECRET` (alias `INTERNAL_SERVICE_SECRET`) ← internal-service-secret |
| Logging | `awslogs`, group `/ecs/fitness-assistant-dev-chat`, region `ap-southeast-1`, stream prefix `chat` |
| Health check | không đặt trong task; ALB kiểm tra `/health` (image có thể không có curl/wget) |

![Chưa có task definition](/images/workshop/runbook/img294.jpg)

![Family, Fargate, 0.5 vCPU / 1 GB, task role và execution role](/images/workshop/runbook/img295.jpg)

![Container chat-service, image dev-20260922-1, port 3005](/images/workshop/runbook/img296.jpg)

![Environment của revision 1 — hai secret bị nhập với kiểu "Value" (lỗi được sửa ở revision 3)](/images/workshop/runbook/img297.jpg)

![Thu thập log vào /ecs/fitness-assistant-dev-chat](/images/workshop/runbook/img298.jpg)

![Ephemeral storage và tag (Project, Environment, Service)](/images/workshop/runbook/img299.jpg)

{{% notice warning %}}
**Bài học rút ra.** Ở revision 1, các mục secret bị nhập với value type *Value*, nên container nhận được **tên** secret thay vì chuỗi kết nối và Prisma báo lỗi `URL must start with postgresql://`. Cách sửa là tạo revision mới có secret dùng **ValueFrom** với ARN đầy đủ của secret cộng hậu tố JSON key (`…:CHAT_DATABASE_URL::`), rồi **Update service → revision 3 → Force new deployment**. Không bao giờ dán giá trị thật vào environment variable thường.
{{% /notice %}}

#### Phần F — Load balancer

**Bước 15 — Security group cho ALB.** `fitness-assistant-dev-chat-alb-sg` ("ALB security group for Fitness Assistant Chat dev"): inbound HTTP 80 từ `0.0.0.0/0` (bản thân frontend vẫn là HTTP; HTTPS 443 sẽ có khi có domain và chứng chỉ ACM).

![Các security group sau khi tạo chat-sg](/images/workshop/runbook/img300.jpg)

![Tạo fitness-assistant-dev-chat-alb-sg: HTTP 80 từ mọi nơi](/images/workshop/runbook/img301.jpg)

![Đã tạo ALB security group](/images/workshop/runbook/img302.jpg)

**Bước 16 — Chỉ ALB được vào task.** Trong `fitness-assistant-dev-chat-sg`, thêm Custom TCP **3005** với source = security group `fitness-assistant-dev-chat-alb-sg` ("Allow Chat ALB to reach ECS task"). Port 3005 không bao giờ mở cho `0.0.0.0/0`.

![Inbound rule 3005 từ ALB security group](/images/workshop/runbook/img303.jpg)

![chat-sg giờ có một inbound rule](/images/workshop/runbook/img304.jpg)

**Bước 17 — Public subnet thứ hai.** ALB internet-facing cần hai Availability Zone, nên `fitness-assistant-dev-public-b` (10.0.2.0/24, `ap-southeast-1b`) được thêm — xem [5.4.1, bước 6](../5.4.1-Shared-Network/#second-public-subnet).

**Bước 18 — Target group.** EC2 → Target groups → *Create*: target type **IP addresses** (Fargate dùng `awsvpc`, nên không chọn *Instances*), tên `fitness-assistant-dev-chat-tg`, HTTP 3005, IPv4, HTTP1; health check `/health`, healthy 2, unhealthy 3, timeout 5 giây, interval 20 giây, success code 200. Không đăng ký target nào — ECS service tự đăng ký IP của task. Sau đó đặt deregistration delay 30 giây và **stickiness** (cookie do load balancer tạo, 1 ngày), phù hợp với chế độ polling fallback của Socket.IO.

![Target groups](/images/workshop/runbook/img308.jpg)

![Target type IP, HTTP 3005](/images/workshop/runbook/img309.jpg)

![Health check /health, ngưỡng 2/3, timeout 5 giây, interval 20 giây](/images/workshop/runbook/img310.jpg)

![Không đăng ký target thủ công](/images/workshop/runbook/img311.jpg)

![Review: fitness-assistant-dev-chat-tg](/images/workshop/runbook/img312.jpg)

![Stickiness bằng cookie của load balancer trong 1 ngày](/images/workshop/runbook/img313.jpg)

**Bước 19 — Application Load Balancer.** `fitness-assistant-dev-chat-alb`, internet-facing, IPv4, subnet `public-a` và `public-b`, chỉ dùng security group `fitness-assistant-dev-chat-alb-sg`, listener HTTP:80 → forward tới `fitness-assistant-dev-chat-tg`. Ghi lại DNS name `fitness-assistant-dev-chat-alb-<id>.ap-southeast-1.elb.amazonaws.com`.

![Load balancers](/images/workshop/runbook/img314.jpg)

![Chọn Application Load Balancer](/images/workshop/runbook/img315.jpg)

![Internet-facing, IPv4, public-a và public-b](/images/workshop/runbook/img316.jpg)

![Listener HTTP:80 forward tới Chat target group](/images/workshop/runbook/img317.jpg)

![Chi tiết ALB và DNS name](/images/workshop/runbook/img318.jpg)

**Bước 20 — Idle timeout 120 giây.** ALB → *Attributes* → đổi idle timeout từ 60 lên **120 giây**, phù hợp hơn với kết nối WebSocket kéo dài.

![Idle timeout đặt 2 phút](/images/workshop/runbook/img319.jpg)

**Bước 21 — Ẩn path nội bộ.** Default action của listener forward mọi path, kể cả `/internal/*` và `/metrics`. Thêm hai rule cho *HTTP:80*: priority 1, path `/internal/*` → fixed response 404 `text/plain` "Not Found"; priority 2, path `/metrics` → tương tự. `/health`, `/chat/*` và `/socket.io/*` vẫn tới container.

![Rule: path /internal/* trả 404 cố định](/images/workshop/runbook/img320.jpg)

![Rule priority 1 đứng trên default rule](/images/workshop/runbook/img321.jpg)

#### Phần G — Service

**Bước 22 — ECS service.** Cluster → *Services → Create*:

| Thiết lập | Giá trị |
|---|---|
| Compute | Launch type **FARGATE**, platform `LATEST` |
| Task definition | `fitness-assistant-dev-chat` (revision mới nhất) |
| Tên service | `fitness-assistant-dev-chat-service`, replica, **1 desired task** |
| Networking | chỉ `private-app-a` + `private-app-b`, security group `fitness-assistant-dev-chat-sg`, **tắt public IP** |
| Load balancing | ALB có sẵn `fitness-assistant-dev-chat-alb`, container `chat-service 3005:3005`, listener HTTP:80 có sẵn, target group có sẵn `fitness-assistant-dev-chat-tg` |
| Health check grace period | 60 giây |
| Service Connect / discovery / auto scaling | tắt |

Desired count giữ **1**: trạng thái phiên Socket.IO nằm trong memory, nên task thứ hai sẽ chia tách phiên cho tới khi có adapter dùng chung (ví dụ Redis).

![Trang cluster: đã tạo task definition fitness-assistant-dev-chat:1](/images/workshop/runbook/img322.jpg)

![Launch type Fargate, platform LATEST](/images/workshop/runbook/img323.jpg)

![Service fitness-assistant-dev-chat-service từ task definition family](/images/workshop/runbook/img324.jpg)

![Replica scheduling, 1 desired task](/images/workshop/runbook/img325.jpg)

![Private app subnet, chat-sg, tắt public IP](/images/workshop/runbook/img326.jpg)

![ALB có sẵn và container chat-service 3005:3005](/images/workshop/runbook/img327.jpg)

![Listener có sẵn (kèm rule /internal và /metrics) và target group](/images/workshop/runbook/img328.jpg)

![Thiết lập cuối cùng của service](/images/workshop/runbook/img329.jpg)

Ngay sau khi tạo, service hiện *Running 0 / Pending 1* trong lúc pull image, inject secret và tạo ENI. Nếu task bị dừng, đọc *Stopped reason* và *Events* của service thay vì tạo lại service.

**Bước 23 — Kiểm tra.** Service chạy 1/1 task và target group báo một private IP **Healthy** ở port 3005.

![Service active: 1/1 task chạy, deployment completed](/images/workshop/runbook/img330.jpg)

![Target 10.0.11.164:3005 healthy](/images/workshop/runbook/img331.jpg)

Sau đó thử `http://<alb-dns>/health`, và handshake Socket.IO `http://<alb-dns>/socket.io/?EIO=4&transport=polling`, phải trả về `0{"sid":"…","upgrades":["websocket"],…}` — không phải 404, 502 hay 503. Xem [5.5.3](../../5.5-Test-Validation/5.5.3-Chat-Health-SocketIO/).

#### Phần H — Nối vào API và frontend

**Bước 24 — REST qua API Gateway.** Trong `fitness-assistant-dev-api`, tạo route `ANY /chat/{proxy+}` với integration **HTTP URI**: method `ANY`, URL `http://<alb-dns>/chat/{proxy}`. Phần `{proxy}` rất quan trọng — `/chat/conversations` phải tới backend đúng là `/chat/conversations`. Kiểm tra bằng `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/chat/conversations` (cần Bearer token để có dữ liệu thật).

![HTTP URI integration cho ANY /chat/{proxy+} trỏ tới ALB](/images/workshop/runbook/img333.jpg)

**Bước 25 — Frontend.** Đặt URL Socket.IO (`VITE_CHAT_WS_URL`) trỏ tới ALB, build và publish lại theo [quy trình deploy lại](../5.4.3-Frontend-S3/#redeploy):

```
REST:      Frontend → API Gateway → /chat/{proxy+} → Chat ALB → ECS
Socket.IO: Frontend → Chat ALB → /socket.io/ → ECS
```

**Bước 26 — Rollout task definition đã sửa.** ECS → `fitness-assistant-dev-cluster` → `fitness-assistant-dev-chat-service` → *Update* → task definition `fitness-assistant-dev-chat:3`, giữ nguyên mọi thứ khác, *Force new deployment*. Trạng thái cần đạt: 1 running, 0 pending, deployment *Completed*, và không còn `URL must start with postgresql://` trong `/ecs/fitness-assistant-dev-chat`.
