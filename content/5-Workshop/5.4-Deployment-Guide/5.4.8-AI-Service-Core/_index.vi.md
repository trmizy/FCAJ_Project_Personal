---
title: "AI Service — database, queue và Bedrock"
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

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của bước nhỏ được viết ngay phía trên ảnh.

#### Bước 1 — Database secret

Không cần `CREATE DATABASE` bằng tay: migration Lambda kết nối tới maintenance database `postgres`, kiểm tra `pg_database`, tạo `fitness_assistant_ai` nếu chưa có, rồi chạy `prisma migrate deploy`, và từ chối chạy trên database khác.

**1.1 — Chọn loại và nhập các cặp.** **Secrets Manager → Store a new secret**, chọn **Other type of secret**, nhập năm cặp giống các service khác với `database` = `fitness_assistant_ai`, rồi bấm **Next**.

![Other type of secret, năm dòng key/value và Next (thông tin đăng nhập đã che)](/images/workshop/runbook/img148.jpg)

**1.2 — Đặt tên secret.** Nhập `fitness-assistant/dev/ai-database` và bấm **Next** (rồi lưu secret).

![Tên secret fitness-assistant/dev/ai-database và Next](/images/workshop/runbook/img149.jpg)

#### Bước 2 — Migration role và Lambda

**2.1 — Tạo role.** `fitness-assistant-dev-ai-migrate-role`: AWS service → Lambda với hai managed policy (`AWSLambdaBasicExecutionRole`, `AWSLambdaVPCAccessExecutionRole`).

*Runbook không có ảnh của bước tạo role; form giống Bước 5.*

**2.2 — Thêm policy cho secret.** Trên role, **Add permissions → Create inline policy → JSON**: cho phép `secretsmanager:GetSecretValue` trên `fitness-assistant/dev/ai-database*`, bấm **Next** và đặt tên `fitness-assistant-dev-ai-migrate-secret`.

![JSON editor với GetSecretValue trên secret AI và Next](/images/workshop/runbook/img150.jpg)

**2.3 — Điền thông tin function.** **Lambda → Create function**, **Author from scratch**, tên `fitness-assistant-dev-ai-migrate`, runtime **Node.js 22.x** (x86_64), custom execution role `fitness-assistant-dev-ai-migrate-role`, rồi **Create function**.

![Author from scratch, tên, runtime và migrate role](/images/workshop/runbook/img151.jpg)

**2.4 — Đặt memory và timeout.** **Configuration → General configuration → Edit**: **Memory** `1024` MB, **Timeout** `5` phút `0` giây, **Save**.

![Memory 1024 MB, timeout 5 phút, Save](/images/workshop/runbook/img152.jpg)

**2.5 — Đặt handler.** **Code → Runtime settings → Edit**: `dist/migrate-lambda.handler`, **Save**.

![Handler dist/migrate-lambda.handler và Save](/images/workshop/runbook/img153.jpg)

**2.6 — Upload code.** **Upload from → .zip file**, chọn `ai-migrate-lambda.zip` (~21 MiB, upload trực tiếp là đủ) và bấm **Update**.

![ai-migrate-lambda.zip đã chọn (22.32 MB) và Update](/images/workshop/runbook/img154.jpg)

**2.7 — Gắn VPC.** **Configuration → VPC → Edit**: VPC của dự án, cả hai private app subnet và `fitness-assistant-dev-lambda-sg`, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img155.jpg)

**2.8 — Thêm environment variable.** `NODE_ENV=production`, `DATABASE_SECRET_ID=fitness-assistant/dev/ai-database`, `AI_DATABASE_NAME=fitness_assistant_ai`. Ảnh cho thấy kết quả đã lưu; nút **Edit** là nơi thêm các biến này.

![Ba environment variable và nút Edit](/images/workshop/runbook/img156.jpg)

#### Bước 3 — Chạy 22 migration

**3.1 — Tạo test event.** Ở tab **Test** chọn **Create new event**, đặt tên `test-db-ai`, giữ `{}` (hoặc `{"database": "fitness_assistant_ai"}`) và bấm **Test**.

![Create new event, tên event và nút Test](/images/workshop/runbook/img157.jpg)

**3.2 — Đọc kết quả.** Lần chạy phải thành công với response bên dưới.

![Executing function succeeded: status ok, databaseCreated true, migrateExitCode 0](/images/workshop/runbook/img158.jpg)

