---
title: "5.4.8 AI Service — database, queue và Bedrock"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 5.4.8. </b> "
---

AI Service được chia thành ba Lambda, mỗi cái có yêu cầu thời gian khác nhau:

| Function | Handler | Timeout | Nhiệm vụ |
|---|---|---|---|
| `fitness-assistant-dev-ai` | `dist/lambda.handler` | 29–30 giây | HTTP API: chat, plans, marketplace, admin AI. Các lần tạo dài được đưa vào hàng đợi thay vì chạy ngay. |
| `fitness-assistant-dev-ai-worker` | `dist/worker-lambda.handler` | 300 giây | Nhận việc từ SQS và chạy các lần tạo workout/nutrition dài trên Nova Pro. |
| `fitness-assistant-dev-ai-jobs` | `dist/jobs-lambda.handler` | 600 giây | Job theo lịch: auto-accept dịch vụ cá nhân hoá và nạp tri thức (PubMed, RSS, web, local evidence). |

Trước khi triển khai, code đã được cập nhật để AI Lambda verify Bearer JWT bằng cách invoke Auth Lambda, gọi Auth/User/Fitness/Payment bằng direct invoke, và migration Lambda đọc `DATABASE_SECRET_ID` rồi tự tạo `fitness_assistant_ai`.

#### Bước 1 — Database secret

Tạo `fitness-assistant/dev/ai-database` (`database = fitness_assistant_ai`). Không cần `CREATE DATABASE` bằng tay: migration Lambda kết nối tới maintenance database `postgres`, kiểm tra `pg_database`, tạo `fitness_assistant_ai` nếu chưa có, rồi chạy `prisma migrate deploy`, và từ chối chạy trên database khác.

![Store a new secret cho database AI](/images/workshop/runbook/img148.jpg)

![Tên secret fitness-assistant/dev/ai-database](/images/workshop/runbook/img149.jpg)

#### Bước 2 — Migration role và Lambda

Role `fitness-assistant-dev-ai-migrate-role` (hai managed policy + inline `fitness-assistant-dev-ai-migrate-secret` cho phép `secretsmanager:GetSecretValue` trên `fitness-assistant/dev/ai-database*`).

![Inline policy cho secret database AI](/images/workshop/runbook/img150.jpg)

Lambda `fitness-assistant-dev-ai-migrate`: Node.js 22.x, x86_64, 1024 MB, 5 phút, handler `dist/migrate-lambda.handler`, artifact `ai-migrate-lambda.zip` (~21 MiB, upload trực tiếp), hai private app subnet + Lambda SG, environment `NODE_ENV=production`, `DATABASE_SECRET_ID=fitness-assistant/dev/ai-database`, `AI_DATABASE_NAME=fitness_assistant_ai`.

![Create function fitness-assistant-dev-ai-migrate](/images/workshop/runbook/img151.jpg)

![Memory 1024 MB, timeout 5 phút](/images/workshop/runbook/img152.jpg)

![Handler dist/migrate-lambda.handler](/images/workshop/runbook/img153.jpg)

![Upload ai-migrate-lambda.zip (22.3 MB)](/images/workshop/runbook/img154.jpg)

![Cấu hình VPC](/images/workshop/runbook/img155.jpg)

![Environment variable của migration Lambda](/images/workshop/runbook/img156.jpg)

#### Bước 3 — Chạy 22 migration

**Test → Create new event** với `{}` (hoặc `{"database": "fitness_assistant_ai"}`), rồi invoke.

![Test event cho migration AI](/images/workshop/runbook/img157.jpg)

![Kết quả: status ok, databaseCreated true, migrateExitCode 0](/images/workshop/runbook/img158.jpg)

**Kết quả mong đợi:** `status = ok`, `database = fitness_assistant_ai`, `databaseCreated = true`, `migrateExitCode = 0`, `22 migrations found`, `All migrations have been successfully applied.` 22 migration này không có `DROP` hay `TRUNCATE` — chỉ một `DELETE` khử trùng lặp không ảnh hưởng database mới.

#### Bước 4 — SQS queue

SQS thay cho Redis/BullMQ trong việc tạo kế hoạch AI trên AWS.

1. **SQS → Create queue**, Standard, tên `fitness-assistant-dev-ai-tasks-dlq` (mặc định).
2. **Create queue**, Standard, tên `fitness-assistant-dev-ai-tasks`, **visibility timeout 10 phút (600 giây)** — dài hơn timeout 300 giây của Worker, để message không bị giao lại khi vẫn đang xử lý — và bật dead-letter queue: `fitness-assistant-dev-ai-tasks-dlq`, **maximum receives 2**.

