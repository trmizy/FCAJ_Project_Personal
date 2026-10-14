---
title: "5.4.5 Fitness Service"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.4.5. </b> "
---

The Fitness Service (exercises, workouts, nutrition, training cycles, coaching data) was the first service whose artifacts were too large for a direct console upload, so its code is attached from the deployments bucket.

| Item | Value |
|---|---|
| Logical database | `fitness_assistant_fitness` (48 Prisma migrations) |
| Secret | `fitness-assistant/dev/fitness-database` |
| Functions | `fitness-assistant-dev-fitness`, `fitness-assistant-dev-fitness-jobs`, temporary `fitness-assistant-dev-fitness-migrate` |
| Calls | Auth and User Lambdas (direct invoke) |

#### Step 1 — Upload the migration artifact to the deployments bucket

**S3 → `fitness-assistant-deployments-dev-<account-id>` → Upload** `backend/services/fitness-service/artifacts/fitness-migrate-lambda.zip`. The object stays private.

![Upload to the deployments bucket](/images/workshop/runbook/img060.jpg)

![Upload of fitness-migrate-lambda.zip (70.8 MB) in progress](/images/workshop/runbook/img061.jpg)

![Upload succeeded](/images/workshop/runbook/img062.jpg)

#### Step 2 — Create the migration role

**IAM → Roles → Create role → AWS service → Lambda**, managed policies `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole`, name `fitness-assistant-dev-fitness-migrate-role`.

![Role name fitness-assistant-dev-fitness-migrate-role](/images/workshop/runbook/img064.jpg)

![The two managed policies](/images/workshop/runbook/img063.jpg)

Then **Permissions → Add permissions → Create inline policy → JSON** — read access to this service's secret only:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": "arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/fitness-database*"
    }
  ]
}
```

![Add permissions → Create inline policy](/images/workshop/runbook/img065.jpg)

![Inline policy scoped to the Fitness database secret](/images/workshop/runbook/img066.jpg)

![Policy name fitness-assistant-dev-fitness-migration-secret](/images/workshop/runbook/img067.jpg)

#### Step 3 — Create the migration Lambda and run the migrations

**Lambda → Create function → Author from scratch**: `fitness-assistant-dev-fitness-migrate`, Node.js 22.x, x86_64, existing role `fitness-assistant-dev-fitness-migrate-role`.

![Create function fitness-assistant-dev-fitness-migrate](/images/workshop/runbook/img075.jpg)

| Setting | Value |
|---|---|
| Memory / timeout | 1024 MB / **15 minutes** (48 migrations) |
| Handler | `dist/migrate-lambda.handler` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` (no need to set `AWS_REGION` — Lambda provides it) |
| VPC | `private-app-a` + `private-app-b`, `fitness-assistant-dev-lambda-sg` |

![Memory 1024 MB and timeout 15 minutes](/images/workshop/runbook/img068.jpg)

![Handler dist/migrate-lambda.handler on x86_64](/images/workshop/runbook/img069.jpg)

![DATABASE_SECRET_ID for the Fitness database](/images/workshop/runbook/img070.jpg)

![VPC: both private app subnets and the Lambda security group](/images/workshop/runbook/img071.jpg)

Attach the code with **Code → Upload from → Amazon S3 location**, pasting the object's S3 URI and keeping **Copy mode**.

![Code → Update from a file in Amazon S3](/images/workshop/runbook/img072.jpg)

![S3 link to fitness-migrate-lambda.zip, copy mode](/images/workshop/runbook/img073.jpg)

![Code properties: 70.8 MB package loaded from S3](/images/workshop/runbook/img074.jpg)

Before invoking, re-check VPC, handler, environment and role once more, then invoke the function with `{}`. After all 48 migrations were applied, the temporary migration Lambda was deleted — the green "Successfully deleted function: fitness-assistant-dev-fitness-migrate" banner is visible in the next screenshots.

#### Step 4 — Upload the main artifact

Upload `fitness-lambda.zip` to the same deployments bucket.

![fitness-lambda.zip (53.3 MB) uploaded to the deployments bucket](/images/workshop/runbook/img076.jpg)

#### Step 5 — Create the runtime role

Create `fitness-assistant-dev-fitness-lambda-role` (AWS service → Lambda, the same two managed policies).

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img077.jpg)

![Managed policies attached to the role](/images/workshop/runbook/img078.jpg)

![Role name fitness-assistant-dev-fitness-lambda-role and its trust policy](/images/workshop/runbook/img079.jpg)

Add two inline policies: `fitness-assistant-dev-fitness-database-secret` (the same secret statement as in Step 2) and `fitness-assistant-dev-fitness-service-invoke`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user"
      ]
    }
  ]
}
```

![Create inline policy on the runtime role](/images/workshop/runbook/img080.jpg)

![Inline policy for the Fitness database secret](/images/workshop/runbook/img081.jpg)

No S3, SQS, Bedrock or Redis permissions are added — the Fitness Service does not use them in AWS.

#### Step 6 — Create the Fitness Lambda

**Lambda → Create function**: `fitness-assistant-dev-fitness`, Node.js 22.x, x86_64, role `fitness-assistant-dev-fitness-lambda-role`; 1024 MB, 30 s; handler `dist/lambda.handler`; code from `s3://fitness-assistant-deployments-dev-<account-id>/fitness-lambda.zip` (copy mode).

