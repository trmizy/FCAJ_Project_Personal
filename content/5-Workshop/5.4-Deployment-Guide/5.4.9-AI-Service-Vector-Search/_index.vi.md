---
title: "5.4.9 AI Service — vector search, lịch chạy và API"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 5.4.9. </b> "
---

Stack local dùng Qdrant làm vector store. Để lên AWS, code được thêm một lớp abstraction cho vector store với implementation OpenSearch (58/58 test pass), nên production không còn cần `QDRANT_HOST` / `QDRANT_PORT`. Request tới OpenSearch được ký bằng SigV4 (service `aoss`) dùng IAM role của từng Lambda — không có username, password hay API key nào của OpenSearch.

#### Bước 1 — Upload lại ba AI Lambda

Bản build mới có OpenSearch client và hỗ trợ SigV4 (ZIP HTTP/Worker ≈ 36.325.814 byte), nên được upload trước, giữ nguyên handler:

| Function | Artifact | Handler |
|---|---|---|
| `fitness-assistant-dev-ai` | `ai-lambda.zip` | `dist/lambda.handler` |
| `fitness-assistant-dev-ai-worker` | `ai-worker-lambda.zip` | `dist/worker-lambda.handler` |
| `fitness-assistant-dev-ai-jobs` | `ai-lambda.zip` | `dist/jobs-lambda.handler` |

Thay đổi này không cần migration database.

#### Bước 2 — Collection group có scale-to-zero

**Amazon OpenSearch Service → Serverless → Collection groups → Create collection group**: generation **NextGen**, tên `fitness-assistant-dev-ai`, mô tả "Gymini AI vector search collection group".

![Tạo collection group fitness-assistant-dev-ai (NextGen)](/images/workshop/runbook/img207.jpg)

| Capacity | Tối thiểu | Tối đa |
|---|---|---|
| Indexing | **0 OCU** | 2 OCU |
| Search | **0 OCU** | 2 OCU |

Mức tối thiểu 0 bật scale-to-zero: sau khoảng 10 phút idle, indexing và search giảm về 0 OCU, và request đầu tiên sau đó có thể mất thêm 10–30 giây để "đánh thức". Khoảng 0–2 OCU hợp lý hơn nhiều cho DEV so với mức tối đa mặc định 96.

![Capacity: 0–2 OCU indexing và 0–2 OCU search](/images/workshop/runbook/img208.jpg)

![Đã tạo collection group: NextGen, 0/2 OCU](/images/workshop/runbook/img209.jpg)

#### Bước 3 — VPC endpoint private

**OpenSearch Service → Serverless → VPC endpoints → Create VPC endpoint**: VPC `fitness-assistant-dev-vpc`, subnet `private-app-a` và `private-app-b`. Runbook chỉ định dùng `fitness-assistant-dev-vpce-sg` có sẵn (TCP 443 từ Lambda SG); endpoint trong screenshot (`fitness-dev-opensearch-vpce`) đang gắn Lambda SG — security group nào được gắn thì cũng phải cho phép inbound TCP 443 từ Lambda security group. Chờ trạng thái **Available** và ghi lại endpoint ID (`vpce-…`, không phải endpoint URL).

![Trang VPC endpoints của OpenSearch Serverless](/images/workshop/runbook/img210.jpg)

![Endpoint fitness-dev-opensearch-vpce ở hai private app subnet](/images/workshop/runbook/img211.jpg)

#### Bước 4 — Vector search collection

**Serverless → Collections → Create collection**: NextGen, **Standard create** (không dùng Express — cần kiểm soát private networking và access policy), tên `fitness-assistant-dev-ai-vectors`, mô tả "Gymini AI vector store for RAG and knowledge retrieval", type **Vector search**, collection group `fitness-assistant-dev-ai`, key mã hoá do AWS sở hữu.

![Trang Collections](/images/workshop/runbook/img212.jpg)

![Collection fitness-assistant-dev-ai-vectors, type Vector search](/images/workshop/runbook/img213.jpg)

![Standard create trong collection group có sẵn](/images/workshop/runbook/img214.jpg)

Networking: access type **Private**, qua VPC endpoint ở trên — không có public access.

![Truy cập private qua VPC endpoint](/images/workshop/runbook/img215.jpg)

Data access: **Create as a new data access policy** tên `fitness-dev-ai-vector-access`, định nghĩa bằng **JSON** thay vì tick quyền trong visual editor:

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

`aoss:DeleteIndex` cố ý không được cấp.

![Data access policy fitness-dev-ai-vector-access, định nghĩa bằng JSON](/images/workshop/runbook/img216.jpg)

