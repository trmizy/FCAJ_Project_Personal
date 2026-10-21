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

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it. Where the runbook has no screenshot for an action, the text says so.

#### Step 1 — Upload the migration artifact to the deployments bucket

**1.1 — Open the upload page.** Open **S3 → `fitness-assistant-deployments-dev-<account-id>` → Upload** and click **Add files**. The destination shown is the deployments bucket.

![Upload page: destination bucket, Add files, Upload](/images/workshop/runbook/img060.jpg)

**1.2 — Select and upload the file.** Choose `backend/services/fitness-service/artifacts/fitness-migrate-lambda.zip` (70.8 MB) and click **Upload**. The object stays private. The status page shows the progress.

![Upload status: fitness-migrate-lambda.zip (70.8 MB) in progress](/images/workshop/runbook/img061.jpg)

**1.3 — Wait for success.** When the banner **Upload succeeded** appears and the file shows *Succeeded*, click **Close**.

![Upload succeeded: the file row and Close](/images/workshop/runbook/img062.jpg)

#### Step 2 — Create the migration role

**2.1 — Create the role.** Open **IAM → Roles → Create role**, choose **AWS service → Lambda** (the screen is the same as in step 5.1) and click **Next**. *The runbook has no screenshot of this screen for the migration role.*

**2.2 — Attach the managed policies.** Select `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole`. The review page lists both.

![Review: the two managed policies](/images/workshop/runbook/img063.jpg)

**2.3 — Name the role.** Enter the role name `fitness-assistant-dev-fitness-migrate-role` and click **Create role**.

![Role name fitness-assistant-dev-fitness-migrate-role](/images/workshop/runbook/img064.jpg)

**2.4 — Add an inline policy.** In the new role, open **Permissions → Add permissions → Create inline policy**.

![Add permissions menu: Create inline policy](/images/workshop/runbook/img065.jpg)

**2.5 — Paste the JSON.** Switch to the **JSON** tab and paste the policy below — read access to this service's secret only. Then click **Next**.

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

![Policy editor, JSON tab: the Resource line scoped to the Fitness database secret](/images/workshop/runbook/img066.jpg)

**2.6 — Name the policy.** Enter the policy name `fitness-assistant-dev-fitness-migration-secret` and click **Create policy**.

![Review and create: policy name, Create policy](/images/workshop/runbook/img067.jpg)

#### Step 3 — Create the migration Lambda and run the migrations

**3.1 — Create the function.** Open **Lambda → Create function**, choose **Author from scratch**, enter the name `fitness-assistant-dev-fitness-migrate`, runtime **Node.js 22.x**, and under **Additional settings → Custom execution role** pick the existing role `fitness-assistant-dev-fitness-migrate-role`. Then click **Create function**.

![Create function: Author from scratch, name, Node.js 22.x, existing role](/images/workshop/runbook/img075.jpg)

The remaining settings for this function:

| Setting | Value |
|---|---|
| Memory / timeout | 1024 MB / **15 minutes** (48 migrations) |
| Handler | `dist/migrate-lambda.handler` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` (no need to set `AWS_REGION` — Lambda provides it) |
| VPC | `private-app-a` + `private-app-b`, `fitness-assistant-dev-lambda-sg` |

**3.2 — Set memory and timeout.** In **Configuration → General configuration → Edit**, set **Memory** `1024` MB and **Timeout** `15` min `0` sec, then click **Save**.

![Edit basic settings: memory 1024 MB, timeout 15 minutes, Save](/images/workshop/runbook/img068.jpg)

**3.3 — Set the handler.** In **Runtime settings → Edit**, set **Handler** to `dist/migrate-lambda.handler`, keep architecture **x86_64** and click **Save**.

![Edit runtime settings: handler dist/migrate-lambda.handler, x86_64, Save](/images/workshop/runbook/img069.jpg)

**3.4 — Add the secret name.** In **Configuration → Environment variables → Edit**, add `DATABASE_SECRET_ID` = `fitness-assistant/dev/fitness-database` and click **Save**.

![Edit environment variables: DATABASE_SECRET_ID, Save](/images/workshop/runbook/img070.jpg)

**3.5 — Attach the VPC.** In **Configuration → VPC → Edit**, select the VPC, both private app subnets and `fitness-assistant-dev-lambda-sg`, then click **Save**.

![Edit VPC: both private app subnets and the Lambda security group, Save](/images/workshop/runbook/img071.jpg)

**3.6 — Open the code update menu.** On the **Code** tab, click **Update** and choose **Update from a file in Amazon S3**. (The ZIP is too large for a direct upload.)

![Code tab: Update menu, Update from a file in Amazon S3](/images/workshop/runbook/img072.jpg)

**3.7 — Point at the S3 object.** Keep **Copy mode (default)**, paste the object's S3 URI `s3://fitness-assistant-deployments-dev-<account-id>/fitness-migrate-lambda.zip` into **Amazon S3 link**, and click **Update**.