**Kết quả mong đợi:** `status = ok`, `database = fitness_assistant_ai`, `databaseCreated = true`, `migrateExitCode = 0`, `22 migrations found`, `All migrations have been successfully applied.` 22 migration không chứa `DROP` hay `TRUNCATE` — chỉ có một lệnh `DELETE` khử trùng lặp không ảnh hưởng database mới.

#### Bước 4 — SQS queue

SQS thay thế Redis/BullMQ cho việc tạo plan AI trên AWS.

**4.1 — Tạo dead-letter queue.** **SQS → Create queue**, loại **Standard**, tên `fitness-assistant-dev-ai-tasks-dlq`, giữ mặc định và bấm **Create queue**.

![Loại Standard và tên fitness-assistant-dev-ai-tasks-dlq](/images/workshop/runbook/img159.jpg)

**4.2 — Kiểm tra DLQ.** Banner phải báo queue đã được tạo.

![Queue fitness-assistant-dev-ai-tasks-dlq created successfully](/images/workshop/runbook/img160.jpg)

**4.3 — Đặt tên queue chính và visibility timeout.** **Create queue**, **Standard**, tên `fitness-assistant-dev-ai-tasks`, **Visibility timeout** `10` **Minutes** — dài hơn timeout 300 giây của Worker, để message không bị giao lại khi đang xử lý.

![Tên fitness-assistant-dev-ai-tasks và visibility timeout 10 phút](/images/workshop/runbook/img161.jpg)

**4.4 — Bật dead-letter queue.** Cuộn tới **Dead-letter queue**, chọn **Enabled**, chọn ARN của `fitness-assistant-dev-ai-tasks-dlq` và đặt **Maximum receives** là `2`.

![DLQ Enabled, ARN của DLQ và maximum receives 2](/images/workshop/runbook/img162.jpg)

**4.5 — Tạo queue.** Xem lại phần redrive và bấm **Create queue**.

![Phần redrive với DLQ đã bật và nút Create queue](/images/workshop/runbook/img163.jpg)

Sao chép queue URL (`https://sqs.ap-southeast-1.amazonaws.com/<account-id>/fitness-assistant-dev-ai-tasks`) — nó trở thành `AI_TASKS_QUEUE_URL`.

#### Bước 5 — Role cho AI HTTP Lambda

**5.1 — Chọn trusted entity.** **IAM → Roles → Create role**: **AWS service**, use case **Lambda**, **Next**.

![AWS service, use case Lambda và Next](/images/workshop/runbook/img164.jpg)

**5.2 — Đặt tên role.** `fitness-assistant-dev-ai-lambda-role`.

![Tên role fitness-assistant-dev-ai-lambda-role](/images/workshop/runbook/img165.jpg)

**5.3 — Kiểm tra managed policy.** `AWSLambdaBasicExecutionRole` và `AWSLambdaVPCAccessExecutionRole`, rồi tạo role.

![Hai managed policy](/images/workshop/runbook/img166.jpg)

**5.4 — Viết runtime policy.** Trên role mở **Add permissions → Create inline policy → JSON** và dán:

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

![JSON editor: secret, SQS send, Lambda invoke](/images/workshop/runbook/img167.jpg)

**5.5 — Đặt tên và tạo policy.** `fitness-assistant-dev-ai-runtime-policy`, rồi **Create policy**.

![Tên policy và Create policy](/images/workshop/runbook/img168.jpg)

**5.6 — Kiểm tra role.** Runtime policy phải xuất hiện cạnh hai managed policy.

![Role với fitness-assistant-dev-ai-runtime-policy](/images/workshop/runbook/img169.jpg)

Gym không có trong danh sách vì code AI không bao giờ gọi nó. HTTP Lambda chỉ có thể **gửi** vào queue; việc nhận là của Worker.

#### Bước 6 — Tạo AI HTTP Lambda

**6.1 — Điền thông tin function.** **Lambda → Create function**, tên `fitness-assistant-dev-ai`, runtime **Node.js 22.x** (x86_64); ở **Additional settings → Custom execution role** chọn `fitness-assistant-dev-ai-lambda-role` và bấm **Save**, rồi **Create function**.

![Author from scratch, tên, runtime và AI role](/images/workshop/runbook/img170.jpg)

**6.2 — Upload code.** **Upload from → .zip file**, `ai-lambda.zip` (34.68 MB), **Update**.

