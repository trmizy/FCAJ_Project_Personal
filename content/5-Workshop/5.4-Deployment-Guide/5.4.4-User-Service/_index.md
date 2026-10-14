---
title: "5.4.4 User Service"
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

#### Step 1 — Create the database secret

**Secrets Manager → Store a new secret → Other type of secret** with `username`, `password` (the Aurora master password, taken directly from Secrets Manager), `host` (Aurora cluster endpoint), `port = 5432` and `database = fitness_assistant_user`. Name it `fitness-assistant/dev/user-database`, rotation off.

![Secret fitness-assistant/dev/user-database (password redacted)](/images/workshop/runbook/img018.jpg)

#### Step 2 — Create the execution role

**IAM → Roles → Create role**, trusted entity **AWS service → Lambda**, managed policies `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole` only — not `AdministratorAccess`, `AmazonRDSFullAccess`, `SecretsManagerReadWrite` or `AmazonS3FullAccess`. Name: `fitness-assistant-dev-user-lambda-role`.

![Role fitness-assistant-dev-user-lambda-role with the two managed policies](/images/workshop/runbook/img019.jpg)

#### Step 3 — Allow the role to read only its own secret

**Role → Permissions → Add permissions → Create inline policy → JSON**, replacing `SECRET_ARN` with the full ARN copied from the secret's page. `"Resource": "*"` is not acceptable.

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

![Inline policy JSON scoped to the User database secret](/images/workshop/runbook/img020.jpg)

![Policy name fitness-assistant-dev-user-read-database-secret](/images/workshop/runbook/img021.jpg)

![The role now has two managed policies and one inline policy](/images/workshop/runbook/img022.jpg)