![Update from a file in Amazon S3: Copy mode, S3 link, Update](/images/workshop/runbook/img073.jpg)

**3.8 — Check the code properties.** The function now shows a 70.8 MB package with code storage mode *Copy (default)*.

![Code properties: 70.8 MB package loaded from S3, Copy mode](/images/workshop/runbook/img074.jpg)

Before invoking, re-check VPC, handler, environment and role once more, then invoke the function with `{}`. After all 48 migrations were applied, the temporary migration Lambda was deleted — the green "Successfully deleted function: fitness-assistant-dev-fitness-migrate" banner is visible in the next screenshots.

#### Step 4 — Upload the main artifact

**4.1 — Upload `fitness-lambda.zip`.** Repeat step 1 for `fitness-lambda.zip` (53.3 MB) in the same deployments bucket. When the upload finishes, check the *Succeeded* status and click **Close**.

![Upload succeeded: fitness-lambda.zip (53.3 MB), Close](/images/workshop/runbook/img076.jpg)

#### Step 5 — Create the runtime role

**5.1 — Choose the trusted entity.** Open **IAM → Roles → Create role**, choose **AWS service**, use case **Lambda**, and click **Next**.

![Select trusted entity: AWS service, Lambda, Next](/images/workshop/runbook/img077.jpg)

**5.2 — Attach the managed policies.** Select the same two managed policies, `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole`.

![Managed policies attached to the role](/images/workshop/runbook/img078.jpg)

**5.3 — Name the role.** Enter the role name `fitness-assistant-dev-fitness-lambda-role` and click **Create role**. The page also shows the trust policy for `lambda.amazonaws.com`.

![Role name fitness-assistant-dev-fitness-lambda-role](/images/workshop/runbook/img079.jpg)

**5.4 — Add the first inline policy.** In the role, open **Permissions → Add permissions → Create inline policy**.

![Add permissions menu: Create inline policy](/images/workshop/runbook/img080.jpg)

**5.5 — Secret policy.** On the **JSON** tab paste the same secret statement as in step 2.5, click **Next**, name it `fitness-assistant-dev-fitness-database-secret` and click **Create policy**.

![Policy editor, JSON tab: the Fitness database secret statement](/images/workshop/runbook/img081.jpg)

**5.6 — Invoke policy.** Create a second inline policy named `fitness-assistant-dev-fitness-service-invoke` with this JSON. *The runbook has no screenshot of it.*

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

No S3, SQS, Bedrock or Redis permissions are added — the Fitness Service does not use them in AWS.

#### Step 6 — Create the Fitness Lambda

**6.1 — Create the function.** Open **Lambda → Create function → Author from scratch**, enter the name `fitness-assistant-dev-fitness`, runtime **Node.js 22.x**, x86_64, the custom execution role `fitness-assistant-dev-fitness-lambda-role`, and click **Create function**.

![Create function: name fitness-assistant-dev-fitness, Node.js 22.x, custom execution role](/images/workshop/runbook/img085.jpg)

**6.2 — Attach the code.** Set memory to 1024 MB and timeout to 30 s, then on **Code → Update → Update from a file in Amazon S3** use `s3://fitness-assistant-deployments-dev-<account-id>/fitness-lambda.zip` in **Copy mode**, exactly as in steps 3.6–3.7. *The runbook has no screenshot of these screens for this function.*

**6.3 — Set the handler.** In **Runtime settings → Edit**, set **Handler** to `dist/lambda.handler` and click **Save**.

![Edit runtime settings: handler dist/lambda.handler, Save](/images/workshop/runbook/img082.jpg)

**6.4 — Add the environment variables** listed below in **Configuration → Environment variables → Edit**, click **Add environment variable** for each one, then **Save**.

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/fitness-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `FITNESS_DISABLE_REDIS` | `true` |
| `INTERNAL_SERVICE_SECRET` | the shared value used by Auth/User |

