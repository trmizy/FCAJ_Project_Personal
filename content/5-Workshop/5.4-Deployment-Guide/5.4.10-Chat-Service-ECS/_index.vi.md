---
title: "5.4.10 Chat Service trên ECS Fargate"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 5.4.10. </b> "
---

Chat là service duy nhất không chạy trên Lambda: Socket.IO giữ kết nối mở suốt phiên chat, không phù hợp với model theo từng lần gọi của Lambda. Service chạy như một container trên ECS Fargate, phía sau Application Load Balancer riêng.

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của bước nhỏ được viết ngay phía trên ảnh.

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

**Bước 1 — Database secret.** Dùng lại username/password/host/port của một database secret đang chạy tốt và chỉ đổi tên database. Secret chỉ lưu thông tin kết nối — bản thân database do migration Lambda tạo.

**1.1 — Mở Secrets Manager.** Danh sách hiện các secret có sẵn (AI, payment, gym, fitness, user, base). Bấm **Store a new secret**.

![Danh sách secret và nút Store a new secret](/images/workshop/runbook/img236.jpg)

**1.2 — Dán JSON.** Chọn **Other type of secret**, mở tab **Plaintext** và thay nội dung bằng JSON bên dưới (giá trị mẫu — dùng thông tin Aurora thật; giá trị mẫu trong ảnh viết bằng tiếng Việt).

```json
{
  "username": "<Aurora username>",
  "password": "<Aurora password>",
  "host": "fitness-assistant-dev-aurora.cluster-<id>.ap-southeast-1.rds.amazonaws.com",
  "port": 5432,
  "database": "fitness_assistant_chat"
}
```

![Other type of secret, tab Plaintext và JSON editor](/images/workshop/runbook/img237.jpg)

**1.3 — Đặt tên.** Tên `fitness-assistant/dev/chat-database`, mô tả "Chat Service Aurora PostgreSQL database – dev", rồi **Next**. Giữ khoá mặc định `aws/secretsmanager`.

![Tên secret, mô tả và Next](/images/workshop/runbook/img238.jpg)

**1.4 — Để rotation tắt.** Giữ **Automatic rotation** tắt và bấm **Next**.

![Công tắc Automatic rotation (tắt) và Next](/images/workshop/runbook/img239.jpg)

**1.5 — Lưu.** Xem lại phần tóm tắt và bấm **Store**.

![Trang review và nút Store](/images/workshop/runbook/img240.jpg)

**Bước 2 — Migration role.** `fitness-assistant-dev-chat-migrate-role` ("Execution role for Chat Service database migration Lambda") với `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole` và inline policy `fitness-assistant-dev-chat-migrate-secret` (`secretsmanager:GetSecretValue` chỉ trên `fitness-assistant/dev/chat-database*`). Không có quyền Bedrock, SQS, OpenSearch hay invoke — migration chỉ cần log, truy cập VPC và secret của nó.

**2.1 — Bắt đầu tạo role.** **IAM → Roles → Create role**.

![Danh sách role IAM và Create role](/images/workshop/runbook/img241.jpg)

**2.2 — Trusted entity.** **AWS service**, use case **Lambda**, **Next**.

![AWS service, use case Lambda và Next](/images/workshop/runbook/img242.jpg)

**2.3 — Chọn managed policy.** Tìm `AWSLambdaVPCAccessExecutionRole` và tick cùng với `AWSLambdaBasicExecutionRole` (đã chọn 2), rồi **Next**.

![Tìm AWSLambdaVPCAccessExecutionRole, dòng đã tick và Next](/images/workshop/runbook/img243.jpg)

**2.4 — Đặt tên role.** `fitness-assistant-dev-chat-migrate-role`, mô tả "Execution role for Chat Service database migration Lambda".

![Tên role và mô tả](/images/workshop/runbook/img244.jpg)

**2.5 — Tạo role.** Phần tóm tắt liệt kê hai managed policy; bấm **Create role**.

![Hai managed policy và Create role](/images/workshop/runbook/img245.jpg)

**2.6 — Thêm inline policy.** Trên role mới bấm **Add permissions → Create inline policy**.

![Role đã tạo và nút Add permissions](/images/workshop/runbook/img246.jpg)

