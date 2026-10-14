---
title: "5.4.9 AI Service — vector search, scheduling and API"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 5.4.9. </b> "
---

The local development stack used Qdrant as the vector store. For AWS, the code was given a vector-store abstraction with an OpenSearch implementation (58/58 tests passing), so production no longer needs `QDRANT_HOST` / `QDRANT_PORT`. Requests to OpenSearch are signed with SigV4 (service `aoss`) using each Lambda's IAM role — there is no OpenSearch username, password or API key.

#### Step 1 — Re-upload the three AI Lambdas

The new build includes the OpenSearch client and SigV4 support (HTTP/Worker ZIP ≈ 36,325,814 bytes), so it is uploaded first, keeping each handler:

| Function | Artifact | Handler |
|---|---|---|
| `fitness-assistant-dev-ai` | `ai-lambda.zip` | `dist/lambda.handler` |
| `fitness-assistant-dev-ai-worker` | `ai-worker-lambda.zip` | `dist/worker-lambda.handler` |
| `fitness-assistant-dev-ai-jobs` | `ai-lambda.zip` | `dist/jobs-lambda.handler` |

No database migration is required for this change.

#### Step 2 — Collection group with scale-to-zero

**Amazon OpenSearch Service → Serverless → Collection groups → Create collection group**: generation **NextGen**, name `fitness-assistant-dev-ai`, description "Gymini AI vector search collection group".

![Create collection group fitness-assistant-dev-ai (NextGen)](/images/workshop/runbook/img207.jpg)

| Capacity | Min | Max |
|---|---|---|
| Indexing | **0 OCU** | 2 OCU |
| Search | **0 OCU** | 2 OCU |

A minimum of 0 enables scale-to-zero: after about 10 idle minutes indexing and search drop to 0 OCU, and the first request after that can take an extra 10–30 seconds to wake up. A 0–2 OCU range is far more sensible for DEV than the default maximum of 96.

![Capacity: 0–2 indexing OCU and 0–2 search OCU](/images/workshop/runbook/img208.jpg)

![Collection group created: NextGen, 0/2 OCU](/images/workshop/runbook/img209.jpg)

#### Step 3 — Private VPC endpoint

**OpenSearch Service → Serverless → VPC endpoints → Create VPC endpoint**: VPC `fitness-assistant-dev-vpc`, subnets `private-app-a` and `private-app-b`. The runbook specifies the existing `fitness-assistant-dev-vpce-sg` (TCP 443 from the Lambda SG); the endpoint captured below (`fitness-dev-opensearch-vpce`) shows the Lambda SG attached — whichever group is attached must allow inbound TCP 443 from the Lambda security group. Wait for **Available** and note the endpoint ID (`vpce-…`, not the endpoint URL).

![VPC endpoints page for OpenSearch Serverless](/images/workshop/runbook/img210.jpg)

![Endpoint fitness-dev-opensearch-vpce in both private app subnets](/images/workshop/runbook/img211.jpg)

#### Step 4 — Vector search collection

**Serverless → Collections → Create collection**: NextGen, **Standard create** (not Express — private networking and access policies must be controlled), name `fitness-assistant-dev-ai-vectors`, description "Gymini AI vector store for RAG and knowledge retrieval", type **Vector search**, collection group `fitness-assistant-dev-ai`, AWS-owned encryption key.

![Collections page](/images/workshop/runbook/img212.jpg)

![Collection fitness-assistant-dev-ai-vectors, type Vector search](/images/workshop/runbook/img213.jpg)

![Standard create in the existing collection group](/images/workshop/runbook/img214.jpg)

Networking: access type **Private**, through the VPC endpoint above — no public access.

![Private access through the VPC endpoint](/images/workshop/runbook/img215.jpg)

Data access: **Create as a new data access policy** named `fitness-dev-ai-vector-access`, defined as **JSON** rather than ticking permissions in the visual editor:

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

`aoss:DeleteIndex` is deliberately not granted.

![Data access policy fitness-dev-ai-vector-access, defined as JSON](/images/workshop/runbook/img216.jpg)

![Data access policy JSON](/images/workshop/runbook/img217.jpg)