![Edit environment variables: the six variables, Add environment variable, Save (secret redacted)](/images/workshop/runbook/img083.jpg)

`AI_SERVICE_URL`, `CHAT_SERVICE_URL`, `REDIS_HOST`, `REDIS_PORT` and `PEXELS_API_KEY` are left unset because those dependencies are not deployed or not enabled.

**6.5 — Attach the VPC.** In **Configuration → VPC → Edit**, select the VPC, both private app subnets and `fitness-assistant-dev-lambda-sg`, then click **Save**.

![Edit VPC: both private app subnets and the Lambda security group, Save](/images/workshop/runbook/img084.jpg)

#### Step 7 — Connect the Fitness Lambda to API Gateway

**7.1 — Create the integration.** Open **API Gateway → `fitness-assistant-dev-api` → Integrations → Manage integrations → Create**. Choose **Lambda function**, region `ap-southeast-1`, function `fitness-assistant-dev-fitness`, payload format version **2.0**, keep **Grant API Gateway permission to invoke your Lambda function** on, and click **Create**.

![Create integration: Lambda function, region, function, payload 2.0, invoke permission, Create](/images/workshop/runbook/img086.jpg)

**7.2 — Create the routes.** For each public prefix, create **both** the root route and the greedy route so that `/workouts` and `/workouts/...` both resolve (**Routes → Create**, method `ANY`). *The runbook has no screenshot of route creation for this service; the procedure is the one shown in [5.4.4, step 8](../5.4.4-User-Service/).*

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

**7.3 — Check the attachment.** Open **Integrations → Attach integrations to routes**. Select a new route such as `ANY /exercises/{proxy+}`: its details show the Lambda function `fitness-assistant-dev-fitness`.

![Attach integrations to routes: ANY /exercises/{proxy+} points at fitness-assistant-dev-fitness](/images/workshop/runbook/img087.jpg)

#### Step 8 — Create the jobs Lambda

`fitness-assistant-dev-fitness-jobs`: same role, same `fitness-lambda.zip` from S3, handler `dist/jobs-lambda.handler`, 1024 MB, 1 minute, same VPC and the same environment variables as the HTTP Lambda. It runs two jobs: `workout-upcoming-reminder` and `workout-unfinished-reminder`.

**8.1 — Create the function.** Open **Lambda → Create function → Author from scratch**, enter the name `fitness-assistant-dev-fitness-jobs`, runtime **Node.js 22.x**, the custom execution role `fitness-assistant-dev-fitness-lambda-role`, and click **Create function**.

![Create function: name fitness-assistant-dev-fitness-jobs, Node.js 22.x, custom execution role](/images/workshop/runbook/img088.jpg)

**8.2 — Attach the VPC.** In **Configuration → VPC → Edit**, select the VPC, both private app subnets and the Lambda security group, then click **Save**.

![Edit VPC: both private app subnets and the Lambda security group, Save](/images/workshop/runbook/img089.jpg)

**8.3 — Add the environment variables** (the same six as the HTTP Lambda) in **Configuration → Environment variables → Edit → Save**. The list afterwards looks like this (secret redacted). *The runbook has no screenshot for the memory, timeout, handler and code settings of this function; they follow steps 3.2, 3.3, 3.6 and 3.7 with the values above.*

![Environment variables of the jobs Lambda: the Edit button and the six variables](/images/workshop/runbook/img090.jpg)

#### Step 9 — Create the scheduler role

**9.1 — Choose the custom trust policy.** Open **IAM → Roles → Create role**, choose **Custom trust policy** and paste the trust policy for `scheduler.amazonaws.com`, then continue without a managed policy.

![Create role: Custom trust policy for scheduler.amazonaws.com](/images/workshop/runbook/img091.jpg)

**9.2 — Name the role.** Enter the role name `fitness-assistant-dev-fitness-jobs-scheduler-role` and click **Create role**.

![Role name fitness-assistant-dev-fitness-jobs-scheduler-role](/images/workshop/runbook/img092.jpg)

**9.3 — Add the inline policy.** In the role, open **Add permissions → Create inline policy → JSON** and allow `lambda:InvokeFunction` on the jobs Lambda only, then click **Next**.

![Policy editor, JSON tab: lambda:InvokeFunction on fitness-assistant-dev-fitness-jobs](/images/workshop/runbook/img093.jpg)