**2.7 — Viết policy.** Chuyển sang **JSON** và cho phép `secretsmanager:GetSecretValue` trên `arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/chat-database*`.

![JSON editor với statement cho secret Chat](/images/workshop/runbook/img248.jpg)

**2.8 — Đặt tên và tạo.** `fitness-assistant-dev-chat-migrate-secret`, **Create policy**.

![Tên policy và Create policy](/images/workshop/runbook/img250.jpg)

**2.9 — Kiểm tra role.** Role giờ có ba mục permission.

![Role với inline policy fitness-assistant-dev-chat-migrate-secret](/images/workshop/runbook/img251.jpg)

**Bước 3 — Migration Lambda.** Lúc này tài khoản đã chạy 15 function.

**3.1 — Mở danh sách function.** **Lambda → Functions** hiện 15 function; bấm **Create function**.

![Functions (15) và Create function](/images/workshop/runbook/img252.jpg)

**3.2 — Điền thông tin function.** **Author from scratch**, tên `fitness-assistant-dev-chat-migrate`, runtime **Node.js 22.x** (x86_64), và trong panel custom execution role chọn `fitness-assistant-dev-chat-migrate-role`, **Save**.

![Author from scratch, tên, runtime và migrate role](/images/workshop/runbook/img253.jpg)

**3.3 — Tạo function.** Kiểm tra custom execution role là migrate role và bấm **Create function**.

![Link custom execution role và Create function](/images/workshop/runbook/img254.jpg)

**3.4 — Upload code.** **Upload from → .zip file** với `backend/services/chat-service/artifacts/chat-migrate-lambda.zip`, rồi **Update**.

*Runbook không có ảnh của lần upload này; hộp thoại giống [5.4.8 Bước 2.6](../5.4.8-AI-Service-Core/).*

**3.5 — Đặt handler.** **Code → Runtime settings → Edit**: `dist/migrate-lambda.handler`, **Save**.

![Handler dist/migrate-lambda.handler và Save](/images/workshop/runbook/img255.jpg)

**3.6 — Đặt memory và timeout.** **Memory** `1024` MB, **Timeout** `1` phút `0` giây, **Save**.

![Memory 1024 MB, timeout 1 phút, Save](/images/workshop/runbook/img256.jpg)

**3.7 — Mở environment variable.** Chưa có biến nào; bấm **Edit**.

![Environment variables (0) và nút Edit](/images/workshop/runbook/img257.jpg)

**3.8 — Thêm biến.** `DATABASE_SECRET_ID` = `fitness-assistant/dev/chat-database`, **Save**.

![DATABASE_SECRET_ID cho database Chat và Edit](/images/workshop/runbook/img258.jpg)

**3.9 — Mở cấu hình VPC.** Chưa cấu hình VPC; bấm **Edit**.

![No VPC configuration và nút Edit](/images/workshop/runbook/img259.jpg)

**3.10 — Gắn VPC.** VPC của dự án, cả hai private app subnet và Lambda SG, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img260.jpg)

**Bước 4 — Chạy migration.**

**4.1 — Tạo test event.** Ở tab **Test** chọn **Create new event**, đặt tên `chat-migrate`, giữ `{}` và bấm **Test**.

![Tên event chat-migrate và nút Test](/images/workshop/runbook/img261.jpg)

**4.2 — Đọc kết quả.** Mong đợi: `status: ok`, `database: fitness_assistant_chat`, `databaseCreated: true` (false nếu đã tồn tại), `migrateExitCode: 0`, 3 migration được áp dụng. Nếu lỗi, hãy ghi lại lỗi thay vì chạy lại liên tục.

![Executing function succeeded và response với 3 migration đã áp dụng](/images/workshop/runbook/img262.jpg)

#### Phần B — Container image

**Bước 5 — ECR repository.**

**5.1 — Mở ECR.** 8 private repository có sẵn từ giai đoạn container trước đó. Bấm **Create repository**.

![Private repositories (8) và Create repository](/images/workshop/runbook/img263.jpg)

**5.2 — Điền thông tin repository.** Private, tên `fitness-assistant-dev-chat`, tag mutability **Mutable** (tag được dùng lại trong DEV; production nên dùng tag theo commit như `git-a84f23c`), mã hoá AES-256, rồi **Create**. Tuỳ chọn scan on push hiện ở console này với nhãn "deprecated".

