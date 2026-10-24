---
title: "AI Service — vector search, scheduling and API"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 5.4.9. </b> "
---

The local development stack used Qdrant as the vector store. For AWS, the code was given a vector-store abstraction with an OpenSearch implementation (58/58 tests passing), so production no longer needs `QDRANT_HOST` / `QDRANT_PORT`. Requests to OpenSearch are signed with SigV4 (service `aoss`) using each Lambda's IAM role — there is no OpenSearch username, password or API key.

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

#### Step 1 — Re-upload the three AI Lambdas

The new build includes the OpenSearch client and SigV4 support (HTTP/Worker ZIP ≈ 36,325,814 bytes), so it is uploaded first, keeping each handler. For each function use **Code → Upload from → .zip file** (or S3) and click **Update**:

| Function | Artifact | Handler |
|---|---|---|
| `fitness-assistant-dev-ai` | `ai-lambda.zip` | `dist/lambda.handler` |
| `fitness-assistant-dev-ai-worker` | `ai-worker-lambda.zip` | `dist/worker-lambda.handler` |
| `fitness-assistant-dev-ai-jobs` | `ai-lambda.zip` | `dist/jobs-lambda.handler` |

No database migration is required for this change.

*The runbook has no screenshot of this re-upload; the dialog is the same as in [5.4.8 Step 6.2](../5.4.8-AI-Service-Core/).*

#### Step 2 — Collection group with scale-to-zero

**2.1 — Name the group.** **Amazon OpenSearch Service → Serverless → Collection groups → Create collection group**: name `fitness-assistant-dev-ai`, generation **NextGen**, description "Gymini AI vector search collection group".

![Collection group name, NextGen badge and the description](/images/workshop/runbook/img207.jpg)

**2.2 — Set the capacity.** Scroll to **Capacity management** and set:

| Capacity | Min | Max |
|---|---|---|
| Indexing | **0 OCU** | 2 OCU |
| Search | **0 OCU** | 2 OCU |

Then click **Create**. A minimum of 0 enables scale-to-zero: after about 10 idle minutes indexing and search drop to 0 OCU, and the first request after that can take an extra 10–30 seconds to wake up. A 0–2 OCU range is far more sensible for DEV than the default maximum of 96.

![Minimum and maximum indexing and search OCUs, Create](/images/workshop/runbook/img208.jpg)

**2.3 — Check the group.** The list must show `fitness-assistant-dev-ai`, NextGen, indexing 0 / 2 OCUs and search 0 / 2 OCUs.

![Collection group row: NextGen, 0 / 2 OCUs](/images/workshop/runbook/img209.jpg)

#### Step 3 — Private VPC endpoint

**3.1 — Open the VPC endpoints page.** **OpenSearch Service → Serverless → VPC endpoints** and click **Create VPC endpoint**. The page itself warns that it manages endpoints for **Classic** collections and that NextGen collections use the Amazon EC2 VPC endpoints console — keep that in mind if the endpoint does not show up in the NextGen collection later.

![VPC endpoints page and the Create VPC endpoint button](/images/workshop/runbook/img210.jpg)

**3.2 — Fill in the endpoint.** Name `fitness-dev-opensearch-vpce`, VPC `fitness-assistant-dev-vpc`, subnets `private-app-a` and `private-app-b`. The runbook specifies the existing `fitness-assistant-dev-vpce-sg` (TCP 443 from the Lambda SG); the endpoint captured below shows the Lambda SG attached — whichever group is attached must allow inbound TCP 443 from the Lambda security group. Wait for **Available** (the screenshot was taken while it was still **Pending**) and note the endpoint ID (`vpce-…`, not the endpoint URL).

![Endpoint ID, both private app subnets and the attached security group (status Pending)](/images/workshop/runbook/img211.jpg)

#### Step 4 — Vector search collection

**4.1 — Start the collection.** **Serverless → Collections → Create collection**.

![Collections page with no collections and the Create collection button](/images/workshop/runbook/img212.jpg)

