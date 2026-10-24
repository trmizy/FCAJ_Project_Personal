---
title: "AI Service — vector search, lịch chạy và API"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 5.4.9. </b> "
---

Stack local dùng Qdrant làm vector store. Để lên AWS, code được thêm một lớp abstraction cho vector store với implementation OpenSearch (58/58 test pass), nên production không còn cần `QDRANT_HOST` / `QDRANT_PORT`. Request tới OpenSearch được ký bằng SigV4 (service `aoss`) dùng IAM role của từng Lambda — không có username, password hay API key nào của OpenSearch.

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của bước nhỏ được viết ngay phía trên ảnh.

#### Bước 1 — Upload lại ba AI Lambda

Bản build mới có OpenSearch client và hỗ trợ SigV4 (ZIP HTTP/Worker ≈ 36.325.814 byte), nên được upload trước, giữ nguyên từng handler. Với mỗi function dùng **Code → Upload from → .zip file** (hoặc S3) và bấm **Update**:

| Function | Artifact | Handler |
|---|---|---|
| `fitness-assistant-dev-ai` | `ai-lambda.zip` | `dist/lambda.handler` |
| `fitness-assistant-dev-ai-worker` | `ai-worker-lambda.zip` | `dist/worker-lambda.handler` |
| `fitness-assistant-dev-ai-jobs` | `ai-lambda.zip` | `dist/jobs-lambda.handler` |

Thay đổi này không cần migration database.

*Runbook không có ảnh của lần upload lại này; hộp thoại giống [5.4.8 Bước 6.2](../5.4.8-AI-Service-Core/).*

#### Bước 2 — Collection group với scale-to-zero

**2.1 — Đặt tên group.** **Amazon OpenSearch Service → Serverless → Collection groups → Create collection group**: tên `fitness-assistant-dev-ai`, generation **NextGen**, mô tả "Gymini AI vector search collection group".

![Tên collection group, nhãn NextGen và mô tả](/images/workshop/runbook/img207.jpg)

**2.2 — Đặt capacity.** Cuộn tới **Capacity management** và đặt:

| Capacity | Min | Max |
|---|---|---|
| Indexing | **0 OCU** | 2 OCU |
| Search | **0 OCU** | 2 OCU |

Rồi bấm **Create**. Min bằng 0 bật scale-to-zero: sau khoảng 10 phút rảnh, indexing và search về 0 OCU, và request đầu tiên sau đó có thể mất thêm 10–30 giây để "đánh thức". Khoảng 0–2 OCU hợp lý hơn nhiều cho DEV so với mức tối đa mặc định 96.

![Min/max OCU của indexing và search, Create](/images/workshop/runbook/img208.jpg)

**2.3 — Kiểm tra group.** Danh sách phải hiện `fitness-assistant-dev-ai`, NextGen, indexing 0 / 2 OCU và search 0 / 2 OCU.

![Dòng collection group: NextGen, 0 / 2 OCU](/images/workshop/runbook/img209.jpg)

#### Bước 3 — VPC endpoint riêng

**3.1 — Mở trang VPC endpoints.** **OpenSearch Service → Serverless → VPC endpoints** và bấm **Create VPC endpoint**. Chính trang này cảnh báo rằng nó quản lý endpoint cho collection **Classic** và collection NextGen dùng console Amazon EC2 VPC endpoints — hãy lưu ý nếu endpoint không hiện trong collection NextGen về sau.

![Trang VPC endpoints và nút Create VPC endpoint](/images/workshop/runbook/img210.jpg)

**3.2 — Điền endpoint.** Tên `fitness-dev-opensearch-vpce`, VPC `fitness-assistant-dev-vpc`, subnet `private-app-a` và `private-app-b`. Runbook chỉ định `fitness-assistant-dev-vpce-sg` có sẵn (TCP 443 từ Lambda SG); endpoint trong ảnh cho thấy Lambda SG được gắn — group nào được gắn cũng phải cho phép inbound TCP 443 từ security group của Lambda. Chờ **Available** (ảnh chụp lúc còn **Pending**) và ghi lại endpoint ID (`vpce-…`, không phải endpoint URL).

