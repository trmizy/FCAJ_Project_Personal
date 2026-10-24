---
title: "User Service"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.4.4. </b> "
---

After login, the frontend immediately needs the user profile, onboarding and body profile, so the User Service came next. It introduced three patterns reused by later services: calling another Lambda directly instead of through the public API, private S3 uploads with presigned URLs, and scheduled jobs on EventBridge Scheduler.

| Item | Value |
|---|---|
| Logical database | `fitness_assistant_user` |
| Secret | `fitness-assistant/dev/user-database` |
| Functions | `fitness-assistant-dev-user` (HTTP), `fitness-assistant-dev-user-jobs` (jobs) |
| Uploads bucket | `fitness-assistant-uploads-dev-<account-id>` (private) |

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it. Where the runbook has no screenshot for an action, the text says so.

#### Step 1 — Create the database secret

**1.1 — Enter the connection details.** Open **Secrets Manager → Store a new secret**, choose **Other type of secret**, and add the key/value rows: `username`, `password` (the Aurora master password, taken directly from Secrets Manager — redacted in the screenshot), `host` (the Aurora cluster endpoint), `port = 5432` and `database = fitness_assistant_user`. Keep the default encryption key and click **Next**.

![Store a new secret: Other type of secret and the five key/value rows (password redacted)](/images/workshop/runbook/img018.jpg)

**1.2 — Name the secret.** On the next page enter the name `fitness-assistant/dev/user-database`, leave rotation off and store the secret. *The runbook has no screenshot of these last pages.*

#### Step 2 — Create the execution role

**2.1 — Create the role.** Open **IAM → Roles → Create role**, choose the trusted entity **AWS service → Lambda**, and attach only the managed policies `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole` — not `AdministratorAccess`, `AmazonRDSFullAccess`, `SecretsManagerReadWrite` or `AmazonS3FullAccess`. On the last page enter the role name `fitness-assistant-dev-user-lambda-role`, check the two policies and click **Create role**.

![Name, review and create: role name, the two managed policies, Create role](/images/workshop/runbook/img019.jpg)

#### Step 3 — Allow the role to read only its own secret

**3.1 — Open the JSON editor.** In the role, open **Permissions → Add permissions → Create inline policy**, switch to the **JSON** tab and paste the policy below. Replace `SECRET_ARN` with the full ARN copied from the secret's page (the placeholder is boxed). `"Resource": "*"` is not acceptable. Then click **Next**.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": "SECRET_ARN"
    }
  ]
}
```

![Policy editor, JSON tab: the Resource line to replace with the secret ARN](/images/workshop/runbook/img020.jpg)

**3.2 — Name the policy.** Enter the policy name `fitness-assistant-dev-user-read-database-secret` and click **Create policy**.

![Review and create: policy name, Create policy](/images/workshop/runbook/img021.jpg)

**3.3 — Check the role.** The role now shows two managed policies and one inline policy.

![The role's permission policies: two managed and one inline](/images/workshop/runbook/img022.jpg)

The schema was then migrated with a temporary `fitness-assistant-dev-user-migrate` Lambda using the [common pattern](../#common-pattern). The outbound network needed by the User Lambda was added at this point too — see [5.4.1](../5.4.1-Shared-Network/).

#### Step 4 — Create the User Lambda

**4.1 — Create the function.** Open **Lambda → Create function**, choose **Author from scratch**, enter the name `fitness-assistant-dev-user`, runtime **Node.js 22.x**, architecture x86_64, and under **Additional settings → Custom execution role** pick the existing role `fitness-assistant-dev-user-lambda-role`. Then click **Create function**.

![Create function: Author from scratch, name, Node.js 22.x, existing execution role](/images/workshop/runbook/img029.jpg)

**4.2 — Configure the function.** Set the values below. *The runbook has no screenshot for the VPC and memory settings; they follow the same screens as in [5.4.2, steps 1.1 and 1.3](../5.4.2-Auth-Service-API-Gateway/).*

| Setting | Value |
|---|---|
| VPC | `fitness-assistant-dev-vpc`, subnets `private-app-a` + `private-app-b`, SG `fitness-assistant-dev-lambda-sg` |
| Memory / timeout | 1024 MB / 30 s |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/user-database` |
| `NODE_ENV` | `production` |
| `AUTH_SERVICE_URL` | the API Gateway invoke URL |
| `USER_UPLOAD_BUCKET` | `fitness-assistant-uploads-dev-<account-id>` |
| `INTERNAL_SERVICE_SECRET` | the **same** value as the Auth Lambda (one shared secret, never a new one) |

**4.3 — Add the environment variables.** In **Configuration → Environment variables → Edit**, add the five variables from the table and click **Save**. The list then looks like the screenshot (the secret value is redacted).