![ai-lambda.zip đã chọn và Update](/images/workshop/runbook/img171.jpg)

**6.3 — Đặt handler.** `dist/lambda.handler`, **Save**.

![Handler dist/lambda.handler và Save](/images/workshop/runbook/img172.jpg)

**6.4 — Đặt memory và timeout.** **Memory** `1024` MB, **Timeout** `0` phút `30` giây (sau đó 29 giây, ngay dưới giới hạn integration của API Gateway), **Save**.

![Memory 1024 MB, timeout 30 giây, Save](/images/workshop/runbook/img173.jpg)

**6.5 — Gắn VPC.** Các private app subnet và security group của Lambda, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img174.jpg)

**6.6 — Thêm environment đầu tiên.** Lúc đầu vẫn trỏ tới Anthropic API (`LLM_PROVIDER=anthropic`, gọi qua NAT Gateway vì endpoint nằm ngoài AWS). `AI_TASKS_QUEUE_URL` là queue URL ở Bước 4.

![Environment đầu tiên với AI_TASKS_QUEUE_URL và LLM_PROVIDER=anthropic](/images/workshop/runbook/img175.jpg)

**6.7 — Save.** Cùng danh sách, cuộn xuống tới nút **Save**.

![Dòng LLM_PROVIDER=anthropic và Save](/images/workshop/runbook/img176.jpg)

#### Bước 7 — Chuyển sang Amazon Bedrock

**7.1 — Xem model catalog.** Trong **Amazon Bedrock → Model catalog** (region `ap-southeast-1`) lọc theo provider **Anthropic** và **Cohere**.

![Bộ lọc provider Anthropic + Cohere và thẻ Embed Multilingual](/images/workshop/runbook/img177.jpg)

**7.2 — Kiểm tra Nova và Cohere.** Lọc theo **Amazon** và **Cohere**: cả **Amazon Nova Pro** và **Cohere Embed Multilingual** đều có. **Quyết định: không cần Anthropic API key** — AI Service chuyển sang Bedrock, bỏ API key bên ngoài, giữ traffic trong AWS và tính phí cùng tài khoản. Cohere là model Marketplace: chấp nhận subscription/EULA một lần bằng quyền administrator ([5.3.1](../../5.3-Prerequisites/5.3.1-AWS-Account-Permissions/)).

![Provider Amazon và Cohere, thẻ Nova Pro và Embed Multilingual](/images/workshop/runbook/img178.jpg)

**7.3 — Thêm statement Bedrock.** Thêm các statement này vào `fitness-assistant-dev-ai-runtime-policy` (không xoá các statement có sẵn):

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

Cross-region inference profile có thể route tới foundation model ở nhiều region APAC, nên IAM phải cho phép **cả** profile lẫn foundation model bên dưới — condition giới hạn statement thứ hai chỉ cho các lời gọi đi qua profile này. Không thêm `AmazonBedrockFullAccess` và `bedrock:InvokeModelWithResponseStream`; code chỉ dùng `InvokeModel`.

*Runbook không có ảnh của việc sửa policy này; ba statement tương tự hiện trong trình soạn role Worker ở Bước 8.3.*

**7.4 — Upload bản build Bedrock.** Upload `ai-lambda.zip` mới (35.076.525 byte nén, 105.103.760 byte giải nén — gồm Bedrock Runtime SDK và engine Prisma `rhel-openssl-3.0.x`), giữ nguyên handler và VPC.

**7.5 — Thay environment.**

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

Xoá `ANTHROPIC_API_KEY`, `LLM_BASE_URL` và `OLLAMA_BASE_URL`. Không cần migration cho việc chuyển đổi này — schema không đổi.

![Environment của AI Lambda: queue URL, LLM_PROVIDER=bedrock và các dòng Bedrock, Save](/images/workshop/runbook/img179.jpg)

{{% notice note %}}
Số chiều embedding đổi từ 768 (Ollama, phát triển local) sang 1024 (Cohere). Code sẽ báo lỗi rõ ràng nếu bị yêu cầu ghi vector 1024 chiều vào index 768 chiều cũ thay vì làm hỏng nó, nên việc nạp tri thức vẫn tắt cho tới khi có vector store 1024 chiều — xem [5.4.9](../5.4.9-AI-Service-Vector-Search/).
{{% /notice %}}

#### Bước 8 — Role cho AI Worker