![Dead-letter queue fitness-assistant-dev-ai-tasks-dlq (Standard)](/images/workshop/runbook/img159.jpg)

![Đã tạo DLQ](/images/workshop/runbook/img160.jpg)

![Queue fitness-assistant-dev-ai-tasks với visibility timeout 10 phút](/images/workshop/runbook/img161.jpg)

![Bật dead-letter queue, maximum receives 2](/images/workshop/runbook/img162.jpg)

![Cấu hình redrive trước khi tạo queue](/images/workshop/runbook/img163.jpg)

Copy queue URL (`https://sqs.ap-southeast-1.amazonaws.com/<account-id>/fitness-assistant-dev-ai-tasks`) — giá trị này là `AI_TASKS_QUEUE_URL`.

#### Bước 5 — Role cho AI HTTP Lambda

`fitness-assistant-dev-ai-lambda-role` (AWS service → Lambda, hai managed policy) với inline policy `fitness-assistant-dev-ai-runtime-policy`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/ai-database*"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:ap-southeast-1:<account-id>:fitness-assistant-dev-ai-tasks"
    },
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-fitness",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-payment"
      ]
    }
  ]
}
```

Không có Gym trong danh sách vì code AI không bao giờ gọi Gym. HTTP Lambda chỉ được **gửi** vào queue; việc nhận là của Worker.

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img164.jpg)

![Tên role fitness-assistant-dev-ai-lambda-role](/images/workshop/runbook/img165.jpg)

![Managed policy](/images/workshop/runbook/img166.jpg)

![Runtime policy JSON: secret, gửi SQS, invoke Lambda](/images/workshop/runbook/img167.jpg)

![Tên policy fitness-assistant-dev-ai-runtime-policy](/images/workshop/runbook/img168.jpg)

![Role với runtime policy](/images/workshop/runbook/img169.jpg)

#### Bước 6 — Tạo AI HTTP Lambda

`fitness-assistant-dev-ai`: Node.js 22.x, x86_64, role `fitness-assistant-dev-ai-lambda-role`, artifact `ai-lambda.zip`, handler `dist/lambda.handler`, 1024 MB, 30 giây (sau đó 29 giây, ngay dưới giới hạn integration của API Gateway), private app subnet + Lambda SG.

![Create function fitness-assistant-dev-ai](/images/workshop/runbook/img170.jpg)

![Upload ai-lambda.zip (34.7 MB)](/images/workshop/runbook/img171.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img172.jpg)

![Memory 1024 MB, timeout 30 giây](/images/workshop/runbook/img173.jpg)

![Cấu hình VPC](/images/workshop/runbook/img174.jpg)

Environment đầu tiên vẫn nhắm tới Anthropic API (`LLM_PROVIDER=anthropic`, gọi qua NAT Gateway vì endpoint nằm ngoài AWS):

![Environment đầu tiên, với LLM_PROVIDER=anthropic](/images/workshop/runbook/img175.jpg)

![Environment đầu tiên (tiếp)](/images/workshop/runbook/img176.jpg)

#### Bước 7 — Chuyển sang Amazon Bedrock

Trong **Amazon Bedrock → Model catalog** (region `ap-southeast-1`), cả **Amazon Nova Pro** lẫn **Cohere Embed Multilingual** đều có sẵn. **Quyết định: không cần Anthropic API key nữa** — AI Service chuyển sang Bedrock, bỏ được API key bên ngoài, giữ traffic trong AWS và tính tiền qua cùng account. Cohere là model Marketplace: chấp nhận subscription/EULA một lần bằng tài khoản admin ([5.3.1](../../5.3-Prerequisites/5.3.1-AWS-Account-Permissions/)).

![Bedrock model catalog lọc theo Anthropic và Cohere](/images/workshop/runbook/img177.jpg)

![Bedrock model catalog: model Amazon Nova và Cohere Embed](/images/workshop/runbook/img178.jpg)

Thêm các statement sau vào `fitness-assistant-dev-ai-runtime-policy` (không xoá các statement cũ):

```json
{
  "Sid": "InvokeNovaProApacInferenceProfile",
  "Effect": "Allow",
  "Action": "bedrock:InvokeModel",
  "Resource": ["arn:aws:bedrock:ap-southeast-1:<account-id>:inference-profile/apac.amazon.nova-pro-v1:0"]
},
{
  "Sid": "InvokeNovaProOnlyThroughApacProfile",
  "Effect": "Allow",
  "Action": "bedrock:InvokeModel",
  "Resource": ["arn:aws:bedrock:*::foundation-model/amazon.nova-pro-v1:0"],
  "Condition": {
    "StringLike": {
      "bedrock:InferenceProfileArn": "arn:aws:bedrock:ap-southeast-1:<account-id>:inference-profile/apac.amazon.nova-pro-v1:0"
    }
  }
},
{
  "Sid": "InvokeCohereEmbedMultilingualV3",
  "Effect": "Allow",
  "Action": "bedrock:InvokeModel",
  "Resource": ["arn:aws:bedrock:ap-southeast-1::foundation-model/cohere.embed-multilingual-v3"]
}
```

Cross-region inference profile có thể route tới foundation model ở nhiều region APAC, nên IAM phải cho phép **cả** profile lẫn foundation model bên dưới — condition giới hạn statement thứ hai chỉ áp dụng cho lời gọi qua profile này. Không thêm `AmazonBedrockFullAccess` và `bedrock:InvokeModelWithResponseStream`; code chỉ dùng `InvokeModel`.

Upload `ai-lambda.zip` mới build cho Bedrock (35.076.525 byte nén, 105.103.760 byte giải nén — có kèm Bedrock Runtime SDK và Prisma engine `rhel-openssl-3.0.x`), giữ nguyên handler và VPC, và thay environment bằng:

| Biến | Giá trị |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/ai-database` |
| `INTERNAL_SERVICE_SECRET` | giá trị dùng chung |
| `AUTH_LAMBDA_NAME`, `USER_LAMBDA_NAME`, `FITNESS_LAMBDA_NAME`, `PAYMENT_LAMBDA_NAME` | tên bốn function |
| `QUEUE_PROVIDER` / `AI_TASKS_QUEUE_URL` | `sqs` / queue URL |
| `LLM_PROVIDER` / `BEDROCK_REGION` | `bedrock` / `ap-southeast-1` |
| `BEDROCK_CHAT_MODEL` / `BEDROCK_VISION_MODEL` | `apac.amazon.nova-pro-v1:0` |
| `EMBEDDING_PROVIDER` / `BEDROCK_EMBEDDING_MODEL` | `bedrock` / `cohere.embed-multilingual-v3` |
| `KNOWLEDGE_VECTOR_SIZE` | `1024` |
| `LLM_TIMEOUT_MS` | `25000` |
| `PLATFORM_COMMISSION_RATE` / `PERSONALIZED_SERVICE_AUTO_ACCEPT_DAYS` | `0.10` / `3` |