**4.2 — Name it and choose the type.** NextGen, name `fitness-assistant-dev-ai-vectors`, description "Gymini AI vector store for RAG and knowledge retrieval", collection type **Vector search**.

![Collection name, description and Vector search type](/images/workshop/runbook/img213.jpg)

**4.3 — Choose Standard create and the group.** Choose **Standard create** (not Express — private networking and access policies must be controlled), **Select existing collection group** and pick `fitness-assistant-dev-ai`.

![Standard create, existing collection group fitness-assistant-dev-ai](/images/workshop/runbook/img214.jpg)

**4.4 — Network access.** Keep the AWS-owned encryption key, choose access type **Private (recommended)**, tick **VPC endpoints for access** and select the endpoint from Step 3 — no public access.

![Private access with the VPC endpoint selected](/images/workshop/runbook/img215.jpg)

**4.5 — Data access policy, part 1.** **Create as a new data access policy**, name `fitness-dev-ai-vector-access`, definition method **JSON** rather than ticking permissions in the visual editor.

![Create a new data access policy, its name and the JSON method](/images/workshop/runbook/img216.jpg)

**4.6 — Data access policy, part 2.** Paste the JSON:

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

![JSON editor holding the data access policy](/images/workshop/runbook/img217.jpg)

**4.7 — OpenSearch UI.** The wizard also creates an OpenSearch application and workspace for browsing the data: **Create new OpenSearch application** `aoss-fitness-dev-ai` and **Create new workspace** `fitness-dev-ai-vectors`.

![New application aoss-fitness-dev-ai and new workspace fitness-dev-ai-vectors](/images/workshop/runbook/img218.jpg)

**4.8 — Administrators and creation.** Leave IAM Identity Center unticked, grant administrator permission to the account's IAM principal only, then click **Create collection**.

![Application administrators and the Create collection button](/images/workshop/runbook/img219.jpg)

**4.9 — Wait for creation.** The page shows "Creating collection"; do not navigate away until the collection details page appears.

![Important notice: creating OpenSearch Serverless resources](/images/workshop/runbook/img220.jpg)

When the collection is **Active**, copy its **ARN** (for IAM) and **OpenSearch endpoint** (`https://<collection-id>.aoss.ap-southeast-1.on.aws`, for the Lambdas) with the console's copy buttons. Indexes are not created by hand.

#### Step 5 — IAM permission on all three AI roles

The data access policy and IAM are two separate layers; missing either one returns 403. Do the two sub-steps below for **each** of `fitness-assistant-dev-ai-lambda-role`, `-ai-worker-role` and `-ai-jobs-role` (the screenshots show the first one).

**5.1 — Paste the policy.** **IAM → Roles → the role → Add permissions → Create inline policy → JSON**:

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

**5.2 — Name and create it.** `fitness-assistant-dev-opensearch-access`, **Create policy**.

![Policy name fitness-assistant-dev-opensearch-access and Create policy](/images/workshop/runbook/img222.jpg)

#### Step 6 — Environment variables

**6.1 — Add the variables** on all three AI Lambdas (**Configuration → Environment variables → Edit**), and remove `QDRANT_HOST` / `QDRANT_PORT` if present:

```
VECTOR_STORE_PROVIDER=opensearch
OPENSEARCH_REGION=ap-southeast-1
OPENSEARCH_SERVERLESS_ENDPOINT=https://<collection-id>.aoss.ap-southeast-1.on.aws
KNOWLEDGE_VECTOR_SIZE=1024
```

The Worker keeps `LLM_TIMEOUT_MS=180000`. The screenshot shows the three OpenSearch rows on the AI Lambda and the **Save** button (`KNOWLEDGE_VECTOR_SIZE` was already set in [5.4.8](../5.4.8-AI-Service-Core/)).

![VECTOR_STORE_PROVIDER, OPENSEARCH_REGION, OPENSEARCH_SERVERLESS_ENDPOINT and Save](/images/workshop/runbook/img223.jpg)

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