**9.4 — Name the policy.** Enter the policy name `fitness-assistant-dev-invoke-fitness-jobs` and click **Create policy**.

![Review and create: policy name fitness-assistant-dev-invoke-fitness-jobs](/images/workshop/runbook/img094.jpg)

#### Step 10 — Create the two reminder schedules

| Schedule | Rate | Payload | What it does |
|---|---|---|---|
| `fitness-assistant-dev-workout-upcoming-reminder` | `rate(30 minutes)` | `{"job": "workout-upcoming-reminder"}` | Sweeps today's `NOT_STARTED` workouts that have not been reminded yet |
| `fitness-assistant-dev-workout-unfinished-reminder` | `rate(30 minutes)` | `{"job": "workout-unfinished-reminder"}` | Reminds about `IN_PROGRESS` workouts started at least 3 hours ago |

Both use the `Asia/Saigon` time zone, flexible window off, state enabled, action NONE, retry (5 minutes / 2 attempts), no DLQ, AWS-owned key and the existing scheduler role. The screenshots first follow the upcoming-reminder schedule.

**10.1 — Name it and set the pattern.** In **EventBridge → Scheduler → Schedules → Create schedule**, enter the schedule name `fitness-assistant-dev-workout-upcoming-reminder`, keep the `default` group, choose **Recurring schedule**, time zone `(UTC+07:00) Asia/Saigon` and **Rate-based schedule**.

![Specify schedule detail: name, default group, recurring, Asia/Saigon, rate-based](/images/workshop/runbook/img095.jpg)

**10.2 — Set the rate.** Enter rate `30` `minutes` and keep **Flexible time window** `Off`. Leave the timeframe empty and click **Next**.

![Rate expression: 30 minutes, flexible time window off](/images/workshop/runbook/img096.jpg)

**10.3 — Choose the target.** With **Templated targets** selected, pick **AWS Lambda → Invoke**.

![Select target: Templated targets, AWS Lambda Invoke](/images/workshop/runbook/img097.jpg)

**10.4 — Function and payload.** Choose the Lambda function `fitness-assistant-dev-fitness-jobs`, enter the payload `{"job": "workout-upcoming-reminder"}` and click **Next**.

![Invoke: function fitness-assistant-dev-fitness-jobs, payload workout-upcoming-reminder, Next](/images/workshop/runbook/img098.jpg)

**10.5 — Retry settings.** Keep **Retry** on with maximum age of event `5` minutes (`0` hours) and `2` retry attempts, and dead-letter queue **None**.

![Retry policy: Retry on, maximum age 5 minutes, 2 attempts, DLQ None](/images/workshop/runbook/img099.jpg)

**10.6 — Permissions.** Under **Execution role**, choose **Use existing role** and select `fitness-assistant-dev-fitness-jobs-scheduler-role`, then click **Next** and **Create schedule** on the review page. *In this particular full-page screenshot the Retry switch is shown off; the retry values come from the previous screenshot, so check this switch when you repeat the step.*

![Settings: Use existing role, the scheduler role, Next](/images/workshop/runbook/img100.jpg)

**10.7 — Second schedule: name and rate.** Create the second schedule the same way: name `fitness-assistant-dev-workout-unfinished-reminder`, recurring, rate-based, rate `30` `minutes`.

![Second schedule: name fitness-assistant-dev-workout-unfinished-reminder, rate 30 minutes](/images/workshop/runbook/img101.jpg)

**10.8 — Second schedule: payload.** Target **AWS Lambda → Invoke**, function `fitness-assistant-dev-fitness-jobs`, payload `{"job": "workout-unfinished-reminder"}`, then **Next**.

![Invoke: function fitness-assistant-dev-fitness-jobs, payload workout-unfinished-reminder, Next](/images/workshop/runbook/img102.jpg)

**10.9 — Second schedule: settings.** Keep: **Enable**, action **NONE**, **Retry** on with maximum age `5` minutes and `2` attempts, DLQ **None**, and **Use existing role** with the same scheduler role. Then create the schedule.

![Settings: Enable, Retry 5 minutes / 2 attempts, DLQ None, existing role](/images/workshop/runbook/img103.jpg)

{{% notice note %}}
The upcoming-workout reminder only has day granularity: the current schema stores no planned start time, so the job cannot send "your workout starts in 30 minutes". It reminds about workouts scheduled for today that have not been reminded yet.
{{% /notice %}}