![Environment variables of the User Lambda: Edit button and the five variables](/images/workshop/runbook/img030.jpg)

Variables for services not deployed yet (`GYM_SERVICE_URL`, `PAYMENT_SERVICE_URL`, `AI_SERVICE_URL`, `CHAT_SERVICE_URL`) are left out until those services exist.

#### Step 5 — Allow profile-photo uploads to one S3 prefix

Add an inline policy that grants `s3:PutObject` on `arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/profile-photos/*` only — not `AmazonS3FullAccess`.

**5.1 — Write the policy.** In the role, open **Add permissions → Create inline policy → JSON** and enter a statement with `Action: s3:PutObject` and the `profile-photos/*` resource, then click **Next**.

![Policy editor, JSON tab: s3:PutObject on the profile-photos prefix](/images/workshop/runbook/img032.jpg)

**5.2 — Name the policy.** Enter the policy name `fitness-assistant-dev-user-profile-upload` and click **Create policy**. The summary shows the single S3 write permission limited to `profile-photos/*`.

![Review and create: policy name fitness-assistant-dev-user-profile-upload](/images/workshop/runbook/img031.jpg)

#### Step 6 — Upload the code

**6.1 — Upload the ZIP.** In the function, open **Code → Upload from → .zip file**, click **Choose file**, select `backend/services/user-service/artifacts/user-lambda.zip` and click **Update**.

![Update from a .zip file: Choose file, user-lambda.zip, Update](/images/workshop/runbook/img033.jpg)

**6.2 — Set the handler.** Open **Runtime settings → Edit** and set **Handler** to `dist/lambda.handler`. *The runbook has no screenshot for the HTTP function; the same screen for the jobs function is shown in step 11.5.*

#### Step 7 — Add the API Gateway integration

**7.1 — Create the integration.** Open **API Gateway → `fitness-assistant-dev-api` → Integrations → Manage integrations → Create**. Choose **Integration type: Lambda function**, region `ap-southeast-1`, function `fitness-assistant-dev-user`, timeout `30000`, payload format version **2.0**, keep **Grant API Gateway permission to invoke your Lambda function** switched on (API Gateway adds the invoke permission on the function), and click **Create**.

![Create an integration: Lambda function, region, function, timeout 30000, payload 2.0, invoke permission, Create](/images/workshop/runbook/img034.jpg)

**7.2 — Check the list.** The API now has the Auth integrations and the new User integration `fitness-assistant-dev-user`.

![Integrations list: the new fitness-assistant-dev-user integration selected](/images/workshop/runbook/img035.jpg)

#### Step 8 — Create greedy routes per prefix

The User Service exposes more than 100 endpoints, so instead of creating each route by hand, one greedy route is created per public prefix and attached to the User integration:

```
GET  /health
ANY  /profile/{proxy+}
ANY  /inbody/{proxy+}
ANY  /pt-applications/{proxy+}
ANY  /contracts/{proxy+}
ANY  /notifications/{proxy+}
ANY  /sessions/{proxy+}
ANY  /availability/{proxy+}
ANY  /admin/{proxy+}
ANY  /locations/{proxy+}
ANY  /pt/{proxy+}
ANY  /me/{proxy+}
```

**8.1 — Create one route per line.** Open **Routes → Create**, choose the method (`ANY`, or `GET` for `/health`), enter the path, e.g. `/me/{proxy+}`, and click **Create**. Repeat for each line. The green banner at the top of the screenshot confirms the previous route was created.

![Create a route: method ANY, path, Create](/images/workshop/runbook/img036.jpg)

**8.2 — Attach the integration.** Open **Integrations → Attach integrations to routes** and attach `fitness-assistant-dev-user` to every new route. *The runbook has no screenshot of this screen.*

`ANY /{proxy+}` and `ANY /internal/{proxy+}` are never created — `/internal/*` is service-to-service only. `/webhooks/dropbox-sign` is also skipped because it is disabled while `REQUIRE_CONTRACT_ESIGN=false`.

{{% notice warning %}}
A route that exists but has no integration attached returns `{"message":"Not Found"}`. After creating routes, always open **Integrations → Attach integrations to routes** and check that every route has a target.
{{% /notice %}}

#### Step 9 — Call Auth directly with Lambda Invoke

Some User flows call `/auth/internal/*`, which is intentionally not public. Instead of exposing it, the User Lambda invokes the Auth Lambda directly.

