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

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

#### Step 1 — Database secret

No `CREATE DATABASE` by hand: the migration Lambda connects to the `postgres` maintenance database, checks `pg_database`, creates `fitness_assistant_ai` if missing, then runs `prisma migrate deploy`, and refuses to run against any other database.

**1.1 — Choose the type and fill in the pairs.** **Secrets Manager → Store a new secret**, choose **Other type of secret**, enter the same five pairs as the other services with `database` = `fitness_assistant_ai`, then click **Next**.

![Other type of secret, five key/value rows and Next (credentials redacted)](/images/workshop/runbook/img148.jpg)

**1.2 — Name the secret.** Enter `fitness-assistant/dev/ai-database` and click **Next** (then store it).

![Secret name fitness-assistant/dev/ai-database and Next](/images/workshop/runbook/img149.jpg)

#### Step 2 — Migration role and Lambda

**2.1 — Create the role.** `fitness-assistant-dev-ai-migrate-role`: AWS service → Lambda with the two managed policies (`AWSLambdaBasicExecutionRole`, `AWSLambdaVPCAccessExecutionRole`).

*The runbook has no screenshot of the role creation; the form is the same as in Step 5.*

**2.2 — Add the secret policy.** On the role, **Add permissions → Create inline policy → JSON**: allow `secretsmanager:GetSecretValue` on `fitness-assistant/dev/ai-database*`, then click **Next** and name it `fitness-assistant-dev-ai-migrate-secret`.

![JSON editor with GetSecretValue on the AI secret and Next](/images/workshop/runbook/img150.jpg)

**2.3 — Fill in the function.** **Lambda → Create function**, **Author from scratch**, name `fitness-assistant-dev-ai-migrate`, runtime **Node.js 22.x** (x86_64), custom execution role `fitness-assistant-dev-ai-migrate-role`, then **Create function**.

![Author from scratch, name, runtime and the migrate role](/images/workshop/runbook/img151.jpg)

**2.4 — Set memory and timeout.** **Configuration → General configuration → Edit**: **Memory** `1024` MB, **Timeout** `5` min `0` sec, **Save**.

![Memory 1024 MB, timeout 5 minutes, Save](/images/workshop/runbook/img152.jpg)

**2.5 — Set the handler.** **Code → Runtime settings → Edit**: `dist/migrate-lambda.handler`, **Save**.

![Handler dist/migrate-lambda.handler and Save](/images/workshop/runbook/img153.jpg)

**2.6 — Upload the code.** **Upload from → .zip file**, choose `ai-migrate-lambda.zip` (~21 MiB, so a direct upload is enough) and click **Update**.

![ai-migrate-lambda.zip selected (22.32 MB) and Update](/images/workshop/runbook/img154.jpg)

**2.7 — Attach the VPC.** **Configuration → VPC → Edit**: the project VPC, both private app subnets and `fitness-assistant-dev-lambda-sg`, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img155.jpg)

**2.8 — Add the environment variables.** `NODE_ENV=production`, `DATABASE_SECRET_ID=fitness-assistant/dev/ai-database`, `AI_DATABASE_NAME=fitness_assistant_ai`. The screenshot shows the saved result; the **Edit** button is where you add them.

![Three environment variables and the Edit button](/images/workshop/runbook/img156.jpg)

#### Step 3 — Run the 22 migrations

**3.1 — Create the test event.** On the **Test** tab choose **Create new event**, name it `test-db-ai`, keep `{}` (or `{"database": "fitness_assistant_ai"}`) and click **Test**.

![Create new event, event name and the Test button](/images/workshop/runbook/img157.jpg)

**3.2 — Read the result.** The execution must succeed with the response below.

![Executing function succeeded: status ok, databaseCreated true, migrateExitCode 0](/images/workshop/runbook/img158.jpg)

**Expected result:** `status = ok`, `database = fitness_assistant_ai`, `databaseCreated = true`, `migrateExitCode = 0`, `22 migrations found`, `All migrations have been successfully applied.` The 22 migrations contain no `DROP` or `TRUNCATE` — only one de-duplication `DELETE` that does not affect a new database.

#### Step 4 — SQS queues

SQS replaces Redis/BullMQ for AI plan generation in AWS.

**4.1 — Create the dead-letter queue.** **SQS → Create queue**, type **Standard**, name `fitness-assistant-dev-ai-tasks-dlq`, keep the defaults and click **Create queue**.

![Standard type and the name fitness-assistant-dev-ai-tasks-dlq](/images/workshop/runbook/img159.jpg)

**4.2 — Check the DLQ.** The banner must say the queue was created.

![Queue fitness-assistant-dev-ai-tasks-dlq created successfully](/images/workshop/runbook/img160.jpg)