![Endpoint ID, hai private app subnet và security group được gắn (trạng thái Pending)](/images/workshop/runbook/img211.jpg)

#### Bước 4 — Collection vector search

**4.1 — Bắt đầu tạo collection.** **Serverless → Collections → Create collection**.

![Trang Collections chưa có collection và nút Create collection](/images/workshop/runbook/img212.jpg)

**4.2 — Đặt tên và chọn loại.** NextGen, tên `fitness-assistant-dev-ai-vectors`, mô tả "Gymini AI vector store for RAG and knowledge retrieval", loại collection **Vector search**.

![Tên collection, mô tả và loại Vector search](/images/workshop/runbook/img213.jpg)

**4.3 — Chọn Standard create và group.** Chọn **Standard create** (không dùng Express — cần kiểm soát private networking và access policy), **Select existing collection group** và chọn `fitness-assistant-dev-ai`.

![Standard create, collection group có sẵn fitness-assistant-dev-ai](/images/workshop/runbook/img214.jpg)

**4.4 — Network access.** Giữ khoá mã hoá do AWS sở hữu, chọn access type **Private (recommended)**, tick **VPC endpoints for access** và chọn endpoint ở Bước 3 — không có truy cập public.

![Private access với VPC endpoint đã chọn](/images/workshop/runbook/img215.jpg)

**4.5 — Data access policy, phần 1.** **Create as a new data access policy**, tên `fitness-dev-ai-vector-access`, cách định nghĩa **JSON** thay vì tick quyền trong visual editor.

![Create a new data access policy, tên policy và phương thức JSON](/images/workshop/runbook/img216.jpg)

**4.6 — Data access policy, phần 2.** Dán JSON:

```json
[
  {
    "Description": "Fitness Assistant AI vector data access",
    "Rules": [
      {
        "ResourceType": "collection",
        "Resource": ["collection/fitness-assistant-dev-ai-vectors"],
        "Permission": ["aoss:DescribeCollectionItems"]
      },
      {
        "ResourceType": "index",
        "Resource": ["index/fitness-assistant-dev-ai-vectors/*"],
        "Permission": [
          "aoss:CreateIndex",
          "aoss:DescribeIndex",
          "aoss:UpdateIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ]
      }
    ],
    "Principal": [
      "arn:aws:iam::<account-id>:role/fitness-assistant-dev-ai-lambda-role",
      "arn:aws:iam::<account-id>:role/fitness-assistant-dev-ai-worker-role",
      "arn:aws:iam::<account-id>:role/fitness-assistant-dev-ai-jobs-role"
    ]
  }
]
```

Cố ý không cấp `aoss:DeleteIndex`.

![JSON editor chứa data access policy](/images/workshop/runbook/img217.jpg)

**4.7 — OpenSearch UI.** Wizard cũng tạo một OpenSearch application và workspace để duyệt dữ liệu: **Create new OpenSearch application** `aoss-fitness-dev-ai` và **Create new workspace** `fitness-dev-ai-vectors`.

![Application mới aoss-fitness-dev-ai và workspace mới fitness-dev-ai-vectors](/images/workshop/runbook/img218.jpg)

**4.8 — Administrator và tạo collection.** Để trống IAM Identity Center, chỉ cấp quyền administrator cho IAM principal của tài khoản, rồi bấm **Create collection**.

![Administrator của application và nút Create collection](/images/workshop/runbook/img219.jpg)

**4.9 — Chờ tạo xong.** Trang hiện "Creating collection"; đừng rời trang cho tới khi trang chi tiết collection xuất hiện.

![Thông báo Important: creating OpenSearch Serverless resources](/images/workshop/runbook/img220.jpg)