**9.1 — Write the policy.** In the role, open **Add permissions → Create inline policy → JSON**, enter the policy below and click **Next**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "InvokeAuthLambda",
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth"
    }
  ]
}
```

![Policy editor, JSON tab: lambda:InvokeFunction on the Auth Lambda only](/images/workshop/runbook/img037.jpg)

**9.2 — Name the policy.** Enter the policy name `fitness-assistant-dev-user-invoke-auth` and click **Create policy**.

![Review and create: policy name fitness-assistant-dev-user-invoke-auth](/images/workshop/runbook/img038.jpg)

**9.3 — Add `AUTH_LAMBDA_NAME`.** In the User Lambda, open **Configuration → Environment variables → Edit**, click **Add environment variable**, enter the key `AUTH_LAMBDA_NAME` and the value `fitness-assistant-dev-auth` (keeping `AUTH_SERVICE_URL` for now) and click **Save**.

![Edit environment variables: the new AUTH_LAMBDA_NAME row, Add environment variable, Save](/images/workshop/runbook/img040.jpg)

**9.4 — Check the result.** The function now has six variables, including `AUTH_LAMBDA_NAME` (the secret value is redacted).

![Environment variables after the change: AUTH_LAMBDA_NAME added](/images/workshop/runbook/img039.jpg)

#### Step 10 — Final S3 permissions and CORS for presigned uploads

Profile photos, PT application documents and contract PDFs all live in the private uploads bucket.

**10.1 — Replace the upload policy.** Edit the inline policy `fitness-assistant-dev-user-profile-upload` so it has three statements, each limited to one prefix. *The runbook has no screenshot of this edit.*

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "UserProfilePhotos",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/profile-photos/*"
    },
    {
      "Sid": "PTApplicationDocuments",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/pt-applications/*"
    },
    {
      "Sid": "ContractDocuments",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/contracts/*"
    }
  ]
}
```

No `s3:*`, no `s3:ListBucket`.

**10.2 — Add the CORS rule.** The browser uploads directly to S3 with a presigned URL, so the uploads bucket needs a CORS rule while staying private. Open the bucket's **Permissions → Cross-origin resource sharing (CORS) → Edit**, paste the JSON below and click **Save changes**.

```json
[
  {
    "AllowedOrigins": ["http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com"],
    "AllowedMethods": ["PUT", "GET", "HEAD"],
    "AllowedHeaders": ["content-type", "x-amz-*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 300
  }
]
```

![Edit CORS on the private uploads bucket: the JSON rule, Save changes](/images/workshop/runbook/img041.jpg)

#### Step 11 — Create the jobs Lambda

Background jobs run in a separate function so the HTTP Lambda never runs timers.

**11.1 — Create the function.** Open **Lambda → Create function → Author from scratch**, enter the name `fitness-assistant-dev-user-jobs`, runtime **Node.js 22.x**, the existing role `fitness-assistant-dev-user-lambda-role`, and click **Create function**.

![Create function: name fitness-assistant-dev-user-jobs, Node.js 22.x, existing role](/images/workshop/runbook/img042.jpg)

**11.2 — Attach the VPC.** In **Configuration → VPC → Edit**, select the VPC, both private app subnets and `fitness-assistant-dev-lambda-sg`, then click **Save**.

![Edit VPC: VPC, private app subnets, Lambda security group, Save](/images/workshop/runbook/img043.jpg)

**11.3 — Set memory and timeout.** In **Configuration → General configuration → Edit**, set **Memory** to `1024` MB and **Timeout** to `1` min `0` sec, then click **Save**.

![Edit basic settings: memory 1024 MB, timeout 1 minute, Save](/images/workshop/runbook/img044.jpg)

**11.4 — Upload the code.** Open **Code → Upload from → .zip file**, choose the same `user-lambda.zip` and click **Update**.

![Update from a .zip file: user-lambda.zip, Update](/images/workshop/runbook/img045.jpg)

**11.5 — Set the handler.** Open **Runtime settings → Edit**, set **Handler** to `dist/jobs-lambda.handler` (architecture stays x86_64) and click **Save**.

![Edit runtime settings: handler dist/jobs-lambda.handler, x86_64, Save](/images/workshop/runbook/img046.jpg)

**11.6 — Add the environment variables:** `DATABASE_SECRET_ID`, `NODE_ENV`, `AUTH_LAMBDA_NAME`, `USER_UPLOAD_BUCKET`, `REQUIRE_CONTRACT_ESIGN=false` and the shared `INTERNAL_SERVICE_SECRET`, in **Configuration → Environment variables → Edit → Save**.

![Environment variables of the jobs Lambda (secret redacted)](/images/workshop/runbook/img047.jpg)

#### Step 12 — Create the scheduler role