**4.3 — Name the main queue and set the visibility timeout.** **Create queue**, **Standard**, name `fitness-assistant-dev-ai-tasks`, **Visibility timeout** `10` **Minutes** — longer than the Worker's 300 s timeout, so a message is not redelivered while still being processed.

![Name fitness-assistant-dev-ai-tasks and visibility timeout 10 minutes](/images/workshop/runbook/img161.jpg)

**4.4 — Enable the dead-letter queue.** Scroll to **Dead-letter queue**, choose **Enabled**, pick the ARN of `fitness-assistant-dev-ai-tasks-dlq` and set **Maximum receives** to `2`.

![DLQ Enabled, the DLQ ARN and maximum receives 2](/images/workshop/runbook/img162.jpg)

**4.5 — Create the queue.** Review the redrive section and click **Create queue**.

![Redrive section with DLQ enabled and the Create queue button](/images/workshop/runbook/img163.jpg)

Copy the queue URL (`https://sqs.ap-southeast-1.amazonaws.com/<account-id>/fitness-assistant-dev-ai-tasks`) — it becomes `AI_TASKS_QUEUE_URL`.

#### Step 5 — Role for the AI HTTP Lambda

**5.1 — Choose the trusted entity.** **IAM → Roles → Create role**: **AWS service**, use case **Lambda**, **Next**.

![AWS service, use case Lambda and Next](/images/workshop/runbook/img164.jpg)

**5.2 — Name the role.** `fitness-assistant-dev-ai-lambda-role`.

![Role name fitness-assistant-dev-ai-lambda-role](/images/workshop/runbook/img165.jpg)

**5.3 — Check the managed policies.** `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole`, then create the role.

![The two managed policies](/images/workshop/runbook/img166.jpg)

**5.4 — Write the runtime policy.** On the role open **Add permissions → Create inline policy → JSON** and paste:

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

**5.5 — Name and create the policy.** `fitness-assistant-dev-ai-runtime-policy`, then **Create policy**.

![Policy name and Create policy](/images/workshop/runbook/img168.jpg)

**5.6 — Check the role.** The runtime policy must appear next to the two managed policies.

![Role with fitness-assistant-dev-ai-runtime-policy](/images/workshop/runbook/img169.jpg)

Gym is not in the list because the AI code never calls it. The HTTP Lambda can only **send** to the queue; consuming is the Worker's job.

#### Step 6 — Create the AI HTTP Lambda

**6.1 — Fill in the function.** **Lambda → Create function**, name `fitness-assistant-dev-ai`, runtime **Node.js 22.x** (x86_64); under **Additional settings → Custom execution role** choose `fitness-assistant-dev-ai-lambda-role` and click **Save**, then **Create function**.

![Author from scratch, name, runtime and the AI role](/images/workshop/runbook/img170.jpg)

**6.2 — Upload the code.** **Upload from → .zip file**, `ai-lambda.zip` (34.68 MB), **Update**.

![ai-lambda.zip selected and Update](/images/workshop/runbook/img171.jpg)

**6.3 — Set the handler.** `dist/lambda.handler`, **Save**.

![Handler dist/lambda.handler and Save](/images/workshop/runbook/img172.jpg)

**6.4 — Set memory and timeout.** **Memory** `1024` MB, **Timeout** `0` min `30` sec (later 29 s, just under API Gateway's integration limit), **Save**.

![Memory 1024 MB, timeout 30 seconds, Save](/images/workshop/runbook/img173.jpg)

**6.5 — Attach the VPC.** Private app subnets and the Lambda security group, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img174.jpg)

**6.6 — Add the first environment.** It still targeted the Anthropic API (`LLM_PROVIDER=anthropic`, called through the NAT Gateway because the endpoint is outside AWS). `AI_TASKS_QUEUE_URL` is the queue URL from Step 4.

![First environment with AI_TASKS_QUEUE_URL and LLM_PROVIDER=anthropic](/images/workshop/runbook/img175.jpg)

**6.7 — Save.** The same list scrolled down to the **Save** button.

![LLM_PROVIDER=anthropic row and Save](/images/workshop/runbook/img176.jpg)

#### Step 7 — Switch to Amazon Bedrock

**7.1 — Look at the model catalog.** In **Amazon Bedrock → Model catalog** (region `ap-southeast-1`) filter on the providers **Anthropic** and **Cohere**.

![Provider filter Anthropic + Cohere and the Embed Multilingual card](/images/workshop/runbook/img177.jpg)

**7.2 — Check Nova and Cohere.** Filter on **Amazon** and **Cohere**: **Amazon Nova Pro** and **Cohere Embed Multilingual** are both available. **Decision: no Anthropic API key needed** — the AI Service moved to Bedrock, which removes the external API key, keeps traffic on AWS and is billed through the same account. Cohere is a Marketplace model: accept its subscription/EULA once as an administrator ([5.3.1](../../5.3-Prerequisites/5.3.1-AWS-Account-Permissions/)).