![JSON của data access policy](/images/workshop/runbook/img217.jpg)

Wizard cũng tạo một OpenSearch application (`aoss-fitness-dev-ai`) và workspace để xem dữ liệu, quyền admin chỉ cấp cho IAM principal của account.

![OpenSearch application và workspace](/images/workshop/runbook/img218.jpg)

![Admin của application](/images/workshop/runbook/img219.jpg)

![Đang tạo collection](/images/workshop/runbook/img220.jpg)

Khi collection chuyển sang **Active**, copy **ARN** (cho IAM) và **OpenSearch endpoint** (`https://<collection-id>.aoss.ap-southeast-1.on.aws`, cho Lambda) bằng nút copy của console. Không tạo index bằng tay.

#### Bước 5 — Quyền IAM cho cả ba AI role

Data access policy và IAM là hai lớp quyền tách biệt; thiếu một trong hai đều trả về 403. Thêm inline policy `fitness-assistant-dev-opensearch-access` vào **từng** role `fitness-assistant-dev-ai-lambda-role`, `-ai-worker-role` và `-ai-jobs-role`:

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

Không dùng: `AmazonOpenSearchServerlessFullAccess`, `aoss:DashboardsAccessAll`, `aoss:*` — Lambda chỉ cần data-plane API.

![aoss:APIAccessAll giới hạn trong ARN collection](/images/workshop/runbook/img221.jpg)

![Tên policy fitness-assistant-dev-opensearch-access](/images/workshop/runbook/img222.jpg)

#### Bước 6 — Environment variable

Thêm vào cả ba AI Lambda (và xoá `QDRANT_HOST` / `QDRANT_PORT` nếu có):

```
VECTOR_STORE_PROVIDER=opensearch
OPENSEARCH_REGION=ap-southeast-1
OPENSEARCH_SERVERLESS_ENDPOINT=https://<collection-id>.aoss.ap-southeast-1.on.aws
KNOWLEDGE_VECTOR_SIZE=1024
```

Worker giữ `LLM_TIMEOUT_MS=180000`.

![Environment variable OpenSearch trên AI Lambda](/images/workshop/runbook/img223.jpg)

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

Collection hiện *Indexes: -* và cứ để như vậy: các index `exercises`, `fitness_knowledge`, `fitness_faq` và `fitness_evidence` được code bootstrap ở lần dùng đầu tiên với đúng mapping cần thiết — vector field `vector`, type `knn_vector`, dimension **1024**, engine `faiss`, method `hnsw`, space `cosinesimil`. Nếu một index tồn tại với số chiều sai, code báo lỗi thay vì xoá dữ liệu.

#### Bước 8 — Scheduler role cho AI jobs

Custom trust policy cho `scheduler.amazonaws.com`, role `fitness-assistant-dev-ai-jobs-scheduler-role`, inline policy `fitness-assistant-dev-invoke-ai-jobs` với `lambda:InvokeFunction` chỉ trên `fitness-assistant-dev-ai-jobs`.

![Custom trust policy cho EventBridge Scheduler](/images/workshop/runbook/img224.jpg)

![Role fitness-assistant-dev-ai-jobs-scheduler-role](/images/workshop/runbook/img225.jpg)

![Inline policy cho AI jobs Lambda](/images/workshop/runbook/img226.jpg)

![Tên policy fitness-assistant-dev-invoke-ai-jobs](/images/workshop/runbook/img227.jpg)

#### Bước 9 — Năm schedule

Schedule auto-accept: `fitness-assistant-dev-ai-autoaccept`, `rate(15 minutes)`, payload `{"job": "personalized-service-autoaccept-sweep"}`, enabled, dùng AI jobs scheduler role.

![Schedule fitness-assistant-dev-ai-autoaccept](/images/workshop/runbook/img228.jpg)

![rate(15 minutes), tắt flexible window](/images/workshop/runbook/img229.jpg)

![Target fitness-assistant-dev-ai-jobs với payload auto-accept](/images/workshop/runbook/img230.jpg)

![Retry policy và DLQ](/images/workshop/runbook/img231.jpg)

![Existing role fitness-assistant-dev-ai-jobs-scheduler-role](/images/workshop/runbook/img232.jpg)

Tiếp theo là bốn schedule nạp tri thức hằng đêm (cron-based, time zone `Asia/Ho_Chi_Minh` để chạy ban đêm theo giờ Việt Nam):