The schema was then migrated with a temporary `fitness-assistant-dev-user-migrate` Lambda using the [common pattern](../#common-pattern). The outbound network needed by the User Lambda was added at this point too — see [5.4.1](../5.4.1-Shared-Network/).

#### Step 4 — Create the User Lambda

**Lambda → Create function → Author from scratch**: name `fitness-assistant-dev-user`, Node.js 22.x, x86_64, existing role `fitness-assistant-dev-user-lambda-role`.

![Create function fitness-assistant-dev-user](/images/workshop/runbook/img029.jpg)

Then configure:

| Setting | Value |
|---|---|
| VPC | `fitness-assistant-dev-vpc`, subnets `private-app-a` + `private-app-b`, SG `fitness-assistant-dev-lambda-sg` |
| Memory / timeout | 1024 MB / 30 s |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/user-database` |
| `NODE_ENV` | `production` |
| `AUTH_SERVICE_URL` | the API Gateway invoke URL |
| `USER_UPLOAD_BUCKET` | `fitness-assistant-uploads-dev-<account-id>` |
| `INTERNAL_SERVICE_SECRET` | the **same** value as the Auth Lambda (one shared secret, never a new one) |

![User Lambda environment variables (INTERNAL_SERVICE_SECRET redacted)](/images/workshop/runbook/img030.jpg)

Variables for services not deployed yet (`GYM_SERVICE_URL`, `PAYMENT_SERVICE_URL`, `AI_SERVICE_URL`, `CHAT_SERVICE_URL`) are left out until those services exist.

#### Step 5 — Allow profile-photo uploads to one S3 prefix

Create an inline policy `fitness-assistant-dev-user-profile-upload` that grants `s3:PutObject` on `arn:aws:s3:::fitness-assistant-uploads-dev-<account-id>/profile-photos/*` only — not `AmazonS3FullAccess`.

![Inline policy for profile-photos/* uploads](/images/workshop/runbook/img031.jpg)

![Role permissions after adding the upload policy](/images/workshop/runbook/img032.jpg)

#### Step 6 — Upload the code

**Code → Upload from → .zip file**: `backend/services/user-service/artifacts/user-lambda.zip`, then **Runtime settings → Edit → Handler** `dist/lambda.handler`.

![User Lambda code uploaded with handler dist/lambda.handler](/images/workshop/runbook/img033.jpg)

#### Step 7 — Add the API Gateway integration

**API Gateway → `fitness-assistant-dev-api` → Integrations → Manage integrations → Create**: Lambda function `fitness-assistant-dev-user`, payload format 2.0. API Gateway adds the invoke permission on the function when the console asks.

![Creating the Lambda integration for fitness-assistant-dev-user](/images/workshop/runbook/img034.jpg)

![The API now has Auth and User integrations](/images/workshop/runbook/img035.jpg)

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

![Creating the User Service routes](/images/workshop/runbook/img036.jpg)

`ANY /{proxy+}` and `ANY /internal/{proxy+}` are never created — `/internal/*` is service-to-service only. `/webhooks/dropbox-sign` is also skipped because it is disabled while `REQUIRE_CONTRACT_ESIGN=false`.

{{% notice warning %}}
A route that exists but has no integration attached returns `{"message":"Not Found"}`. After creating routes, always open **Integrations → Attach integrations to routes** and check that every route has a target.
{{% /notice %}}

#### Step 9 — Call Auth directly with Lambda Invoke

Some User flows call `/auth/internal/*`, which is intentionally not public. Instead of exposing it, the User Lambda invokes the Auth Lambda directly. Add an inline policy `fitness-assistant-dev-user-invoke-auth`:

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

![Inline policy allowing lambda:InvokeFunction on the Auth Lambda only](/images/workshop/runbook/img037.jpg)

![Policy name fitness-assistant-dev-user-invoke-auth](/images/workshop/runbook/img038.jpg)

Then add `AUTH_LAMBDA_NAME = fitness-assistant-dev-auth` to the User Lambda's environment (keeping `AUTH_SERVICE_URL` for now).

![AUTH_LAMBDA_NAME added (secret value redacted)](/images/workshop/runbook/img039.jpg)

![User Lambda environment after the change (secret value redacted)](/images/workshop/runbook/img040.jpg)

#### Step 10 — Final S3 permissions and CORS for presigned uploads

Profile photos, PT application documents and contract PDFs all live in the private uploads bucket. The inline policy `fitness-assistant-dev-user-profile-upload` is replaced with three statements, each limited to one prefix:

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

No `s3:*`, no `s3:ListBucket`. The browser uploads directly to S3 with a presigned URL, so the uploads bucket gets a CORS rule (**Permissions → Cross-origin resource sharing**) while staying private:

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

![CORS rule on the private uploads bucket](/images/workshop/runbook/img041.jpg)

#### Step 11 — Create the jobs Lambda

Background jobs run in a separate function so the HTTP Lambda never runs timers. Create `fitness-assistant-dev-user-jobs` (Node.js 22.x, x86_64, role `fitness-assistant-dev-user-lambda-role`), with the same VPC settings, 1024 MB and a 1 minute timeout.

![Create function fitness-assistant-dev-user-jobs](/images/workshop/runbook/img042.jpg)

![Jobs Lambda VPC settings](/images/workshop/runbook/img043.jpg)

![Jobs Lambda memory and timeout](/images/workshop/runbook/img044.jpg)

Upload the same `user-lambda.zip` and set the handler to `dist/jobs-lambda.handler`.

![Same artifact uploaded to the jobs Lambda](/images/workshop/runbook/img045.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img046.jpg)

Environment: `DATABASE_SECRET_ID`, `NODE_ENV`, `AUTH_LAMBDA_NAME`, `USER_UPLOAD_BUCKET`, `REQUIRE_CONTRACT_ESIGN=false` and the shared `INTERNAL_SERVICE_SECRET`.

![Jobs Lambda environment variables (secret redacted)](/images/workshop/runbook/img047.jpg)

#### Step 12 — Create the scheduler role

**IAM → Roles → Create role** with a custom trust policy for EventBridge Scheduler:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "scheduler.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
```

Name it `fitness-assistant-dev-user-jobs-scheduler-role` and add an inline policy `fitness-assistant-dev-invoke-user-jobs` that allows `lambda:InvokeFunction` on `fitness-assistant-dev-user-jobs` only. The scheduler never reuses a Lambda execution role and never gets `lambda:*`.

![Custom trust policy for scheduler.amazonaws.com](/images/workshop/runbook/img048.jpg)

![Inline policy allowing lambda:InvokeFunction on the User jobs Lambda only](/images/workshop/runbook/img049.jpg)

![Policy name fitness-assistant-dev-invoke-user-jobs](/images/workshop/runbook/img050.jpg)

#### Step 13 — Create the three schedules

**Amazon EventBridge → Scheduler → Schedules → Create schedule**, one per job, each sending `{"job": "<name>"}` to `fitness-assistant-dev-user-jobs`:

| Schedule | Rate | Payload |
|---|---|---|
| `fitness-assistant-dev-user-session-settlement` | `rate(5 minutes)` | `{"job": "session-settlement"}` |
| `fitness-assistant-dev-user-session-auto-confirm` | `rate(10 minutes)` | `{"job": "session-auto-confirm"}` |
| `fitness-assistant-dev-user-reschedule-expiry` | `rate(10 minutes)` | `{"job": "reschedule-expiry"}` |

Common settings: recurring rate-based schedule in the `Asia/Saigon` (UTC+07:00) time zone, flexible time window off, state enabled, action after completion **NONE**, retry enabled with maximum event age 5 minutes and 2 retry attempts, no DLQ for DEV, AWS-owned encryption key, and **Use existing role → `fitness-assistant-dev-user-jobs-scheduler-role`** (not *Create new role*).

![EventBridge Scheduler → Schedules → Create schedule](/images/workshop/runbook/img051.jpg)

![Schedule name fitness-assistant-dev-user-session-settlement in the default group](/images/workshop/runbook/img052.jpg)

![Recurring rate-based schedule: rate(5 minutes), Asia/Saigon, flexible window off](/images/workshop/runbook/img053.jpg)

![Timeframe left empty (runs indefinitely)](/images/workshop/runbook/img054.jpg)

![Target: AWS Lambda Invoke](/images/workshop/runbook/img055.jpg)

![Target fitness-assistant-dev-user-jobs with payload {"job": "session-settlement"}](/images/workshop/runbook/img056.jpg)

![Settings: enabled, action NONE, retry 5 min / 2 attempts, no DLQ, existing scheduler role](/images/workshop/runbook/img057.jpg)

![Schedule fitness-assistant-dev-user-session-settlement created](/images/workshop/runbook/img058.jpg)

![Second schedule fitness-assistant-dev-user-session-auto-confirm at rate(10 minutes)](/images/workshop/runbook/img059.jpg)