![Tên repository, Mutable và Create](/images/workshop/runbook/img264.jpg)

**Bước 6 — Push image** từ PowerShell trên máy làm việc. Chỉ build khi image chưa có:

```powershell
docker images gymini-chat-service
# chỉ khi chưa có:
docker build --platform linux/amd64 -t gymini-chat-service:aws-local -f backend/services/chat-service/Dockerfile .

aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag gymini-chat-service:aws-local <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
```

**6.1 — Kiểm tra image local.** Chạy `docker images gymini-chat-service`; phải thấy `gymini-chat-service:aws-local` (146 MB nén).

![Lệnh docker images và dòng image](/images/workshop/runbook/img265.jpg)

**6.2 — Đăng nhập ECR.** Chạy dòng `aws ecr get-login-password … | docker login …`. Phải thấy `Login Succeeded` trước khi tag; nếu gặp `'aws' is not recognized`, `Unable to locate credentials` hay `AccessDeniedException` thì dừng lại sửa cấu hình CLI trước.

![Lệnh đăng nhập và Login Succeeded](/images/workshop/runbook/img266.jpg)

**6.3 — Tag image.** Chạy `docker tag …` với ECR URI và tag `dev-20260922-1`.

![Lệnh docker tag](/images/workshop/runbook/img267.jpg)

**6.4 — Push.** Chạy `docker push …`; mọi layer phải báo `Pushed` và dòng cuối hiện digest.

![Lệnh docker push và dòng digest cuối](/images/workshop/runbook/img268.jpg)

**6.5 — Kiểm tra trong ECR.** Mở repository: tag `dev-20260922-1` hiện trong danh sách (image index cùng hai image của nó).

![Tag dev-20260922-1 trong repository](/images/workshop/runbook/img269.jpg)

#### Phần C — Log và IAM

**Bước 7 — Log group.**

**7.1 — Tạo log group.** **CloudWatch → Log groups → Create log group**: tên `/ecs/fitness-assistant-dev-chat` (quy ước của ECS, không phải `/aws/lambda/...`), retention **1 month (30 days)**, rồi **Create**.

![Tên log group, retention 1 tháng và Create](/images/workshop/runbook/img270.jpg)

**7.2 — Kiểm tra danh sách.** Lọc danh sách log group theo `/ecs/fitness-assistant-dev-chat`.

![Danh sách log group và ô lọc](/images/workshop/runbook/img271.jpg)

**Bước 8 — Task execution role** (do chính ECS dùng để kéo image, ghi log và inject secret — không phải ứng dụng).

**8.1 — Bắt đầu tạo role.** **IAM → Roles → Create role** (banner là xác nhận policy trước đó).

![Danh sách role IAM và Create role](/images/workshop/runbook/img272.jpg)

**8.2 — Trusted entity.** **AWS service**, service **Elastic Container Service**, use case **Elastic Container Service Task**.

![AWS service, Elastic Container Service và use case Task](/images/workshop/runbook/img273.jpg)

**8.3 — Managed policy.** Tìm `AmazonECSTaskExecutionRolePolicy`, tick và bấm **Next**.

![Tìm AmazonECSTaskExecutionRolePolicy, dòng đã tick và Next](/images/workshop/runbook/img274.jpg)

**8.4 — Đặt tên role.** `fitness-assistant-dev-chat-execution-role`, mô tả "ECS task execution role for Chat Service dev"; trust policy là `ecs-tasks.amazonaws.com`.

![Tên role và mô tả](/images/workshop/runbook/img275.jpg)

**8.5 — Tạo role.** Phần tóm tắt có một managed policy; bấm **Create role**.

![AmazonECSTaskExecutionRolePolicy và Create role](/images/workshop/runbook/img276.jpg)

**8.6 — Thêm inline policy.** Trên role vừa tạo mở **Add permissions → Create inline policy**.

![Menu Add permissions với Create inline policy](/images/workshop/runbook/img277.jpg)

**8.7 — Viết policy.** `secretsmanager:GetSecretValue` trên các secret của Chat (ban đầu chỉ `chat-database*`; được mở rộng ở Bước 13). Đặt tên `fitness-assistant-dev-chat-execution-secrets`.

![JSON editor với statement cho secret Chat và Next](/images/workshop/runbook/img278.jpg)

