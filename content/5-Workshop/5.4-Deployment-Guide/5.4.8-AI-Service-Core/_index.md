---
title: "5.4.8 AI Service — database, queue and Bedrock"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 5.4.8. </b> "
---

The AI Service is split into three Lambdas, each with a different timing requirement:

| Function | Handler | Timeout | Job |
|---|---|---|---|
| `fitness-assistant-dev-ai` | `dist/lambda.handler` | 29–30 s | HTTP API: chat, plans, marketplace, admin AI. Long generations are queued instead of run inline. |
| `fitness-assistant-dev-ai-worker` | `dist/worker-lambda.handler` | 300 s | Consumes the SQS queue and runs long workout/nutrition generations on Nova Pro. |
| `fitness-assistant-dev-ai-jobs` | `dist/jobs-lambda.handler` | 600 s | Scheduled jobs: personalized-service auto-accept and knowledge ingestion (PubMed, RSS, web, local evidence). |

Before deploying, the code was updated so that the AI Lambda verifies Bearer JWTs by invoking the Auth Lambda, calls Auth/User/Fitness/Payment by direct invoke, and its migration Lambda reads `DATABASE_SECRET_ID` and creates `fitness_assistant_ai` on its own.

#### Step 1 — Database secret

Create `fitness-assistant/dev/ai-database` (`database = fitness_assistant_ai`). No `CREATE DATABASE` by hand: the migration Lambda connects to the `postgres` maintenance database, checks `pg_database`, creates `fitness_assistant_ai` if missing, then runs `prisma migrate deploy`, and refuses to run against any other database.

![Store a new secret for the AI database](/images/workshop/runbook/img148.jpg)

![Secret name fitness-assistant/dev/ai-database](/images/workshop/runbook/img149.jpg)

#### Step 2 — Migration role and Lambda

Role `fitness-assistant-dev-ai-migrate-role` (two managed policies + inline `fitness-assistant-dev-ai-migrate-secret` allowing `secretsmanager:GetSecretValue` on `fitness-assistant/dev/ai-database*`).

![Inline policy for the AI database secret](/images/workshop/runbook/img150.jpg)

Lambda `fitness-assistant-dev-ai-migrate`: Node.js 22.x, x86_64, 1024 MB, 5 minutes, handler `dist/migrate-lambda.handler`, artifact `ai-migrate-lambda.zip` (~21 MiB, direct upload), both private app subnets + Lambda SG, environment `NODE_ENV=production`, `DATABASE_SECRET_ID=fitness-assistant/dev/ai-database`, `AI_DATABASE_NAME=fitness_assistant_ai`.

![Create function fitness-assistant-dev-ai-migrate](/images/workshop/runbook/img151.jpg)

![Memory 1024 MB, timeout 5 minutes](/images/workshop/runbook/img152.jpg)

![Handler dist/migrate-lambda.handler](/images/workshop/runbook/img153.jpg)

![Uploading ai-migrate-lambda.zip (22.3 MB)](/images/workshop/runbook/img154.jpg)

![VPC configuration](/images/workshop/runbook/img155.jpg)

![Environment variables of the migration Lambda](/images/workshop/runbook/img156.jpg)

#### Step 3 — Run the 22 migrations

**Test → Create new event** with `{}` (or `{"database": "fitness_assistant_ai"}`), then invoke.

![Test event for the AI migration](/images/workshop/runbook/img157.jpg)

![Result: status ok, databaseCreated true, migrateExitCode 0](/images/workshop/runbook/img158.jpg)

**Expected result:** `status = ok`, `database = fitness_assistant_ai`, `databaseCreated = true`, `migrateExitCode = 0`, `22 migrations found`, `All migrations have been successfully applied.` The 22 migrations contain no `DROP` or `TRUNCATE` — only one de-duplication `DELETE` that does not affect a new database.

#### Step 4 — SQS queues

SQS replaces Redis/BullMQ for AI plan generation in AWS.