The wizard also creates an OpenSearch application (`aoss-fitness-dev-ai`) and workspace for browsing the data, with administrator permission limited to the account's IAM principal.

![OpenSearch application and workspace](/images/workshop/runbook/img218.jpg)

![Application administrators](/images/workshop/runbook/img219.jpg)

![Creating the collection](/images/workshop/runbook/img220.jpg)

When the collection is **Active**, copy its **ARN** (for IAM) and **OpenSearch endpoint** (`https://<collection-id>.aoss.ap-southeast-1.on.aws`, for the Lambdas) with the console's copy buttons. Indexes are not created by hand.

#### Step 5 — IAM permission on all three AI roles

The data access policy and IAM are two separate layers; missing either one returns 403. Add the inline policy `fitness-assistant-dev-opensearch-access` to **each** of `fitness-assistant-dev-ai-lambda-role`, `-ai-worker-role` and `-ai-jobs-role`:

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

Not used: `AmazonOpenSearchServerlessFullAccess`, `aoss:DashboardsAccessAll`, `aoss:*` — the Lambdas only need the data-plane API.

![aoss:APIAccessAll limited to the collection ARN](/images/workshop/runbook/img221.jpg)

![Policy name fitness-assistant-dev-opensearch-access](/images/workshop/runbook/img222.jpg)

#### Step 6 — Environment variables

Add to all three AI Lambdas (and remove `QDRANT_HOST` / `QDRANT_PORT` if present):

```
VECTOR_STORE_PROVIDER=opensearch
OPENSEARCH_REGION=ap-southeast-1
OPENSEARCH_SERVERLESS_ENDPOINT=https://<collection-id>.aoss.ap-southeast-1.on.aws
KNOWLEDGE_VECTOR_SIZE=1024
```

The Worker keeps `LLM_TIMEOUT_MS=180000`.

![OpenSearch environment variables on the AI Lambda](/images/workshop/runbook/img223.jpg)

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

#### Step 7 — Let the code create the indexes

The collection shows *Indexes: -* and stays that way: the indexes `exercises`, `fitness_knowledge`, `fitness_faq` and `fitness_evidence` are bootstrapped by the code on first use with the exact mapping it expects — vector field `vector`, type `knn_vector`, dimension **1024**, engine `faiss`, method `hnsw`, space `cosinesimil`. If an index exists with the wrong dimension the code fails instead of deleting data.

#### Step 8 — Scheduler role for the AI jobs

Custom trust policy for `scheduler.amazonaws.com`, role `fitness-assistant-dev-ai-jobs-scheduler-role`, inline policy `fitness-assistant-dev-invoke-ai-jobs` with `lambda:InvokeFunction` on `fitness-assistant-dev-ai-jobs` only.

![Custom trust policy for EventBridge Scheduler](/images/workshop/runbook/img224.jpg)

![Role fitness-assistant-dev-ai-jobs-scheduler-role](/images/workshop/runbook/img225.jpg)

![Inline policy for the AI jobs Lambda](/images/workshop/runbook/img226.jpg)

![Policy name fitness-assistant-dev-invoke-ai-jobs](/images/workshop/runbook/img227.jpg)

#### Step 9 — Five schedules

The auto-accept schedule: `fitness-assistant-dev-ai-autoaccept`, `rate(15 minutes)`, payload `{"job": "personalized-service-autoaccept-sweep"}`, enabled, the AI jobs scheduler role.

![Schedule fitness-assistant-dev-ai-autoaccept](/images/workshop/runbook/img228.jpg)

![rate(15 minutes), flexible window off](/images/workshop/runbook/img229.jpg)

![Target fitness-assistant-dev-ai-jobs with the auto-accept payload](/images/workshop/runbook/img230.jpg)

![Retry policy and DLQ settings](/images/workshop/runbook/img231.jpg)

![Existing role fitness-assistant-dev-ai-jobs-scheduler-role](/images/workshop/runbook/img232.jpg)

Then four nightly knowledge-ingestion schedules (cron-based, time zone `Asia/Ho_Chi_Minh` so they run at night Vietnam time):