**8.8 — Kiểm tra role.** Role có managed policy cùng inline policy.

![Execution role với cả hai policy](/images/workshop/runbook/img279.jpg)

**Bước 9 — Task role** (thứ mà code Chat dùng lúc chạy). Cùng trusted entity (ECS Task), không có managed policy, tên `fitness-assistant-dev-chat-task-role`. Không có quyền Secrets Manager ở đây — secret do execution role inject.

**9.1 — Tạo role và mở Add permissions.** Role có 0 policy; bấm **Add permissions → Create inline policy**.

![Task role đã tạo và Add permissions](/images/workshop/runbook/img280.jpg)

**9.2 — Viết policy.** JSON: `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-auth` và `fitness-assistant-dev-user`, rồi **Next**.

![JSON editor: invoke Auth và User Lambda, Next](/images/workshop/runbook/img281.jpg)

**9.3 — Đặt tên và tạo.** `fitness-assistant-dev-chat-service-invoke`, **Create policy**.

![Tên policy và Create policy](/images/workshop/runbook/img282.jpg)

#### Phần D — Network

**Bước 10 — Security group cho task.**

**10.1 — Mở Security groups.** **EC2 → Security Groups** liệt kê năm group hiện có; bấm **Create security group**.

![Security group trước khi có group của Chat và Create security group](/images/workshop/runbook/img283.jpg)

**10.2 — Điền thông tin group.** Tên `fitness-assistant-dev-chat-sg`, mô tả "Security group for Chat Service Fargate tasks", VPC của dự án, **chưa có inbound rule**, outbound mặc định (task gọi Auth/User Lambda, Aurora và DNS). Bấm **Create security group**.

![Tên, mô tả, VPC, không có inbound rule và Create security group](/images/workshop/runbook/img284.jpg)

**Bước 11 — Cho task truy cập Aurora.** Không bao giờ mở 5432 cho `0.0.0.0/0`.

**11.1 — Mở security group của Aurora.** **RDS → `fitness-assistant-dev-aurora` → Connectivity & security**, rồi bấm link security group của Aurora trong **Security group rules**.

![Link security group Aurora trong Security group rules](/images/workshop/runbook/img285.jpg)

**11.2 — Sửa inbound rule.** Ở tab **Inbound rules** bấm **Edit inbound rules**.

![Inbound rules (2) và Edit inbound rules](/images/workshop/runbook/img286.jpg)

**11.3 — Thêm rule.** **Add rule**: PostgreSQL, TCP 5432, source = security group `fitness-assistant-dev-chat-sg`, mô tả "Allow Chat Fargate tasks to Aurora", rồi **Save rules**.

![Add rule, dòng PostgreSQL mới với Chat SG, Save rules](/images/workshop/runbook/img287.jpg)

**Bước 12 — ECS cluster.**

**12.1 — Bắt đầu tạo cluster.** **ECS → Clusters** chưa có cluster nào; bấm **Create cluster**.

![Clusters (0) và Create cluster](/images/workshop/runbook/img288.jpg)

**12.2 — Điền thông tin cluster.** Tên `fitness-assistant-dev-cluster`, infrastructure **Fargate only**, không EC2 capacity, không Service Connect, rồi **Create**.

![Tên cluster, Fargate only và Create](/images/workshop/runbook/img289.jpg)

**12.3 — Kiểm tra cluster.** Cluster xuất hiện trong danh sách.

![Cluster fitness-assistant-dev-cluster trong danh sách](/images/workshop/runbook/img290.jpg)

#### Phần E — Runtime secret và task definition

**Bước 13 — Runtime secret.** Code Chat đọc `CHAT_DATABASE_URL`, không phải `DATABASE_URL`.

**13.1 — Mở Secrets Manager.** Secret `chat-database` mới ở đầu danh sách. Bấm **Store a new secret** lần nữa.

![Danh sách secret với chat-database và Store a new secret](/images/workshop/runbook/img291.jpg)

**13.2 — Tạo secret URL.** **Other type of secret**, một dòng key/value với key `CHAT_DATABASE_URL` và value `postgresql://USERNAME:PASSWORD@<aurora-endpoint>:5432/fitness_assistant_chat?schema=public` (URL-encode ký tự đặc biệt trong mật khẩu, ví dụ `@` → `%40`). Tên `fitness-assistant/dev/chat-database-url`, mô tả "Chat Service PostgreSQL connection URL - dev", rồi **Next** và lưu.