1. **SQS → Create queue**, Standard, name `fitness-assistant-dev-ai-tasks-dlq` (defaults).
2. **Create queue**, Standard, name `fitness-assistant-dev-ai-tasks`, **visibility timeout 10 minutes (600 s)** — longer than the Worker's 300 s timeout, so a message is not redelivered while still being processed — with the dead-letter queue enabled: `fitness-assistant-dev-ai-tasks-dlq`, **maximum receives 2**.

![Dead-letter queue fitness-assistant-dev-ai-tasks-dlq (Standard)](/images/workshop/runbook/img159.jpg)

![DLQ created](/images/workshop/runbook/img160.jpg)

![Queue fitness-assistant-dev-ai-tasks with a 10-minute visibility timeout](/images/workshop/runbook/img161.jpg)

![Dead-letter queue enabled, maximum receives 2](/images/workshop/runbook/img162.jpg)

![Redrive configuration before creating the queue](/images/workshop/runbook/img163.jpg)

Copy the queue URL (`https://sqs.ap-southeast-1.amazonaws.com/<account-id>/fitness-assistant-dev-ai-tasks`) — it becomes `AI_TASKS_QUEUE_URL`.

#### Step 5 — Role for the AI HTTP Lambda

`fitness-assistant-dev-ai-lambda-role` (AWS service → Lambda, two managed policies) with the inline policy `fitness-assistant-dev-ai-runtime-policy`:

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

Gym is not in the list because the AI code never calls it. The HTTP Lambda can only **send** to the queue; consuming is the Worker's job.

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img164.jpg)

![Role name fitness-assistant-dev-ai-lambda-role](/images/workshop/runbook/img165.jpg)

![Managed policies](/images/workshop/runbook/img166.jpg)

![Runtime policy JSON: secret, SQS send, Lambda invoke](/images/workshop/runbook/img167.jpg)

![Policy name fitness-assistant-dev-ai-runtime-policy](/images/workshop/runbook/img168.jpg)

![Role with its runtime policy](/images/workshop/runbook/img169.jpg)

#### Step 6 — Create the AI HTTP Lambda