| Schedule | Expression | Payload |
|---|---|---|
| `fitness-assistant-dev-ai-local-evidence` | `cron(0 2 * * ? *)` | `{"job":"local-evidence-refresh"}` |
| `fitness-assistant-dev-ai-pubmed` | `cron(30 2 * * ? *)` | `{"job":"pubmed-refresh"}` |
| `fitness-assistant-dev-ai-rss` | `cron(0 3 * * ? *)` | `{"job":"rss-refresh"}` |
| `fitness-assistant-dev-ai-web` | `cron(30 3 * * ? *)` | `{"job":"web-refresh"}` |

```
EventBridge Scheduler → AI Jobs Lambda → PubMed / RSS / Web / Local
   → Cohere Embed Multilingual v3 (1024) → OpenSearch Serverless → fitness_knowledge / fitness_evidence …
```

#### Step 10 — Connect the AI Lambda to API Gateway

Create the Lambda integration `fitness-assistant-dev-ai` (payload 2.0) and eight routes:

```
ANY /ai            ANY /ai/{proxy+}
ANY /plans         ANY /plans/{proxy+}
ANY /marketplace   ANY /marketplace/{proxy+}
ANY /admin/ai      ANY /admin/ai/{proxy+}
```

The greedy routes cover `POST /ai/ask`, `GET /ai/conversations`, `POST /ai/agent/goal-image`, `POST /plans/workout/generate`, `GET /plans/job/{id}`, `GET /admin/ai/overview` and so on. Route authorization stays **NONE**: the AI Lambda verifies the Bearer JWT itself through the Auth Lambda and rejects spoofed `x-user-id` / `x-user-role` headers, so adding an API Gateway JWT authorizer would create a second, inconsistent auth layer. `/internal/*`, `/metrics` and `/{proxy+}` are not created.

![Lambda integration for fitness-assistant-dev-ai](/images/workshop/runbook/img233.jpg)

![AI routes attached to the integration](/images/workshop/runbook/img234.jpg)

#### Step 11 — Payment → AI

After a successful payment, Payment activates the personalized service by invoking the AI Lambda's internal endpoint `POST /internal/personalized-service/orders/:id/activate-after-payment` (idempotent, so retries are safe). Add `AI_LAMBDA_NAME=fitness-assistant-dev-ai` to both `fitness-assistant-dev-payment` and `fitness-assistant-dev-payment-jobs`, and add to the Payment role:

```json
{
  "Sid": "InvokeAiService",
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-ai"
}
```

![AI_LAMBDA_NAME on the Payment Lambda](/images/workshop/runbook/img235.jpg)

No public URL, `/internal` route or Lambda Function URL is created for this. The chain is now: user → AI marketplace → Payment → provider → webhook/reconciliation → Payment Lambda → (direct invoke) AI Lambda → activate service.

#### Step 12 — Rate-limit the AI routes to protect Bedrock cost

The old application gateway limited `/ai/ask` to 20 requests per 60 seconds, and the AI Service has no per-user token budget, so without a limit a frontend bug could send hundreds of billable Bedrock calls. In **API Gateway → `fitness-assistant-dev-api` → Stages → `$default` → route throttling**, limit only the AI routes (not the whole API):

| Route | Rate (req/s) | Burst |
|---|---|---|
| `ANY /ai`, `ANY /ai/{proxy+}` | 1 | 3 |
| `ANY /plans`, `ANY /plans/{proxy+}` | 1 | 3 |
| `ANY /marketplace`, `ANY /marketplace/{proxy+}` | 3 | 6 |
| `ANY /admin/ai`, `ANY /admin/ai/{proxy+}` | 1 | 3 |

API Gateway uses a token bucket and returns **HTTP 429** when the limit is exceeded; the limits are best-effort targets, not hard ceilings, and they apply per route, not per user. The frontend must show a "too many requests, try again later" message with backoff instead of retrying in a loop. Usage plans / API keys (a REST API feature) and Lambda reserved concurrency (which would throttle all AI routes together) are deliberately not used.

The full AI path now has: JWT → API Gateway route throttling → AI HTTP Lambda (Auth, Aurora, Nova Pro, Cohere, OpenSearch, SQS) → AI Worker; EventBridge → AI Jobs → OpenSearch; Payment → AI internal endpoint.