![Create function fitness-assistant-dev-fitness](/images/workshop/runbook/img085.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img082.jpg)

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `FITNESS_DISABLE_REDIS` | `true` |
| `INTERNAL_SERVICE_SECRET` | the shared value used by Auth/User |

![Fitness Lambda environment variables (secret redacted)](/images/workshop/runbook/img083.jpg)

`AI_SERVICE_URL`, `CHAT_SERVICE_URL`, `REDIS_HOST`, `REDIS_PORT` and `PEXELS_API_KEY` are left unset because those dependencies are not deployed or not enabled.

![Fitness Lambda VPC configuration](/images/workshop/runbook/img084.jpg)

#### Step 7 — Connect the Fitness Lambda to API Gateway

Create a Lambda integration `fitness-assistant-dev-fitness` (payload 2.0). Then, for each public prefix, create **both** the root route and the greedy route so that `/workouts` and `/workouts/...` both resolve:

```
ANY /exercises         ANY /exercises/{proxy+}
ANY /workouts          ANY /workouts/{proxy+}
ANY /nutrition         ANY /nutrition/{proxy+}
ANY /stats             ANY /stats/{proxy+}
ANY /food              ANY /food/{proxy+}
ANY /training-cycles   ANY /training-cycles/{proxy+}
ANY /coach             ANY /coach/{proxy+}
ANY /equipment         ANY /equipment/{proxy+}
ANY /imports           ANY /imports/{proxy+}
ANY /exports           ANY /exports/{proxy+}
ANY /templates         ANY /templates/{proxy+}
```

`/internal`, `/internal/{proxy+}` and `/{proxy+}` are not created, and the existing global `GET /health` (owned by Auth) is not duplicated.

![Lambda integration for fitness-assistant-dev-fitness](/images/workshop/runbook/img086.jpg)

![Routes attached to the Fitness integration](/images/workshop/runbook/img087.jpg)

#### Step 8 — Create the jobs Lambda

`fitness-assistant-dev-fitness-jobs`: same role, same `fitness-lambda.zip` from S3, handler `dist/jobs-lambda.handler`, 1024 MB, 1 minute, same VPC and the same environment variables as the HTTP Lambda. It runs two jobs: `workout-upcoming-reminder` and `workout-unfinished-reminder`.

![Create function fitness-assistant-dev-fitness-jobs](/images/workshop/runbook/img088.jpg)

![Jobs Lambda VPC configuration](/images/workshop/runbook/img089.jpg)

![Jobs Lambda environment variables (secret redacted)](/images/workshop/runbook/img090.jpg)

#### Step 9 — Create the scheduler role

Custom trust policy for `scheduler.amazonaws.com`, role name `fitness-assistant-dev-fitness-jobs-scheduler-role`, inline policy `fitness-assistant-dev-invoke-fitness-jobs` allowing `lambda:InvokeFunction` on the jobs Lambda only.

![Custom trust policy for EventBridge Scheduler](/images/workshop/runbook/img091.jpg)

![Role name fitness-assistant-dev-fitness-jobs-scheduler-role](/images/workshop/runbook/img092.jpg)

![Inline policy limited to fitness-assistant-dev-fitness-jobs](/images/workshop/runbook/img093.jpg)

![Policy name fitness-assistant-dev-invoke-fitness-jobs](/images/workshop/runbook/img094.jpg)

#### Step 10 — Create the two reminder schedules

| Schedule | Rate | Payload | What it does |
|---|---|---|---|
| `fitness-assistant-dev-workout-upcoming-reminder` | `rate(30 minutes)` | `{"job": "workout-upcoming-reminder"}` | Sweeps today's `NOT_STARTED` workouts that have not been reminded yet |
| `fitness-assistant-dev-workout-unfinished-reminder` | `rate(30 minutes)` | `{"job": "workout-unfinished-reminder"}` | Reminds about `IN_PROGRESS` workouts started at least 3 hours ago |

Both use the `Asia/Saigon` time zone, flexible window off, state enabled, action NONE, retry (5 minutes / 2 attempts), no DLQ, AWS-owned key and the existing scheduler role.

![Schedule fitness-assistant-dev-workout-upcoming-reminder: recurring, rate-based, Asia/Saigon](/images/workshop/runbook/img095.jpg)

![rate(30 minutes), flexible window off](/images/workshop/runbook/img096.jpg)

![Target: AWS Lambda Invoke](/images/workshop/runbook/img097.jpg)

![Payload {"job": "workout-upcoming-reminder"}](/images/workshop/runbook/img098.jpg)

![Retry: maximum age 5 minutes, 2 attempts, no DLQ](/images/workshop/runbook/img099.jpg)

![Settings with the existing scheduler role](/images/workshop/runbook/img100.jpg)

![Second schedule fitness-assistant-dev-workout-unfinished-reminder](/images/workshop/runbook/img101.jpg)

![Payload {"job": "workout-unfinished-reminder"}](/images/workshop/runbook/img102.jpg)

![Settings for the second schedule](/images/workshop/runbook/img103.jpg)

{{% notice note %}}
The upcoming-workout reminder only has day granularity: the current schema stores no planned start time, so the job cannot send "your workout starts in 30 minutes". It reminds about workouts scheduled for today that have not been reminded yet.
{{% /notice %}}