No action in the console. The collection shows *Indexes: -* and stays that way: the indexes `exercises`, `fitness_knowledge`, `fitness_faq` and `fitness_evidence` are bootstrapped by the code on first use with the exact mapping it expects — vector field `vector`, type `knn_vector`, dimension **1024**, engine `faiss`, method `hnsw`, space `cosinesimil`. If an index exists with the wrong dimension the code fails instead of deleting data.

#### Step 8 — Scheduler role for the AI jobs

**8.1 — Choose the custom trust policy.** **IAM → Roles → Create role**, choose **Custom trust policy** and paste a statement with principal `scheduler.amazonaws.com` and action `sts:AssumeRole`.

![Custom trust policy selected and its JSON for scheduler.amazonaws.com](/images/workshop/runbook/img224.jpg)

**8.2 — Name the role.** `fitness-assistant-dev-ai-jobs-scheduler-role`, then **Create role**.

![Role name fitness-assistant-dev-ai-jobs-scheduler-role](/images/workshop/runbook/img225.jpg)

**8.3 — Write the inline policy.** On the role, **Add permissions → Create inline policy → JSON**: `lambda:InvokeFunction` on `fitness-assistant-dev-ai-jobs` only.

![JSON editor: lambda:InvokeFunction on fitness-assistant-dev-ai-jobs](/images/workshop/runbook/img226.jpg)

**8.4 — Name and create it.** `fitness-assistant-dev-invoke-ai-jobs`, **Create policy**.

![Policy name fitness-assistant-dev-invoke-ai-jobs and Create policy](/images/workshop/runbook/img227.jpg)

#### Step 9 — Five schedules

**9.1 — Name the auto-accept schedule.** **EventBridge → Schedules → Create schedule**: name `fitness-assistant-dev-ai-autoaccept`, **Recurring schedule**, **Rate-based schedule**.

![Schedule name, Recurring schedule and Rate-based schedule](/images/workshop/runbook/img228.jpg)

**9.2 — Set the rate.** `15` `minutes`, flexible time window **Off**, then **Next**.

![Rate 15 minutes, flexible window Off and Next](/images/workshop/runbook/img229.jpg)

**9.3 — Choose the target.** Click the **AWS Lambda — Invoke** tile, pick `fitness-assistant-dev-ai-jobs` and enter the payload `{"job": "personalized-service-autoaccept-sweep"}`.

![AWS Lambda Invoke, function ai-jobs and the auto-accept payload](/images/workshop/runbook/img230.jpg)

**9.4 — Choose the settings.** Keep the schedule enabled, retry on with maximum age `0` hours `5` minutes, `2` retry attempts and DLQ **None**.

![Enable, retry 5 minutes, 2 attempts, DLQ None](/images/workshop/runbook/img231.jpg)

**9.5 — Choose the role.** **Use existing role**: `fitness-assistant-dev-ai-jobs-scheduler-role`, then **Next** and create the schedule.

![Use existing role, the AI jobs scheduler role and Next](/images/workshop/runbook/img232.jpg)

**9.6 — Create the four nightly schedules** the same way, but cron-based, time zone `Asia/Ho_Chi_Minh` so they run at night Vietnam time:

| Schedule | Expression | Payload |
|---|---|---|
| `fitness-assistant-dev-ai-local-evidence` | `cron(0 2 * * ? *)` | `{"job":"local-evidence-refresh"}` |
| `fitness-assistant-dev-ai-pubmed` | `cron(30 2 * * ? *)` | `{"job":"pubmed-refresh"}` |
| `fitness-assistant-dev-ai-rss` | `cron(0 3 * * ? *)` | `{"job":"rss-refresh"}` |
| `fitness-assistant-dev-ai-web` | `cron(30 3 * * ? *)` | `{"job":"web-refresh"}` |

*The runbook has no screenshots of the four cron schedules.*

```
EventBridge Scheduler → AI Jobs Lambda → PubMed / RSS / Web / Local
   → Cohere Embed Multilingual v3 (1024) → OpenSearch Serverless → fitness_knowledge / fitness_evidence …
```

#### Step 10 — Connect the AI Lambda to API Gateway