![Providers Amazon and Cohere, Nova Pro and Embed Multilingual cards](/images/workshop/runbook/img178.jpg)

**7.3 — Add the Bedrock statements.** Add these statements to `fitness-assistant-dev-ai-runtime-policy` (without removing the existing ones):

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

*The runbook has no screenshot of editing this policy; the same three statements are visible in the Worker role editor in Step 8.3.*

**7.4 — Upload the Bedrock build.** Upload the new `ai-lambda.zip` (35,076,525 bytes compressed, 105,103,760 bytes uncompressed — it bundles the Bedrock Runtime SDK and the Prisma `rhel-openssl-3.0.x` engine) and keep the handler and VPC.

**7.5 — Replace the environment.**

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

![AI Lambda environment: queue URL, LLM_PROVIDER=bedrock and the Bedrock rows, Save](/images/workshop/runbook/img179.jpg)

{{% notice note %}}
The embedding dimension changed from 768 (Ollama, local development) to 1024 (Cohere). The code fails loudly if it is asked to write 1024-dimension vectors into an old 768-dimension index instead of corrupting it, so knowledge ingestion stays disabled until a 1024-dimension vector store exists — see [5.4.9](../5.4.9-AI-Service-Vector-Search/).
{{% /notice %}}

#### Step 8 — AI Worker role

Role `fitness-assistant-dev-ai-worker-role` with the two managed policies and the inline `fitness-assistant-dev-ai-worker-runtime-policy`. Not added: `AmazonBedrockFullAccess`, `AmazonSQSFullAccess`, `AWSLambdaFullAccess`.

**8.1 — Name the role.** `fitness-assistant-dev-ai-worker-role`, description "Execution role for Gymini AI Worker Lambda".

![Role name fitness-assistant-dev-ai-worker-role](/images/workshop/runbook/img180.jpg)

**8.2 — Check the managed policies and create the role.** Click **Create role**.

![The two managed policies and Create role](/images/workshop/runbook/img181.jpg)

**8.3 — Write the runtime policy.** The JSON contains: the AI secret; `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` on `fitness-assistant-dev-ai-tasks`; invoke on Auth/User/Fitness/Payment; and the same three Bedrock statements as in Step 7.3.

![JSON editor, Bedrock statements in the lower half](/images/workshop/runbook/img182.jpg)

**8.4 — Name and create the policy.** `fitness-assistant-dev-ai-worker-runtime-policy`, **Create policy**. The summary lists Bedrock, Lambda, Secrets Manager and SQS.

![Policy name and Create policy](/images/workshop/runbook/img183.jpg)

The resulting flow:

```
AI HTTP Lambda ──sqs:SendMessage──► fitness-assistant-dev-ai-tasks ──ReceiveMessage──► AI Worker Lambda
                                                                                       ├── Nova Pro
                                                                                       ├── Cohere Embed
                                                                                       ├── Aurora
                                                                                       └── internal Lambdas
```

#### Step 9 — AI Worker Lambda

**9.1 — Fill in the function.** **Lambda → Create function**, name `fitness-assistant-dev-ai-worker`, runtime **Node.js 22.x** (x86_64), and in the custom execution role panel choose `fitness-assistant-dev-ai-worker-role`, **Save**.

![Author from scratch, name, runtime and the Worker role](/images/workshop/runbook/img184.jpg)

**9.2 — Create the function.** Check **Additional settings** (the custom execution role is the Worker role) and click **Create function**.

![Custom execution role link and the Create function button](/images/workshop/runbook/img185.jpg)

**9.3 — Upload the code.** **Upload from → .zip file → Choose file**: `ai-worker-lambda.zip` (the new Bedrock build), then **Update**.

![Choose file and Update](/images/workshop/runbook/img186.jpg)

**9.4 — Set the handler.** **`dist/worker-lambda.handler`** (not `dist/lambda.handler`), **Save**.

![Handler dist/worker-lambda.handler and Save](/images/workshop/runbook/img187.jpg)

**9.5 — Set memory and timeout.** **Memory** `1024` MB, **Timeout** `5` min `0` sec (**300 s**), ephemeral storage stays `512` MB, **Save**.

![Memory 1024 MB, timeout 5 minutes, Save](/images/workshop/runbook/img188.jpg)

**9.6 — Attach the VPC.** Private app subnets only (never the DB subnets) and the Lambda security group, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img189.jpg)

**9.7 — Add the environment.** Copy the HTTP Lambda's environment with one important change: **`LLM_TIMEOUT_MS=180000`** instead of 25000, because generations can run for minutes. `AWS_REGION` is not set manually (Lambda provides it), and no Anthropic/Ollama/Redis variables are needed.