![Tên secret, mô tả và Next](/images/workshop/runbook/img292.jpg)

**13.3 — Internal secret.** Dùng lại internal secret dùng chung với tên `fitness-assistant/dev/internal-service-secret` (cùng giá trị các Lambda đang dùng, không bao giờ tạo giá trị mới).

*Runbook không có ảnh của thao tác này.*

**13.4 — Mở rộng policy của execution role.** Trong `fitness-assistant-dev-chat-execution-secrets` liệt kê cả hai ARN (`chat-database*` và `chat-database-url*`; cùng secret internal) và bấm **Next**.

![Policy editor với hai ARN secret và Next](/images/workshop/runbook/img293.jpg)

**Bước 14 — Task definition.** **ECS → Task definitions → Create new task definition**:

| Cài đặt | Giá trị |
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

**14.1 — Mở trang.** Chưa có task definition nào; bấm **Create new task definition**.

![Task definitions (0) và Create new task definition](/images/workshop/runbook/img294.jpg)

**14.2 — Family, kích thước và role.** Family `fitness-assistant-dev-chat`, **AWS Fargate**, **Linux/X86_64**, **.5 vCPU**, **1 GB**, task role `fitness-assistant-dev-chat-task-role`, execution role `fitness-assistant-dev-chat-execution-role`.

![Family, Fargate, OS, CPU, memory, task role và execution role](/images/workshop/runbook/img295.jpg)

**14.3 — Container.** Tên `chat-service`, essential **Yes**, image URI `<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1`, container port `3005`, TCP, port name `chat-http`, app protocol HTTP.

![Tên container, image URI và port mapping 3005](/images/workshop/runbook/img296.jpg)

**14.4 — Environment (revision 1 — chứa lỗi).** Ảnh cho thấy lần thử đầu: hai dòng secret `CHAT_DATABASE_URL` và `INTERNAL_SERVICE_SECRET` bị gõ với value type **Value** và *tên* secret — xem cảnh báo bên dưới. Hãy dùng **ValueFrom** với ARN của secret.

![Environment revision 1: tám dòng, đều có value type Value](/images/workshop/runbook/img297.jpg)

**14.5 — Logging.** Tick **Use log collection**, destination **Amazon CloudWatch**, `awslogs-group` = `/ecs/fitness-assistant-dev-chat`, `awslogs-region` = `ap-southeast-1`, `awslogs-stream-prefix` = `chat`.

![Log collection tới /ecs/fitness-assistant-dev-chat](/images/workshop/runbook/img298.jpg)

**14.6 — Storage và tag.** Giữ ephemeral storage 20 GiB; thêm tag `Project=fitness-assistant`, `Environment=dev`, `Service=chat`; bấm **Create**.

![Ephemeral storage, ba tag và Create](/images/workshop/runbook/img299.jpg)

{{% notice warning %}}
**Bài học.** Ở revision 1, các dòng secret được gõ với value type *Value*, nên container nhận **tên** secret thay vì chuỗi kết nối và Prisma báo lỗi `URL must start with postgresql://`. Cách sửa là tạo revision mới với secret dùng **ValueFrom** kèm ARN đầy đủ cộng hậu tố khoá JSON (`…:CHAT_DATABASE_URL::`), rồi **Update service → revision 3 → Force new deployment**. Không bao giờ dán giá trị thật vào environment variable thường.
{{% /notice %}}

#### Phần F — Load balancer

**Bước 15 — Security group của ALB.** HTTP 80 từ `0.0.0.0/0` (bản thân frontend vẫn là HTTP; HTTPS 443 sẽ có khi có domain và chứng chỉ ACM).

**15.1 — Kiểm tra danh sách.** Banner xác nhận `chat-sg` đã tạo (6 group). Bấm **Create security group**.

![Banner chat-sg đã tạo và Create security group](/images/workshop/runbook/img300.jpg)

**15.2 — Điền thông tin group.** Tên `fitness-assistant-dev-chat-alb-sg`, mô tả "ALB security group for Fitness Assistant Chat dev", VPC của dự án; inbound rule **HTTP**, source **Anywhere-IPv4 0.0.0.0/0**; **Create security group**.