Khi collection **Active**, sao chép **ARN** (cho IAM) và **OpenSearch endpoint** (`https://<collection-id>.aoss.ap-southeast-1.on.aws`, cho các Lambda) bằng nút copy của console. Không tạo index bằng tay.

#### Bước 5 — Quyền IAM cho cả ba AI role

Data access policy và IAM là hai lớp riêng; thiếu một trong hai sẽ trả 403. Làm hai bước nhỏ dưới đây cho **từng** role `fitness-assistant-dev-ai-lambda-role`, `-ai-worker-role` và `-ai-jobs-role` (ảnh là của role đầu tiên).

**5.1 — Dán policy.** **IAM → Roles → role → Add permissions → Create inline policy → JSON**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessAiVectorCollection",
      "Effect": "Allow",
      "Action": "aoss:APIAccessAll",
      "Resource": "arn:aws:aoss:ap-southeast-1:<account-id>:collection/<collection-id>"
    }
  ]
}
```

Không dùng: `AmazonOpenSearchServerlessFullAccess`, `aoss:DashboardsAccessAll`, `aoss:*` — các Lambda chỉ cần data-plane API.

![aoss:APIAccessAll giới hạn theo ARN của collection](/images/workshop/runbook/img221.jpg)

**5.2 — Đặt tên và tạo.** `fitness-assistant-dev-opensearch-access`, **Create policy**.

![Tên policy fitness-assistant-dev-opensearch-access và Create policy](/images/workshop/runbook/img222.jpg)

#### Bước 6 — Environment variable

**6.1 — Thêm biến** vào cả ba AI Lambda (**Configuration → Environment variables → Edit**), và xoá `QDRANT_HOST` / `QDRANT_PORT` nếu có:

```
VECTOR_STORE_PROVIDER=opensearch
OPENSEARCH_REGION=ap-southeast-1
OPENSEARCH_SERVERLESS_ENDPOINT=https://<collection-id>.aoss.ap-southeast-1.on.aws
KNOWLEDGE_VECTOR_SIZE=1024
```

Worker giữ `LLM_TIMEOUT_MS=180000`. Ảnh cho thấy ba dòng OpenSearch trên AI Lambda và nút **Save** (`KNOWLEDGE_VECTOR_SIZE` đã được đặt từ [5.4.8](../5.4.8-AI-Service-Core/)).

![VECTOR_STORE_PROVIDER, OPENSEARCH_REGION, OPENSEARCH_SERVERLESS_ENDPOINT và Save](/images/workshop/runbook/img223.jpg)

```
                 Amazon Bedrock
                /              \
          Nova Pro          Cohere Embed (1024)
                                 │
                                 ▼
                     OpenSearch Serverless (NextGen)
                                 ▲
                 ┌───────────────┼───────────────┐
            AI HTTP          AI Worker        AI Jobs