Role `fitness-assistant-dev-ai-worker-role` với hai managed policy và inline `fitness-assistant-dev-ai-worker-runtime-policy`. Không thêm: `AmazonBedrockFullAccess`, `AmazonSQSFullAccess`, `AWSLambdaFullAccess`.

**8.1 — Đặt tên role.** `fitness-assistant-dev-ai-worker-role`, mô tả "Execution role for Gymini AI Worker Lambda".

![Tên role fitness-assistant-dev-ai-worker-role](/images/workshop/runbook/img180.jpg)

**8.2 — Kiểm tra managed policy và tạo role.** Bấm **Create role**.

![Hai managed policy và Create role](/images/workshop/runbook/img181.jpg)

**8.3 — Viết runtime policy.** JSON gồm: secret AI; `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` trên `fitness-assistant-dev-ai-tasks`; invoke Auth/User/Fitness/Payment; và ba statement Bedrock giống Bước 7.3.

![JSON editor, các statement Bedrock ở nửa dưới](/images/workshop/runbook/img182.jpg)

**8.4 — Đặt tên và tạo policy.** `fitness-assistant-dev-ai-worker-runtime-policy`, **Create policy**. Phần tóm tắt liệt kê Bedrock, Lambda, Secrets Manager và SQS.

![Tên policy và Create policy](/images/workshop/runbook/img183.jpg)

Luồng kết quả:

```
AI HTTP Lambda ──sqs:SendMessage──► fitness-assistant-dev-ai-tasks ──ReceiveMessage──► AI Worker Lambda
                                                                                       ├── Nova Pro
                                                                                       ├── Cohere Embed
                                                                                       ├── Aurora
                                                                                       └── internal Lambdas
```

#### Bước 9 — AI Worker Lambda

**9.1 — Điền thông tin function.** **Lambda → Create function**, tên `fitness-assistant-dev-ai-worker`, runtime **Node.js 22.x** (x86_64), và trong panel custom execution role chọn `fitness-assistant-dev-ai-worker-role`, **Save**.

![Author from scratch, tên, runtime và Worker role](/images/workshop/runbook/img184.jpg)

**9.2 — Tạo function.** Kiểm tra **Additional settings** (custom execution role là Worker role) và bấm **Create function**.

![Link custom execution role và nút Create function](/images/workshop/runbook/img185.jpg)

**9.3 — Upload code.** **Upload from → .zip file → Choose file**: `ai-worker-lambda.zip` (bản build Bedrock mới), rồi **Update**.

![Choose file và Update](/images/workshop/runbook/img186.jpg)

**9.4 — Đặt handler.** **`dist/worker-lambda.handler`** (không phải `dist/lambda.handler`), **Save**.

![Handler dist/worker-lambda.handler và Save](/images/workshop/runbook/img187.jpg)

**9.5 — Đặt memory và timeout.** **Memory** `1024` MB, **Timeout** `5` phút `0` giây (**300 giây**), ephemeral storage giữ `512` MB, **Save**.

![Memory 1024 MB, timeout 5 phút, Save](/images/workshop/runbook/img188.jpg)

**9.6 — Gắn VPC.** Chỉ các private app subnet (không bao giờ dùng DB subnet) và security group của Lambda, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img189.jpg)

**9.7 — Thêm environment.** Sao chép environment của HTTP Lambda với một thay đổi quan trọng: **`LLM_TIMEOUT_MS=180000`** thay vì 25000, vì các lần tạo có thể chạy vài phút. `AWS_REGION` không đặt thủ công (Lambda tự cung cấp), và không cần biến Anthropic/Ollama/Redis.

![Environment của Worker, LLM_TIMEOUT_MS=180000 ở dòng đầu, Save](/images/workshop/runbook/img190.jpg)

#### Bước 10 — SQS trigger cho Worker

**10.1 — Kiểm tra queue.** Mở `fitness-assistant-dev-ai-tasks`: default visibility timeout 10 phút, **Dead-letter queue: Enabled**, DLQ `fitness-assistant-dev-ai-tasks-dlq`, maximum receives 2.

![Visibility timeout 10 phút, DLQ đã bật, ARN của DLQ và maximum receives 2](/images/workshop/runbook/img191.jpg)

**10.2 — Mở Add trigger.** **Lambda → `fitness-assistant-dev-ai-worker` → Configuration → Triggers** — đang hiện **No triggers**. Bấm **Add trigger**.