**10.1 — Create the integration.** **API Gateway → fitness-assistant-dev-api → Integrations → Create**: **Lambda function**, region `ap-southeast-1`, pick `fitness-assistant-dev-ai`, payload format `2.0`, keep **Grant API Gateway permission to invoke your Lambda function**, then **Create**.

![Lambda function integration, payload 2.0 and Create](/images/workshop/runbook/img233.jpg)

**10.2 — Create and attach eight routes.**

```
ANY /ai            ANY /ai/{proxy+}
ANY /plans         ANY /plans/{proxy+}
ANY /marketplace   ANY /marketplace/{proxy+}
ANY /admin/ai      ANY /admin/ai/{proxy+}
```

The greedy routes cover `POST /ai/ask`, `GET /ai/conversations`, `POST /ai/agent/goal-image`, `POST /plans/workout/generate`, `GET /plans/job/{id}`, `GET /admin/ai/overview` and so on. Route authorization stays **NONE**: the AI Lambda verifies the Bearer JWT itself through the Auth Lambda and rejects spoofed `x-user-id` / `x-user-role` headers, so adding an API Gateway JWT authorizer would create a second, inconsistent auth layer. `/internal/*`, `/metrics` and `/{proxy+}` are not created.

**10.3 — Check one route.** Under **Attach integrations to routes**, select `ANY /admin/ai`; the details must show `fitness-assistant-dev-ai`.

![Route ANY /admin/ai selected, Lambda function fitness-assistant-dev-ai](/images/workshop/runbook/img234.jpg)

#### Step 11 — Payment → AI

After a successful payment, Payment activates the personalized service by invoking the AI Lambda's internal endpoint `POST /internal/personalized-service/orders/:id/activate-after-payment` (idempotent, so retries are safe).

**11.1 — Add the variable.** Add `AI_LAMBDA_NAME=fitness-assistant-dev-ai` to both `fitness-assistant-dev-payment` and `fitness-assistant-dev-payment-jobs`.

![AI_LAMBDA_NAME = fitness-assistant-dev-ai on the Payment Lambda](/images/workshop/runbook/img235.jpg)

**11.2 — Allow the invoke.** Add to the Payment role:

```json
{
  "Sid": "InvokeAiService",
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-ai"
}
```

*The runbook has no screenshot of the policy edit.*

No public URL, `/internal` route or Lambda Function URL is created for this. The chain is now: user → AI marketplace → Payment → provider → webhook/reconciliation → Payment Lambda → (direct invoke) AI Lambda → activate service.

#### Step 12 — Rate-limit the AI routes to protect Bedrock cost

The old application gateway limited `/ai/ask` to 20 requests per 60 seconds, and the AI Service has no per-user token budget, so without a limit a frontend bug could send hundreds of billable Bedrock calls. In **API Gateway → `fitness-assistant-dev-api` → Stages → `$default` → route throttling**, limit only the AI routes (not the whole API):

| Route | Rate (req/s) | Burst |
|---|---|---|
| `ANY /ai`, `ANY /ai/{proxy+}` | 1 | 3 |
| `ANY /plans`, `ANY /plans/{proxy+}` | 1 | 3 |
| `ANY /marketplace`, `ANY /marketplace/{proxy+}` | 3 | 6 |
| `ANY /admin/ai`, `ANY /admin/ai/{proxy+}` | 1 | 3 |

*The runbook has no screenshot of the throttling settings.*

API Gateway uses a token bucket and returns **HTTP 429** when the limit is exceeded; the limits are best-effort targets, not hard ceilings, and they apply per route, not per user. The frontend must show a "too many requests, try again later" message with backoff instead of retrying in a loop. Usage plans / API keys (a REST API feature) and Lambda reserved concurrency (which would throttle all AI routes together) are deliberately not used.

The full AI path now has: JWT → API Gateway route throttling → AI HTTP Lambda (Auth, Aurora, Nova Pro, Cohere, OpenSearch, SQS) → AI Worker; EventBridge → AI Jobs → OpenSearch; Payment → AI internal endpoint.