```

#### Bước 7 — Để code tự tạo index

Không có thao tác nào trên console. Collection hiện *Indexes: -* và vẫn như vậy: các index `exercises`, `fitness_knowledge`, `fitness_faq` và `fitness_evidence` được code khởi tạo ở lần dùng đầu tiên với đúng mapping nó cần — vector field `vector`, kiểu `knn_vector`, số chiều **1024**, engine `faiss`, method `hnsw`, space `cosinesimil`. Nếu index đã tồn tại với số chiều sai, code báo lỗi thay vì xoá dữ liệu.

#### Bước 8 — Scheduler role cho AI jobs

**8.1 — Chọn custom trust policy.** **IAM → Roles → Create role**, chọn **Custom trust policy** và dán statement với principal `scheduler.amazonaws.com`, action `sts:AssumeRole`.

![Custom trust policy đã chọn và JSON cho scheduler.amazonaws.com](/images/workshop/runbook/img224.jpg)

**8.2 — Đặt tên role.** `fitness-assistant-dev-ai-jobs-scheduler-role`, rồi **Create role**.

![Tên role fitness-assistant-dev-ai-jobs-scheduler-role](/images/workshop/runbook/img225.jpg)

**8.3 — Viết inline policy.** Trên role, **Add permissions → Create inline policy → JSON**: `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-ai-jobs`.

![JSON editor: lambda:InvokeFunction trên fitness-assistant-dev-ai-jobs](/images/workshop/runbook/img226.jpg)

**8.4 — Đặt tên và tạo.** `fitness-assistant-dev-invoke-ai-jobs`, **Create policy**.

![Tên policy fitness-assistant-dev-invoke-ai-jobs và Create policy](/images/workshop/runbook/img227.jpg)

#### Bước 9 — Năm schedule

**9.1 — Đặt tên schedule auto-accept.** **EventBridge → Schedules → Create schedule**: tên `fitness-assistant-dev-ai-autoaccept`, **Recurring schedule**, **Rate-based schedule**.

![Tên schedule, Recurring schedule và Rate-based schedule](/images/workshop/runbook/img228.jpg)

**9.2 — Đặt tần suất.** `15` `minutes`, flexible time window **Off**, rồi **Next**.

![Rate 15 phút, flexible window Off và Next](/images/workshop/runbook/img229.jpg)

**9.3 — Chọn target.** Bấm ô **AWS Lambda — Invoke**, chọn `fitness-assistant-dev-ai-jobs` và nhập payload `{"job": "personalized-service-autoaccept-sweep"}`.

![AWS Lambda Invoke, function ai-jobs và payload auto-accept](/images/workshop/runbook/img230.jpg)

**9.4 — Chọn settings.** Giữ schedule enabled, bật retry với maximum age `0` giờ `5` phút, `2` lần thử và DLQ **None**.

![Enable, retry 5 phút, 2 lần, DLQ None](/images/workshop/runbook/img231.jpg)

**9.5 — Chọn role.** **Use existing role**: `fitness-assistant-dev-ai-jobs-scheduler-role`, rồi **Next** và tạo schedule.

![Use existing role, AI jobs scheduler role và Next](/images/workshop/runbook/img232.jpg)

**9.6 — Tạo bốn schedule ban đêm** theo cách tương tự, nhưng dạng cron, time zone `Asia/Ho_Chi_Minh` để chạy vào ban đêm giờ Việt Nam:

| Schedule | Biểu thức | Payload |
|---|---|---|
| `fitness-assistant-dev-ai-local-evidence` | `cron(0 2 * * ? *)` | `{"job":"local-evidence-refresh"}` |
| `fitness-assistant-dev-ai-pubmed` | `cron(30 2 * * ? *)` | `{"job":"pubmed-refresh"}` |
| `fitness-assistant-dev-ai-rss` | `cron(0 3 * * ? *)` | `{"job":"rss-refresh"}` |
| `fitness-assistant-dev-ai-web` | `cron(30 3 * * ? *)` | `{"job":"web-refresh"}` |

*Runbook không có ảnh của bốn schedule cron.*

```
EventBridge Scheduler → AI Jobs Lambda → PubMed / RSS / Web / Local
   → Cohere Embed Multilingual v3 (1024) → OpenSearch Serverless → fitness_knowledge / fitness_evidence …