![Worker environment, LLM_TIMEOUT_MS=180000 in the first row, Save](/images/workshop/runbook/img190.jpg)

#### Step 10 — SQS trigger for the Worker

**10.1 — Check the queue.** Open `fitness-assistant-dev-ai-tasks`: default visibility timeout 10 minutes, **Dead-letter queue: Enabled**, DLQ `fitness-assistant-dev-ai-tasks-dlq`, maximum receives 2.

![Visibility timeout 10 minutes, DLQ enabled, DLQ ARN and maximum receives 2](/images/workshop/runbook/img191.jpg)

**10.2 — Open Add trigger.** **Lambda → `fitness-assistant-dev-ai-worker` → Configuration → Triggers** — it says **No triggers**. Click **Add trigger**.

![Triggers (0) and the Add trigger button](/images/workshop/runbook/img192.jpg)

**10.3 — Configure the SQS trigger.** Source **SQS**, queue `fitness-assistant-dev-ai-tasks`, **Activate trigger** ticked, **Batch size** `1`, batch window `0`, no maximum concurrency, **Report batch item failures** ticked (the Worker returns `batchItemFailures`, so one failed message does not force the whole batch to retry), then **Add**.

![SQS, the queue, Activate trigger, batch size 1, Report batch item failures](/images/workshop/runbook/img193.jpg)

**10.4 — Check the trigger.** The banner says it was added and the Triggers list shows the SQS queue.

![Trigger added to fitness-assistant-dev-ai-worker](/images/workshop/runbook/img194.jpg)

#### Step 11 — AI Jobs role and Lambda

Role `fitness-assistant-dev-ai-jobs-role` (two managed policies + inline `fitness-assistant-dev-ai-jobs-runtime-policy`: the AI secret and the three Bedrock statements — Cohere for embeddings, Nova for LLM/safety judging).

**11.1 — Choose the trusted entity.** **AWS service**, use case **Lambda**, **Next**.

![AWS service, use case Lambda and Next](/images/workshop/runbook/img195.jpg)

**11.2 — Name the role.** `fitness-assistant-dev-ai-jobs-role`.

![Role name fitness-assistant-dev-ai-jobs-role](/images/workshop/runbook/img196.jpg)

**11.3 — Check the managed policies and create the role.**

![The two managed policies and Create role](/images/workshop/runbook/img197.jpg)

**11.4 — Write the runtime policy.** The JSON holds the secret statement and the three Bedrock statements.

![JSON editor with the secret and Bedrock statements, Next](/images/workshop/runbook/img198.jpg)

**11.5 — Name and create the policy.** `fitness-assistant-dev-ai-jobs-runtime-policy`, **Create policy**. The summary lists Bedrock and Secrets Manager.

![Policy name and Create policy](/images/workshop/runbook/img199.jpg)

**11.6 — Check the role.** The role now has three policies.

![Role with the jobs runtime policy](/images/workshop/runbook/img200.jpg)

**11.7 — Fill in the function.** `fitness-assistant-dev-ai-jobs`, **Node.js 22.x**, custom execution role `fitness-assistant-dev-ai-jobs-role`, **Create function**.

![Author from scratch, name ai-jobs, runtime and the jobs role](/images/workshop/runbook/img201.jpg)

**11.8 — Upload the code.** `ai-lambda.zip` (35.08 MB), **Update**.

![Choose file, ai-lambda.zip and Update](/images/workshop/runbook/img202.jpg)

**11.9 — Set the handler.** `dist/jobs-lambda.handler`, **Save**.

![Handler dist/jobs-lambda.handler and Save](/images/workshop/runbook/img203.jpg)

**11.10 — Set memory and timeout.** **Memory** `1024` MB, **Timeout** `10` min `0` sec (**600 s** — crawling plus embedding is long-running I/O and is not bound by API Gateway's ~30 s limit), **Save**.

![Memory 1024 MB, timeout 10 minutes, Save](/images/workshop/runbook/img204.jpg)

**11.11 — Attach the VPC.** Private app subnets and the Lambda security group, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img205.jpg)

**11.12 — Add the environment.** `NODE_ENV`, `DATABASE_SECRET_ID`, the shared `INTERNAL_SERVICE_SECRET`, `LLM_PROVIDER=bedrock`, `BEDROCK_REGION`, `BEDROCK_CHAT_MODEL`, `BEDROCK_VISION_MODEL`, `EMBEDDING_PROVIDER=bedrock`, `BEDROCK_EMBEDDING_MODEL`, `KNOWLEDGE_VECTOR_SIZE=1024`, then **Save**.

![Jobs Lambda environment variables and Save](/images/workshop/runbook/img206.jpg)

No schedule is attached yet: the knowledge jobs must not run until the 1024-dimension vector store exists. That is the next page.