![Tên, mô tả, VPC, inbound HTTP từ anywhere và Create](/images/workshop/runbook/img301.jpg)

**15.3 — Kiểm tra.** Banner xác nhận đã tạo; group có một inbound entry (HTTP 80, 0.0.0.0/0).

![Security group của ALB đã tạo và inbound rule của nó](/images/workshop/runbook/img302.jpg)

**Bước 16 — Chỉ ALB mới được tới task.** Không bao giờ mở port 3005 cho `0.0.0.0/0`.

**16.1 — Sửa inbound rule của security group task.** Trong `fitness-assistant-dev-chat-sg` thêm **Custom TCP**, port `3005`, source = security group `fitness-assistant-dev-chat-alb-sg`, mô tả "Allow Chat ALB to reach ECS task", rồi **Save rules**.

![Custom TCP 3005 từ security group của ALB và Save rules](/images/workshop/runbook/img303.jpg)

**16.2 — Kiểm tra.** `chat-sg` giờ có một inbound rule: Custom TCP 3005 từ ALB SG.

![Inbound rule 3005 của chat-sg từ ALB SG](/images/workshop/runbook/img304.jpg)

**Bước 17 — Public subnet thứ hai.** ALB internet-facing cần hai Availability Zone, nên đã thêm `fitness-assistant-dev-public-b` (10.0.2.0/24, `ap-southeast-1b`) — xem [5.4.1, bước 6](../5.4.1-Shared-Network/#second-public-subnet).

**Bước 18 — Target group.**

**18.1 — Mở Target groups.** **EC2 → Target groups** chưa có gì; bấm **Create target group**.

![Target groups (chưa có) và Create target group](/images/workshop/runbook/img308.jpg)

**18.2 — Settings.** Target type **IP addresses** (Fargate dùng `awsvpc`, nên không chọn *Instances*), tên `fitness-assistant-dev-chat-tg`, protocol HTTP, port `3005`, IPv4, VPC của dự án, protocol version HTTP1.

![IP addresses, tên, HTTP 3005 và VPC](/images/workshop/runbook/img309.jpg)

**18.3 — Health check.** Path `/health`; healthy threshold 2, unhealthy 3, timeout 5 giây, interval 20 giây, success code 200.

![Health check path /health, ngưỡng, timeout, interval và success codes](/images/workshop/runbook/img310.jpg)

**18.4 — Không đăng ký target.** ECS service tự đăng ký IP của task; chỉ cần bấm **Next**.

![Trang Register targets (chưa thêm IP) và Next](/images/workshop/runbook/img311.jpg)

**18.5 — Review và tạo.** Kiểm tra phần tóm tắt (HTTP 3005, `/health`, 0 target) và bấm **Create target group**.

![Review: fitness-assistant-dev-chat-tg và Create target group](/images/workshop/runbook/img312.jpg)

**18.6 — Stickiness.** Sau đó đặt deregistration delay 30 giây và **Turn on stickiness**: load-balancer generated cookie, 1 ngày — phù hợp với cơ chế polling dự phòng của Socket.IO.

![Stickiness với load balancer cookie 1 ngày](/images/workshop/runbook/img313.jpg)

**Bước 19 — Application Load Balancer.** `fitness-assistant-dev-chat-alb`, internet-facing, IPv4, subnet `public-a` và `public-b`, chỉ dùng security group `fitness-assistant-dev-chat-alb-sg`, listener HTTP:80 → forward tới `fitness-assistant-dev-chat-tg`.

**19.1 — Mở Load balancers.** Chưa có; bấm **Create load balancer**.

![Load balancers (chưa có) và Create load balancer](/images/workshop/runbook/img314.jpg)

**19.2 — Chọn loại.** Bấm **Create** dưới **Application Load Balancer**.

![Create dưới Application Load Balancer](/images/workshop/runbook/img315.jpg)

**19.3 — Basic configuration và network mapping.** Tên `fitness-assistant-dev-chat-alb`, **Internet-facing**, **IPv4**, VPC của dự án, và tick cả hai zone cùng public subnet: `ap-southeast-1a` → `public-a`, `ap-southeast-1b` → `public-b`. Chọn security group `fitness-assistant-dev-chat-alb-sg` duy nhất (phía dưới trang).

![Tên, Internet-facing, IPv4, VPC và hai zone với public-a / public-b](/images/workshop/runbook/img316.jpg)

**19.4 — Listener.** Protocol **HTTP**, port `80`, default action **Forward to target groups**, target group `fitness-assistant-dev-chat-tg`. Rồi bấm **Create load balancer**.

![Listener HTTP:80, Forward to target groups và target group của Chat](/images/workshop/runbook/img317.jpg)

**19.5 — Đọc DNS name.** Mở load balancer mới; trạng thái **Provisioning** khi đang khởi động. Ghi lại DNS name `fitness-assistant-dev-chat-alb-<id>.ap-southeast-1.elb.amazonaws.com`, và mở listener **HTTP:80**.

![Chi tiết load balancer, DNS name và listener HTTP:80](/images/workshop/runbook/img318.jpg)

**Bước 20 — Idle timeout 120 giây.**

**20.1 — Sửa attribute.** ALB → **Attributes → Edit**: **Connection idle timeout** `0` giờ `2` phút `0` giây (120 giây), phù hợp hơn với kết nối WebSocket sống lâu; **Save changes**.

![Connection idle timeout 0 giờ 2 phút 0 giây](/images/workshop/runbook/img319.jpg)

**Bước 21 — Ẩn các path nội bộ.** Action mặc định của listener forward mọi path, kể cả `/internal/*` và `/metrics`. Thêm hai rule vào *HTTP:80*; `/health`, `/chat/*` và `/socket.io/*` vẫn tới được container.

**21.1 — Rule 1: `/internal/*`.** Trong listener bấm **Add rule**. Condition **Path** với giá trị `/internal/*` (value matching); action **Return fixed response**: response code `404`, content type `text/plain`, body `Not found`; bấm **Next**.

![Path /internal/*, Return fixed response 404 text/plain và Next](/images/workshop/runbook/img320.jpg)

**21.2 — Priority.** Đặt priority `1` (trên rule mặc định) và bấm **Next**, rồi tạo rule.

![Priority 1 trên rule mặc định và Next](/images/workshop/runbook/img321.jpg)

**21.3 — Rule 2: `/metrics`.** Lặp lại 21.1–21.2 với path `/metrics` và priority `2` (cùng fixed response 404).

*Runbook không có ảnh của rule thứ hai; màn hình ECS service ở Bước 22 liệt kê cả hai rule.*

#### Phần G — Service

**Bước 22 — ECS service.** **Cluster → Services → Create**:

| Cài đặt | Giá trị |
|---|---|
| Compute | Launch type **FARGATE**, platform `LATEST` |
| Task definition | `fitness-assistant-dev-chat` (revision mới nhất) |
| Service name | `fitness-assistant-dev-chat-service`, replica, **1 desired task** |
| Networking | chỉ `private-app-a` + `private-app-b`, security group `fitness-assistant-dev-chat-sg`, **tắt public IP** |
| Load balancing | ALB có sẵn `fitness-assistant-dev-chat-alb`, container `chat-service 3005:3005`, listener HTTP:80 có sẵn, target group `fitness-assistant-dev-chat-tg` có sẵn |
| Health check grace period | 60 giây |
| Service Connect / discovery / auto scaling | tắt |

**22.1 — Mở cluster.** Banner báo task definition `fitness-assistant-dev-chat:1` đã tạo; cluster chưa có service. Bấm **Create** ở tab Services.

![Banner task definition đã tạo, Services (0) và Create](/images/workshop/runbook/img322.jpg)

**22.2 — Compute.** Compute options **Launch type**, launch type **Fargate**, platform version **LATEST**.

![Launch type, Fargate và LATEST](/images/workshop/runbook/img323.jpg)

**22.3 — Service details.** Task definition family `fitness-assistant-dev-chat`, revision (mới nhất — ảnh hiện `1`), service name `fitness-assistant-dev-chat-service`.

![Task definition family, revision và service name](/images/workshop/runbook/img324.jpg)

**22.4 — Deployment configuration.** Scheduling strategy **Replica**, **Desired tasks** `1`, health check grace period `60` giây (ảnh vẫn hiện mặc định trống `0`).

![Replica và desired tasks 1](/images/workshop/runbook/img325.jpg)

**22.5 — Networking.** VPC của dự án, hai private app subnet (`private-app-a`, `private-app-b`), **Use an existing security group** với `fitness-assistant-dev-chat-sg`, và **Public IP** tắt.

![VPC, private app subnet, chat-sg và Public IP tắt](/images/workshop/runbook/img326.jpg)

**22.6 — Load balancer.** Tick **Use load balancing**, loại **Application Load Balancer**, container `chat-service 3005:3005`, **Use an existing load balancer** `fitness-assistant-dev-chat-alb`.

![Application Load Balancer, container chat-service 3005:3005 và ALB có sẵn](/images/workshop/runbook/img327.jpg)

**22.7 — Listener và target group.** **Use an existing listener** `HTTP:80` (danh sách rule hiện `/internal/*` priority 1, `/metrics` priority 2 và rule mặc định) và **Use an existing target group** `fitness-assistant-dev-chat-tg`.

![Listener HTTP:80 có sẵn với ba rule và target group có sẵn](/images/workshop/runbook/img328.jpg)

**22.8 — Tạo.** Để tắt VPC Lattice, auto scaling, volume và tag, rồi bấm **Create**.

![Tên target group và nút Create](/images/workshop/runbook/img329.jpg)

Desired count giữ **1**: trạng thái phiên Socket.IO lưu trong bộ nhớ, nên task thứ hai sẽ chia tách các phiên cho tới khi có shared adapter (ví dụ Redis). Ngay sau khi tạo, service hiện *Running 0 / Pending 1* trong lúc kéo image, inject secret và tạo ENI. Nếu task dừng, hãy đọc *Stopped reason* và *Events* của service thay vì tạo lại service.

**Bước 23 — Kiểm tra.**

**23.1 — Trạng thái service.** Service **Active**, deployment **Completed** và cột task ghi **1/1 Tasks running**.

![Service active: 1/1 task đang chạy, deployment hoàn tất](/images/workshop/runbook/img330.jpg)

**23.2 — Sức khoẻ target.** Trong target group, **Healthy** là 1 và target đã đăng ký `10.0.11.164:3005` là **Healthy**.

![Healthy 1 và target 10.0.11.164:3005](/images/workshop/runbook/img331.jpg)

**23.3 — Gọi thử.** Mở `http://<alb-dns>/health`, và Socket.IO handshake `http://<alb-dns>/socket.io/?EIO=4&transport=polling`, phải trả `0{"sid":"…","upgrades":["websocket"],…}` — không phải 404, 502 hay 503. Xem [5.5.3](../../5.5-Test-Validation/5.5.3-Chat-Health-SocketIO/).

#### Phần H — Nối vào API và frontend

**Bước 24 — REST qua API Gateway.**

**24.1 — Tạo integration.** Trong `fitness-assistant-dev-api` tạo integration gắn với route `ANY /chat/{proxy+}`: loại **HTTP URI**, method `ANY`, URL `http://<alb-dns>/chat/{proxy}`, rồi **Create**. Phần `{proxy}` rất quan trọng — `/chat/conversations` phải tới backend là `/chat/conversations`.

![Route ANY /chat/{proxy+}, HTTP URI, method ANY, URL của ALB và Create](/images/workshop/runbook/img333.jpg)

**24.2 — Kiểm thử.** `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/chat/conversations` (cần Bearer token để có dữ liệu thật).

**Bước 25 — Frontend.** Đặt Socket.IO URL (`VITE_CHAT_WS_URL`) trỏ tới ALB, build lại và publish lại theo [quy trình redeploy](../5.4.3-Frontend-S3/#redeploy):

```
REST:      Frontend → API Gateway → /chat/{proxy+} → Chat ALB → ECS
Socket.IO: Frontend → Chat ALB → /socket.io/ → ECS
```

**Bước 26 — Triển khai task definition đã sửa.** ECS → `fitness-assistant-dev-cluster` → `fitness-assistant-dev-chat-service` → *Update* → task definition `fitness-assistant-dev-chat:3`, giữ nguyên các thứ khác, *Force new deployment*. Trạng thái đích: 1 running, 0 pending, deployment *Completed*, và không còn `URL must start with postgresql://` trong `/ecs/fitness-assistant-dev-chat`.

*Runbook không có ảnh của Bước 25 và 26.*