```

#### Bước 10 — Nối AI Lambda vào API Gateway

**10.1 — Tạo integration.** **API Gateway → fitness-assistant-dev-api → Integrations → Create**: **Lambda function**, region `ap-southeast-1`, chọn `fitness-assistant-dev-ai`, payload format `2.0`, giữ **Grant API Gateway permission to invoke your Lambda function**, rồi **Create**.

![Lambda function integration, payload 2.0 và Create](/images/workshop/runbook/img233.jpg)

**10.2 — Tạo và gắn tám route.**

```
ANY /ai            ANY /ai/{proxy+}
ANY /plans         ANY /plans/{proxy+}
ANY /marketplace   ANY /marketplace/{proxy+}
ANY /admin/ai      ANY /admin/ai/{proxy+}
```

Các greedy route bao phủ `POST /ai/ask`, `GET /ai/conversations`, `POST /ai/agent/goal-image`, `POST /plans/workout/generate`, `GET /plans/job/{id}`, `GET /admin/ai/overview` và các route khác. Route authorization giữ **NONE**: AI Lambda tự verify Bearer JWT qua Auth Lambda và từ chối header `x-user-id` / `x-user-role` giả mạo, nên thêm JWT authorizer của API Gateway sẽ tạo ra lớp auth thứ hai thiếu nhất quán. Không tạo `/internal/*`, `/metrics` và `/{proxy+}`.

**10.3 — Kiểm tra một route.** Ở **Attach integrations to routes**, chọn `ANY /admin/ai`; chi tiết phải hiện `fitness-assistant-dev-ai`.

![Route ANY /admin/ai được chọn, Lambda function fitness-assistant-dev-ai](/images/workshop/runbook/img234.jpg)

#### Bước 11 — Payment → AI

Sau khi thanh toán thành công, Payment kích hoạt dịch vụ cá nhân hoá bằng cách invoke endpoint nội bộ của AI Lambda `POST /internal/personalized-service/orders/:id/activate-after-payment` (idempotent, nên thử lại an toàn).

**11.1 — Thêm biến.** Thêm `AI_LAMBDA_NAME=fitness-assistant-dev-ai` vào cả `fitness-assistant-dev-payment` và `fitness-assistant-dev-payment-jobs`.

![AI_LAMBDA_NAME = fitness-assistant-dev-ai trên Payment Lambda](/images/workshop/runbook/img235.jpg)

**11.2 — Cho phép invoke.** Thêm vào Payment role:

```json
{
  "Sid": "InvokeAiService",
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-ai"
}
```

*Runbook không có ảnh của việc sửa policy.*

Không tạo public URL, route `/internal` hay Lambda Function URL cho việc này. Chuỗi gọi giờ là: người dùng → AI marketplace → Payment → provider → webhook/reconciliation → Payment Lambda → (direct invoke) AI Lambda → kích hoạt dịch vụ.

#### Bước 12 — Giới hạn tốc độ các route AI để bảo vệ chi phí Bedrock

Application gateway cũ giới hạn `/ai/ask` ở 20 request mỗi 60 giây, và AI Service không có ngân sách token theo từng user, nên nếu không giới hạn thì một lỗi frontend có thể gửi hàng trăm lời gọi Bedrock tốn tiền. Trong **API Gateway → `fitness-assistant-dev-api` → Stages → `$default` → route throttling**, chỉ giới hạn các route AI (không phải toàn bộ API):

| Route | Rate (req/s) | Burst |
|---|---|---|
| `ANY /ai`, `ANY /ai/{proxy+}` | 1 | 3 |
| `ANY /plans`, `ANY /plans/{proxy+}` | 1 | 3 |
| `ANY /marketplace`, `ANY /marketplace/{proxy+}` | 3 | 6 |
| `ANY /admin/ai`, `ANY /admin/ai/{proxy+}` | 1 | 3 |

*Runbook không có ảnh của cấu hình throttling.*

API Gateway dùng token bucket và trả **HTTP 429** khi vượt giới hạn; các giới hạn là mục tiêu best-effort chứ không phải trần cứng, và áp dụng theo route chứ không theo user. Frontend phải hiển thị thông báo "quá nhiều yêu cầu, hãy thử lại sau" kèm backoff thay vì thử lại liên tục. Cố ý không dùng usage plan / API key (tính năng của REST API) và Lambda reserved concurrency (sẽ throttle mọi route AI cùng lúc).

Đường đi AI đầy đủ giờ gồm: JWT → route throttling của API Gateway → AI HTTP Lambda (Auth, Aurora, Nova Pro, Cohere, OpenSearch, SQS) → AI Worker; EventBridge → AI Jobs → OpenSearch; Payment → endpoint nội bộ của AI.