**12.1 — Create the role with a custom trust policy.** Open **IAM → Roles → Create role**, choose the trusted entity type **Custom trust policy** and paste the policy below for EventBridge Scheduler:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "scheduler.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
```

![Create role: Custom trust policy for scheduler.amazonaws.com](/images/workshop/runbook/img048.jpg)

Continue without attaching a managed policy (the permission is added as an inline policy in the next sub-step), name the role `fitness-assistant-dev-user-jobs-scheduler-role` and create it. *The runbook has no screenshot of these last pages.*

**12.2 — Write the inline policy.** In the new role, open **Add permissions → Create inline policy → JSON** and allow `lambda:InvokeFunction` on `fitness-assistant-dev-user-jobs` only, then click **Next**. The scheduler never reuses a Lambda execution role and never gets `lambda:*`.

![Policy editor, JSON tab: lambda:InvokeFunction on the User jobs Lambda only](/images/workshop/runbook/img049.jpg)

**12.3 — Name the policy.** Enter the policy name `fitness-assistant-dev-invoke-user-jobs` and click **Create policy**.

![Review and create: policy name fitness-assistant-dev-invoke-user-jobs](/images/workshop/runbook/img050.jpg)

#### Step 13 — Create the three schedules

One schedule per job, each sending `{"job": "<name>"}` to `fitness-assistant-dev-user-jobs`:

| Schedule | Rate | Payload |
|---|---|---|
| `fitness-assistant-dev-user-session-settlement` | `rate(5 minutes)` | `{"job": "session-settlement"}` |
| `fitness-assistant-dev-user-session-auto-confirm` | `rate(10 minutes)` | `{"job": "session-auto-confirm"}` |
| `fitness-assistant-dev-user-reschedule-expiry` | `rate(10 minutes)` | `{"job": "reschedule-expiry"}` |

The screenshots follow the first schedule, `session-settlement`.

**13.1 — Start the wizard.** Open **Amazon EventBridge → Scheduler → Schedules** and click **Create schedule**.

![EventBridge Scheduler: Schedules list, Create schedule](/images/workshop/runbook/img051.jpg)

**13.2 — Name the schedule.** Enter the schedule name `fitness-assistant-dev-user-session-settlement` and keep the `default` schedule group.

![Specify schedule detail: schedule name, default group](/images/workshop/runbook/img052.jpg)

**13.3 — Set the pattern.** Choose **Recurring schedule**, time zone `(UTC+07:00) Asia/Saigon`, **Rate-based schedule**, rate `5` `minutes`, and **Flexible time window** `Off`.

![Schedule pattern: recurring, Asia/Saigon, rate-based, rate(5 minutes), flexible window off](/images/workshop/runbook/img053.jpg)

**13.4 — Leave the timeframe empty** (the schedule runs indefinitely) and click **Next**.

![Timeframe left empty, Next](/images/workshop/runbook/img054.jpg)

**13.5 — Choose the target.** With **Templated targets** selected, pick **AWS Lambda → Invoke**.

![Select target: Templated targets, AWS Lambda Invoke](/images/workshop/runbook/img055.jpg)

**13.6 — Set the function and payload.** Choose the Lambda function `fitness-assistant-dev-user-jobs`, enter the payload `{"job": "session-settlement"}` and click **Next**.

![Invoke: Lambda function fitness-assistant-dev-user-jobs, payload, Next](/images/workshop/runbook/img056.jpg)

**13.7 — Settings.** Keep: schedule state **Enable**, action after completion **NONE**, **Retry** on with maximum age of event `5` minutes and `2` retry attempts, dead-letter queue **None** (DEV), AWS-owned encryption key, and execution role **Use existing role → `fitness-assistant-dev-user-jobs-scheduler-role`** (not *Create new role*). Click **Next**, then **Create schedule** on the review page.

![Settings: Enable, NONE, retry 5 min / 2 attempts, no DLQ, existing scheduler role, Next](/images/workshop/runbook/img057.jpg)

**13.8 — Check the schedule.** The new schedule is *Enabled* with `rate (5 minutes)` in the `Asia/Saigon` time zone.

![Schedule fitness-assistant-dev-user-session-settlement created: banner, Enabled, rate(5 minutes)](/images/workshop/runbook/img058.jpg)

**13.9 — Repeat for the other two.** Create the second schedule the same way with the name `fitness-assistant-dev-user-session-auto-confirm` and `rate(10 minutes)`, then the third, `fitness-assistant-dev-user-reschedule-expiry`, with `rate(10 minutes)`, each with its own payload from the table. *The runbook shows only the second schedule's first page; the third has no screenshot.*

![Second schedule: name fitness-assistant-dev-user-session-auto-confirm and rate(10 minutes)](/images/workshop/runbook/img059.jpg)