`fitness-assistant-dev-ai`: Node.js 22.x, x86_64, role `fitness-assistant-dev-ai-lambda-role`, artifact `ai-lambda.zip`, handler `dist/lambda.handler`, 1024 MB, 30 s (later 29 s, just under API Gateway's integration limit), private app subnets + Lambda SG.

![Create function fitness-assistant-dev-ai](/images/workshop/runbook/img170.jpg)

![Uploading ai-lambda.zip (34.7 MB)](/images/workshop/runbook/img171.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img172.jpg)

![Memory 1024 MB, timeout 30 seconds](/images/workshop/runbook/img173.jpg)

![VPC configuration](/images/workshop/runbook/img174.jpg)

The first environment still targeted the Anthropic API (`LLM_PROVIDER=anthropic`, called through the NAT Gateway because the endpoint is outside AWS):

![First environment, with LLM_PROVIDER=anthropic](/images/workshop/runbook/img175.jpg)

![First environment (continued)](/images/workshop/runbook/img176.jpg)

#### Step 7 — Switch to Amazon Bedrock

In **Amazon Bedrock → Model catalog** (region `ap-southeast-1`), both **Amazon Nova Pro** and **Cohere Embed Multilingual** were available. **Decision: no Anthropic API key needed** — the AI Service moved to Bedrock, which removes the external API key, keeps traffic on AWS and is billed through the same account. Cohere is a Marketplace model: accept its subscription/EULA once as an administrator ([5.3.1](../../5.3-Prerequisites/5.3.1-AWS-Account-Permissions/)).

![Bedrock model catalog filtered on Anthropic and Cohere](/images/workshop/runbook/img177.jpg)

![Bedrock model catalog: Amazon Nova and Cohere Embed models](/images/workshop/runbook/img178.jpg)

Add these statements to `fitness-assistant-dev-ai-runtime-policy` (without removing the existing ones):

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

A cross-region inference profile can route to the foundation model in several APAC regions, so IAM must allow **both** the profile and the underlying foundation model — the condition limits the second statement to calls made through this profile. `AmazonBedrockFullAccess` and `bedrock:InvokeModelWithResponseStream` are not added; the code only uses `InvokeModel`.

Upload the new `ai-lambda.zip` built for Bedrock (35,076,525 bytes compressed, 105,103,760 bytes uncompressed — it bundles the Bedrock Runtime SDK and the Prisma `rhel-openssl-3.0.x` engine), keep the handler and VPC, and replace the environment with:

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/ai-database` |
| `INTERNAL_SERVICE_SECRET` | the shared value |
| `AUTH_LAMBDA_NAME`, `USER_LAMBDA_NAME`, `FITNESS_LAMBDA_NAME`, `PAYMENT_LAMBDA_NAME` | the four function names |
| `QUEUE_PROVIDER` / `AI_TASKS_QUEUE_URL` | `sqs` / the queue URL |
| `LLM_PROVIDER` / `BEDROCK_REGION` | `bedrock` / `ap-southeast-1` |
| `BEDROCK_CHAT_MODEL` / `BEDROCK_VISION_MODEL` | `apac.amazon.nova-pro-v1:0` |
| `EMBEDDING_PROVIDER` / `BEDROCK_EMBEDDING_MODEL` | `bedrock` / `cohere.embed-multilingual-v3` |
| `KNOWLEDGE_VECTOR_SIZE` | `1024` |
| `LLM_TIMEOUT_MS` | `25000` |
| `PLATFORM_COMMISSION_RATE` / `PERSONALIZED_SERVICE_AUTO_ACCEPT_DAYS` | `0.10` / `3` |

`ANTHROPIC_API_KEY`, `LLM_BASE_URL` and `OLLAMA_BASE_URL` are removed. No migration is needed for the switch — the schema did not change.

![AI Lambda environment after the switch to Nova Pro and Cohere](/images/workshop/runbook/img179.jpg)

{{% notice note %}}
The embedding dimension changed from 768 (Ollama, local development) to 1024 (Cohere). The code fails loudly if it is asked to write 1024-dimension vectors into an old 768-dimension index instead of corrupting it, so knowledge ingestion stays disabled until a 1024-dimension vector store exists — see [5.4.9](../5.4.9-AI-Service-Vector-Search/).
{{% /notice %}}

#### Step 8 — AI Worker role

`fitness-assistant-dev-ai-worker-role` ("Execution role for Gymini AI Worker Lambda"), two managed policies, inline `fitness-assistant-dev-ai-worker-runtime-policy` with: the AI secret; `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` on `fitness-assistant-dev-ai-tasks`; invoke on Auth/User/Fitness/Payment; and the same three Bedrock statements. Not added: `AmazonBedrockFullAccess`, `AmazonSQSFullAccess`, `AWSLambdaFullAccess`.

![Role name fitness-assistant-dev-ai-worker-role](/images/workshop/runbook/img180.jpg)

![Managed policies of the Worker role](/images/workshop/runbook/img181.jpg)

![Worker runtime policy JSON (Bedrock statements)](/images/workshop/runbook/img182.jpg)

![Policy summary: Bedrock, Lambda, Secrets Manager, SQS](/images/workshop/runbook/img183.jpg)

The resulting flow:

```
AI HTTP Lambda ──sqs:SendMessage──► fitness-assistant-dev-ai-tasks ──ReceiveMessage──► AI Worker Lambda
                                                                                       ├── Nova Pro
                                                                                       ├── Cohere Embed
                                                                                       ├── Aurora
                                                                                       └── internal Lambdas
```

#### Step 9 — AI Worker Lambda

`fitness-assistant-dev-ai-worker`: Node.js 22.x, x86_64, role `fitness-assistant-dev-ai-worker-role`, artifact `ai-worker-lambda.zip` (the new Bedrock build), handler **`dist/worker-lambda.handler`** (not `dist/lambda.handler`), 1024 MB, **300 s**, ephemeral storage 512 MB, private app subnets only (never the DB subnets) + Lambda SG.

![Create function fitness-assistant-dev-ai-worker](/images/workshop/runbook/img184.jpg)

![Additional settings with the custom execution role](/images/workshop/runbook/img185.jpg)

![Upload ai-worker-lambda.zip](/images/workshop/runbook/img186.jpg)

![Handler dist/worker-lambda.handler](/images/workshop/runbook/img187.jpg)

![Memory 1024 MB, timeout 5 minutes](/images/workshop/runbook/img188.jpg)

![Worker VPC configuration](/images/workshop/runbook/img189.jpg)

The Worker copies the HTTP Lambda's environment with one important change: **`LLM_TIMEOUT_MS=180000`** instead of 25000, because generations can run for minutes. `AWS_REGION` is not set manually (Lambda provides it), and no Anthropic/Ollama/Redis variables are needed.

![Worker environment with LLM_TIMEOUT_MS=180000](/images/workshop/runbook/img190.jpg)

#### Step 10 — SQS trigger for the Worker

Check the queue first: visibility timeout 600 s, DLQ `fitness-assistant-dev-ai-tasks-dlq`, maximum receives 2.

![Queue details: DLQ enabled](/images/workshop/runbook/img191.jpg)

Then **Lambda → `fitness-assistant-dev-ai-worker` → Add trigger → SQS**: queue `fitness-assistant-dev-ai-tasks`, **batch size 1**, batch window 0, trigger activated, no filter, no maximum concurrency, and **Report batch item failures** enabled (the Worker returns `batchItemFailures`, so one failed message does not force the whole batch to retry).

![No triggers configured yet](/images/workshop/runbook/img192.jpg)

![Add trigger: SQS queue, batch size 1, report batch item failures](/images/workshop/runbook/img193.jpg)

![SQS trigger added to fitness-assistant-dev-ai-worker](/images/workshop/runbook/img194.jpg)

#### Step 11 — AI Jobs role and Lambda

Role `fitness-assistant-dev-ai-jobs-role` (two managed policies + inline `fitness-assistant-dev-ai-jobs-runtime-policy`: the AI secret and the three Bedrock statements — Cohere for embeddings, Nova for LLM/safety judging).

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img195.jpg)

![Role name fitness-assistant-dev-ai-jobs-role](/images/workshop/runbook/img196.jpg)

![Managed policies](/images/workshop/runbook/img197.jpg)

![Jobs runtime policy JSON](/images/workshop/runbook/img198.jpg)

![Policy summary: Bedrock and Secrets Manager](/images/workshop/runbook/img199.jpg)

![Role with three policies](/images/workshop/runbook/img200.jpg)

Lambda `fitness-assistant-dev-ai-jobs`: artifact `ai-lambda.zip`, handler `dist/jobs-lambda.handler`, 1024 MB, **600 s** (crawling plus embedding is long-running I/O and is not bound by API Gateway's ~30 s limit), private app subnets + Lambda SG.

![Create function fitness-assistant-dev-ai-jobs](/images/workshop/runbook/img201.jpg)

![Upload ai-lambda.zip (35.1 MB)](/images/workshop/runbook/img202.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img203.jpg)

![Memory 1024 MB, timeout 10 minutes](/images/workshop/runbook/img204.jpg)

![Jobs Lambda VPC configuration](/images/workshop/runbook/img205.jpg)

Environment: `NODE_ENV`, `DATABASE_SECRET_ID`, the shared `INTERNAL_SERVICE_SECRET`, `LLM_PROVIDER=bedrock`, `BEDROCK_REGION`, `BEDROCK_CHAT_MODEL`, `BEDROCK_VISION_MODEL`, `EMBEDDING_PROVIDER=bedrock`, `BEDROCK_EMBEDDING_MODEL`, `KNOWLEDGE_VECTOR_SIZE=1024`.

![Jobs Lambda environment variables](/images/workshop/runbook/img206.jpg)

No schedule is attached yet: the knowledge jobs must not run until the 1024-dimension vector store exists. That is the next page.