![Triggers (0) và nút Add trigger](/images/workshop/runbook/img192.jpg)

**10.3 — Cấu hình SQS trigger.** Nguồn **SQS**, queue `fitness-assistant-dev-ai-tasks`, tick **Activate trigger**, **Batch size** `1`, batch window `0`, không đặt maximum concurrency, tick **Report batch item failures** (Worker trả `batchItemFailures`, nên một message lỗi không buộc cả batch phải thử lại), rồi **Add**.

![SQS, queue, Activate trigger, batch size 1, Report batch item failures](/images/workshop/runbook/img193.jpg)

**10.4 — Kiểm tra trigger.** Banner báo đã thêm và danh sách Triggers hiện queue SQS.

![Trigger đã được thêm vào fitness-assistant-dev-ai-worker](/images/workshop/runbook/img194.jpg)

#### Bước 11 — Role và Lambda cho AI Jobs

Role `fitness-assistant-dev-ai-jobs-role` (hai managed policy + inline `fitness-assistant-dev-ai-jobs-runtime-policy`: secret AI và ba statement Bedrock — Cohere cho embedding, Nova cho LLM/safety judging).

**11.1 — Chọn trusted entity.** **AWS service**, use case **Lambda**, **Next**.

![AWS service, use case Lambda và Next](/images/workshop/runbook/img195.jpg)

**11.2 — Đặt tên role.** `fitness-assistant-dev-ai-jobs-role`.

![Tên role fitness-assistant-dev-ai-jobs-role](/images/workshop/runbook/img196.jpg)

**11.3 — Kiểm tra managed policy và tạo role.**

![Hai managed policy và Create role](/images/workshop/runbook/img197.jpg)

**11.4 — Viết runtime policy.** JSON gồm statement secret và ba statement Bedrock.

![JSON editor với statement secret và Bedrock, Next](/images/workshop/runbook/img198.jpg)

**11.5 — Đặt tên và tạo policy.** `fitness-assistant-dev-ai-jobs-runtime-policy`, **Create policy**. Phần tóm tắt liệt kê Bedrock và Secrets Manager.

![Tên policy và Create policy](/images/workshop/runbook/img199.jpg)

**11.6 — Kiểm tra role.** Role giờ có ba policy.

![Role với jobs runtime policy](/images/workshop/runbook/img200.jpg)

**11.7 — Điền thông tin function.** `fitness-assistant-dev-ai-jobs`, **Node.js 22.x**, custom execution role `fitness-assistant-dev-ai-jobs-role`, **Create function**.

![Author from scratch, tên ai-jobs, runtime và jobs role](/images/workshop/runbook/img201.jpg)

**11.8 — Upload code.** `ai-lambda.zip` (35.08 MB), **Update**.

![Choose file, ai-lambda.zip và Update](/images/workshop/runbook/img202.jpg)

**11.9 — Đặt handler.** `dist/jobs-lambda.handler`, **Save**.

![Handler dist/jobs-lambda.handler và Save](/images/workshop/runbook/img203.jpg)

**11.10 — Đặt memory và timeout.** **Memory** `1024` MB, **Timeout** `10` phút `0` giây (**600 giây** — crawl cộng embedding là I/O dài và không bị giới hạn ~30 giây của API Gateway), **Save**.

![Memory 1024 MB, timeout 10 phút, Save](/images/workshop/runbook/img204.jpg)

**11.11 — Gắn VPC.** Các private app subnet và security group của Lambda, **Save**.

![VPC, hai private app subnet, security group của Lambda và Save](/images/workshop/runbook/img205.jpg)

**11.12 — Thêm environment.** `NODE_ENV`, `DATABASE_SECRET_ID`, `INTERNAL_SERVICE_SECRET` dùng chung, `LLM_PROVIDER=bedrock`, `BEDROCK_REGION`, `BEDROCK_CHAT_MODEL`, `BEDROCK_VISION_MODEL`, `EMBEDDING_PROVIDER=bedrock`, `BEDROCK_EMBEDDING_MODEL`, `KNOWLEDGE_VECTOR_SIZE=1024`, rồi **Save**.

![Environment variable của Jobs Lambda và Save](/images/workshop/runbook/img206.jpg)

Chưa gắn schedule nào: các job tri thức không được chạy cho tới khi có vector store 1024 chiều. Đó là trang tiếp theo.