Xoá `ANTHROPIC_API_KEY`, `LLM_BASE_URL` và `OLLAMA_BASE_URL`. Việc chuyển đổi không cần chạy lại migration — schema không đổi.

![Environment của AI Lambda sau khi chuyển sang Nova Pro và Cohere](/images/workshop/runbook/img179.jpg)

{{% notice note %}}
Số chiều embedding đổi từ 768 (Ollama, môi trường local) sang 1024 (Cohere). Code sẽ báo lỗi rõ ràng nếu phải ghi vector 1024 chiều vào index cũ 768 chiều thay vì làm hỏng dữ liệu, nên việc nạp tri thức được tắt cho tới khi có vector store 1024 chiều — xem [5.4.9](../5.4.9-AI-Service-Vector-Search/).
{{% /notice %}}

#### Bước 8 — Role cho AI Worker

`fitness-assistant-dev-ai-worker-role` ("Execution role for Gymini AI Worker Lambda"), hai managed policy, inline `fitness-assistant-dev-ai-worker-runtime-policy` gồm: secret AI; `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` trên `fitness-assistant-dev-ai-tasks`; invoke Auth/User/Fitness/Payment; và cùng ba statement Bedrock. Không thêm: `AmazonBedrockFullAccess`, `AmazonSQSFullAccess`, `AWSLambdaFullAccess`.

![Tên role fitness-assistant-dev-ai-worker-role](/images/workshop/runbook/img180.jpg)

![Managed policy của Worker role](/images/workshop/runbook/img181.jpg)

![Worker runtime policy JSON (các statement Bedrock)](/images/workshop/runbook/img182.jpg)

![Tóm tắt policy: Bedrock, Lambda, Secrets Manager, SQS](/images/workshop/runbook/img183.jpg)

Luồng kết quả:

```
AI HTTP Lambda ──sqs:SendMessage──► fitness-assistant-dev-ai-tasks ──ReceiveMessage──► AI Worker Lambda
                                                                                       ├── Nova Pro
                                                                                       ├── Cohere Embed
                                                                                       ├── Aurora
                                                                                       └── internal Lambdas
```

#### Bước 9 — AI Worker Lambda