| Schedule | Biểu thức | Payload |
|---|---|---|
| `fitness-assistant-dev-ai-local-evidence` | `cron(0 2 * * ? *)` | `{"job":"local-evidence-refresh"}` |
| `fitness-assistant-dev-ai-pubmed` | `cron(30 2 * * ? *)` | `{"job":"pubmed-refresh"}` |
| `fitness-assistant-dev-ai-rss` | `cron(0 3 * * ? *)` | `{"job":"rss-refresh"}` |
| `fitness-assistant-dev-ai-web` | `cron(30 3 * * ? *)` | `{"job":"web-refresh"}` |

```
EventBridge Scheduler → AI Jobs Lambda → PubMed / RSS / Web / Local
   → Cohere Embed Multilingual v3 (1024) → OpenSearch Serverless → fitness_knowledge / fitness_evidence …
```

#### Bước 10 — Nối AI Lambda vào API Gateway

Tạo Lambda integration `fitness-assistant-dev-ai` (payload 2.0) và tám route:

```
ANY /ai            ANY /ai/{proxy+}
ANY /plans         ANY /plans/{proxy+}
ANY /marketplace   ANY /marketplace/{proxy+}
ANY /admin/ai      ANY /admin/ai/{proxy+}
```

Các greedy route bao phủ `POST /ai/ask`, `GET /ai/conversations`, `POST /ai/agent/goal-image`, `POST /plans/workout/generate`, `GET /plans/job/{id}`, `GET /admin/ai/overview`, v.v. Authorization của route để **NONE**: AI Lambda tự verify Bearer JWT qua Auth Lambda và từ chối header `x-user-id` / `x-user-role` giả mạo, nên thêm JWT authorizer ở API Gateway sẽ tạo ra lớp xác thực thứ hai không nhất quán. Không tạo `/internal/*`, `/metrics` và `/{proxy+}`.

![Lambda integration cho fitness-assistant-dev-ai](/images/workshop/runbook/img233.jpg)

![Route AI đã gắn vào integration](/images/workshop/runbook/img234.jpg)

#### Bước 11 — Payment → AI

Sau khi thanh toán thành công, Payment kích hoạt dịch vụ cá nhân hoá bằng cách invoke endpoint nội bộ của AI Lambda `POST /internal/personalized-service/orders/:id/activate-after-payment` (idempotent, nên retry an toàn). Thêm `AI_LAMBDA_NAME=fitness-assistant-dev-ai` vào cả `fitness-assistant-dev-payment` và `fitness-assistant-dev-payment-jobs`, và thêm vào Payment role:

```json
{
  "Sid": "InvokeAiService",
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-ai"
}
```

![AI_LAMBDA_NAME trên Payment Lambda](/images/workshop/runbook/img235.jpg)

Không cần public URL, route `/internal` hay Lambda Function URL cho việc này. Chuỗi lúc này là: người dùng → AI marketplace → Payment → provider → webhook/reconciliation → Payment Lambda → (direct invoke) AI Lambda → kích hoạt dịch vụ.

#### Bước 12 — Rate limit các route AI để bảo vệ chi phí Bedrock

Application gateway cũ giới hạn `/ai/ask` ở 20 request mỗi 60 giây, và AI Service không có ngân sách token theo người dùng, nên nếu không giới hạn, một bug frontend có thể gửi hàng trăm lời gọi Bedrock tính phí. Trong **API Gateway → `fitness-assistant-dev-api` → Stages → `$default` → route throttling**, chỉ giới hạn các route AI (không giới hạn toàn API):

| Route | Rate (req/giây) | Burst |
|---|---|---|
| `ANY /ai`, `ANY /ai/{proxy+}` | 1 | 3 |
| `ANY /plans`, `ANY /plans/{proxy+}` | 1 | 3 |
| `ANY /marketplace`, `ANY /marketplace/{proxy+}` | 3 | 6 |
| `ANY /admin/ai`, `ANY /admin/ai/{proxy+}` | 1 | 3 |

API Gateway dùng token bucket và trả **HTTP 429** khi vượt giới hạn; đây là mục tiêu best-effort chứ không phải trần cứng, và áp dụng theo route chứ không theo người dùng. Frontend phải hiển thị thông báo "quá nhiều yêu cầu, vui lòng thử lại sau" kèm backoff thay vì retry liên tục. Usage plan / API key (tính năng của REST API) và Lambda reserved concurrency (sẽ bóp toàn bộ route AI cùng lúc) cố ý không dùng.

Toàn bộ đường đi AI lúc này có: JWT → route throttling ở API Gateway → AI HTTP Lambda (Auth, Aurora, Nova Pro, Cohere, OpenSearch, SQS) → AI Worker; EventBridge → AI Jobs → OpenSearch; Payment → endpoint nội bộ của AI.