`fitness-assistant-dev-ai-worker`: Node.js 22.x, x86_64, role `fitness-assistant-dev-ai-worker-role`, artifact `ai-worker-lambda.zip` (bản build Bedrock mới), handler **`dist/worker-lambda.handler`** (không phải `dist/lambda.handler`), 1024 MB, **300 giây**, ephemeral storage 512 MB, chỉ private app subnet (không bao giờ chọn DB subnet) + Lambda SG.

![Create function fitness-assistant-dev-ai-worker](/images/workshop/runbook/img184.jpg)

![Additional settings với custom execution role](/images/workshop/runbook/img185.jpg)

![Upload ai-worker-lambda.zip](/images/workshop/runbook/img186.jpg)

![Handler dist/worker-lambda.handler](/images/workshop/runbook/img187.jpg)

![Memory 1024 MB, timeout 5 phút](/images/workshop/runbook/img188.jpg)

![Cấu hình VPC của Worker](/images/workshop/runbook/img189.jpg)

Worker copy environment của HTTP Lambda với một thay đổi quan trọng: **`LLM_TIMEOUT_MS=180000`** thay vì 25000, vì một lần tạo có thể kéo dài vài phút. Không tự đặt `AWS_REGION` (Lambda đã cung cấp), và không cần biến Anthropic/Ollama/Redis.

![Environment của Worker với LLM_TIMEOUT_MS=180000](/images/workshop/runbook/img190.jpg)

#### Bước 10 — SQS trigger cho Worker

Kiểm tra queue trước: visibility timeout 600 giây, DLQ `fitness-assistant-dev-ai-tasks-dlq`, maximum receives 2.

![Chi tiết queue: đã bật DLQ](/images/workshop/runbook/img191.jpg)

Sau đó **Lambda → `fitness-assistant-dev-ai-worker` → Add trigger → SQS**: queue `fitness-assistant-dev-ai-tasks`, **batch size 1**, batch window 0, kích hoạt trigger, không filter, không maximum concurrency, và bật **Report batch item failures** (Worker trả `batchItemFailures`, nên một message lỗi không buộc cả batch phải thử lại).

![Chưa có trigger nào](/images/workshop/runbook/img192.jpg)

![Add trigger: SQS queue, batch size 1, report batch item failures](/images/workshop/runbook/img193.jpg)

![Đã thêm SQS trigger vào fitness-assistant-dev-ai-worker](/images/workshop/runbook/img194.jpg)

#### Bước 11 — Role và Lambda cho AI Jobs

Role `fitness-assistant-dev-ai-jobs-role` (hai managed policy + inline `fitness-assistant-dev-ai-jobs-runtime-policy`: secret AI và ba statement Bedrock — Cohere cho embedding, Nova cho LLM/safety judging).

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img195.jpg)

![Tên role fitness-assistant-dev-ai-jobs-role](/images/workshop/runbook/img196.jpg)

![Managed policy](/images/workshop/runbook/img197.jpg)

![Jobs runtime policy JSON](/images/workshop/runbook/img198.jpg)

![Tóm tắt policy: Bedrock và Secrets Manager](/images/workshop/runbook/img199.jpg)

![Role với ba policy](/images/workshop/runbook/img200.jpg)

Lambda `fitness-assistant-dev-ai-jobs`: artifact `ai-lambda.zip`, handler `dist/jobs-lambda.handler`, 1024 MB, **600 giây** (crawl và tạo embedding là I/O dài, không bị giới hạn ~30 giây của API Gateway), private app subnet + Lambda SG.

![Create function fitness-assistant-dev-ai-jobs](/images/workshop/runbook/img201.jpg)

![Upload ai-lambda.zip (35.1 MB)](/images/workshop/runbook/img202.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img203.jpg)

![Memory 1024 MB, timeout 10 phút](/images/workshop/runbook/img204.jpg)

![Cấu hình VPC của jobs Lambda](/images/workshop/runbook/img205.jpg)

Environment: `NODE_ENV`, `DATABASE_SECRET_ID`, `INTERNAL_SERVICE_SECRET` dùng chung, `LLM_PROVIDER=bedrock`, `BEDROCK_REGION`, `BEDROCK_CHAT_MODEL`, `BEDROCK_VISION_MODEL`, `EMBEDDING_PROVIDER=bedrock`, `BEDROCK_EMBEDDING_MODEL`, `KNOWLEDGE_VECTOR_SIZE=1024`.

![Environment variable của jobs Lambda](/images/workshop/runbook/img206.jpg)

Chưa gắn schedule nào: các job tri thức không được chạy cho tới khi có vector store 1024 chiều. Đó là nội dung trang tiếp theo.
