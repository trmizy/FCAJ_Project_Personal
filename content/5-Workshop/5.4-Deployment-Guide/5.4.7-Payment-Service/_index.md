---
title: "5.4.7 Payment Service"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.4.7. </b> "
---

The Payment Service handles wallet top-ups, PT-contract payments, withdrawals and the provider webhooks. Its sensitive internal endpoints (checkout, wallet transfer, contract release, no-show, termination, gym withdrawals) are only reachable through direct Lambda invoke from Gym, User and AI — never through the public API.

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

| Item | Value |
|---|---|
| Logical database | `fitness_assistant_payment` (11 Prisma migrations) |
| Secret | `fitness-assistant/dev/payment-database` |
| Functions | `fitness-assistant-dev-payment`, `fitness-assistant-dev-payment-jobs`, temporary `fitness-assistant-dev-payment-migrate` |
| Provider | `PAYMENT_PROVIDER=VNPAY` (MoMo, PayOS, ZaloPay supported by the code) |

With Payment's database the Aurora cluster reaches this layout:

```
fitness-assistant-dev-aurora
├── fitness_assistant          → Auth
├── fitness_assistant_user     → User
├── fitness_assistant_fitness  → Fitness
├── fitness_assistant_gym      → Gym
└── fitness_assistant_payment  → Payment
```

#### Step 1 — Secret and artifacts

**1.1 — Create the secret.** In **Secrets Manager → Store a new secret** choose **Other type of secret**, enter the same five pairs as the other services with `database` = `fitness_assistant_payment`, and name it `fitness-assistant/dev/payment-database`.

*The runbook has no screenshot of this action; the form is the same as in [5.4.6 Step 1](../5.4.6-Gym-Service/#step-1--create-the-database-secret).*

**1.2 — Upload both zips.** In the deployments bucket click **Upload**, add `payment-lambda.zip` (36 MB) and `payment-migrate-lambda.zip` (~69 MiB, so S3 is mandatory), and start the upload. The screenshot shows both files in the list (105.1 MB in total).

![payment-lambda.zip and payment-migrate-lambda.zip uploading](/images/workshop/runbook/img123.jpg)

#### Step 2 — Migration role

**2.1 — Create the role.** In **IAM → Roles → Create role** choose **AWS service → Lambda**, attach `AWSLambdaBasicExecutionRole` and `AWSLambdaVPCAccessExecutionRole`, and name it `fitness-assistant-dev-payment-migrate-role`.

![New role with its two managed policies](/images/workshop/runbook/img124.jpg)

**2.2 — Write the secret policy.** On the role open **Add permissions → Create inline policy**, switch to **JSON** and allow `secretsmanager:GetSecretValue` / `DescribeSecret` on `fitness-assistant/dev/payment-database*` only.

![JSON editor with the Payment secret statement](/images/workshop/runbook/img125.jpg)

**2.3 — Name and create the policy.** Enter the name `fitness-assistant-dev-payment-migration-secret` and click **Create policy**.

![Policy name and the Create policy button](/images/workshop/runbook/img126.jpg)

#### Step 3 — Migration Lambda

**3.1 — Fill in the function.** **Lambda → Create function**, keep **Author from scratch**, name `fitness-assistant-dev-payment-migrate`, runtime **Node.js 22.x**, custom execution role `fitness-assistant-dev-payment-migrate-role`, then **Create function**.

![Author from scratch, name, runtime and the migrate role](/images/workshop/runbook/img127.jpg)

**3.2 — Set memory and timeout.** **Configuration → General configuration → Edit**: **Memory** `1024` MB, **Timeout** `15` min `0` sec, **Save**.

![Memory 1024 MB, timeout 15 minutes, Save](/images/workshop/runbook/img128.jpg)

**3.3 — Set the handler.** **Code → Runtime settings → Edit**: `dist/migrate-lambda.handler`, **Save**.

![Handler dist/migrate-lambda.handler and Save](/images/workshop/runbook/img129.jpg)

**3.4 — Add the environment variable.** **Configuration → Environment variables → Edit**: key `DATABASE_SECRET_ID`, value `fitness-assistant/dev/payment-database`, **Save**.

![DATABASE_SECRET_ID for the Payment database and Save](/images/workshop/runbook/img130.jpg)

**3.5 — Attach the VPC.** **Configuration → VPC → Edit**: the project VPC, both private app subnets and `fitness-assistant-dev-lambda-sg`, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img131.jpg)

**3.6 — Load the code.** **Upload from → Amazon S3 location**: `s3://fitness-assistant-deployments-dev-<account-id>/payment-migrate-lambda.zip`, copy mode, **Update**.

*The runbook has no screenshot of this action; it is the same dialog as in [5.4.6 Step 4.4](../5.4.6-Gym-Service/#step-4--create-the-gym-lambda).*

#### Step 4 — Run the 11 migrations

**4.1 — Invoke once.** Check that the secret really says `database = fitness_assistant_payment`, then open the **Test** tab and invoke the function once with `{}`. The handler has a safety guard that only accepts this database name, creates the logical database if it is missing, and only runs `prisma migrate deploy`.

![Test tab: Executing function succeeded and the JSON response](/images/workshop/runbook/img132.jpg)

**Expected result:** `database = fitness_assistant_payment`, `migrateExitCode = 0`, `11 migrations found`, `All migrations have been successfully applied.`

#### Step 5 — Runtime role

**5.1 — Create the role.** **IAM → Roles → Create role**, AWS service → Lambda, the same two managed policies, name `fitness-assistant-dev-payment-lambda-role`.

![The new role with its two managed policies](/images/workshop/runbook/img133.jpg)

**5.2 — Add two inline policies.** `fitness-assistant-dev-payment-database-secret` for the Payment secret, and `fitness-assistant-dev-payment-service-invoke`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user",
        "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-gym"
      ]
    }
  ]
}
```

![Role with two managed and two inline policies](/images/workshop/runbook/img134.jpg)

#### Step 6 — Payment Lambda

**6.1 — Fill in the function.** **Lambda → Create function**, name `fitness-assistant-dev-payment`, runtime **Node.js 22.x**, custom execution role `fitness-assistant-dev-payment-lambda-role`, **Create function**.

![Author from scratch, name, runtime and the Payment role](/images/workshop/runbook/img135.jpg)

**6.2 — Set memory and timeout.** **Memory** `1024` MB, **Timeout** `0` min `30` sec, **Save**.

![Memory 1024 MB, timeout 30 seconds, Save](/images/workshop/runbook/img136.jpg)

**6.3 — Set the handler.** `dist/lambda.handler`, **Save**.

![Handler dist/lambda.handler and Save](/images/workshop/runbook/img137.jpg)

**6.4 — Load the code.** **Upload from → Amazon S3 location**: `s3://fitness-assistant-deployments-dev-<account-id>/payment-lambda.zip`, copy mode, **Update**.

![S3 link to payment-lambda.zip and Update](/images/workshop/runbook/img138.jpg)

**6.5 — Attach the VPC.** The same VPC, subnets and security group as the other database Lambdas, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img139.jpg)

**6.6 — Add the environment variables.**

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/payment-database` |
| `INTERNAL_SERVICE_SECRET` | the shared value |
| `AUTH_LAMBDA_NAME` / `USER_LAMBDA_NAME` / `GYM_LAMBDA_NAME` | the three function names |
| `PAYMENT_PROVIDER` | `VNPAY` |
| `VNPAY_SIMULATE` | `false` |
| `FRONTEND_URL` | the S3 website endpoint |
| `PAYMENT_PUBLIC_URL` | the API Gateway invoke URL (used to build provider callback URLs) |

Provider credentials (`VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`, MoMo / PayOS / ZaloPay keys) are only added once a real sandbox credential exists.

*The runbook has no screenshot of the environment-variable form for this function.*

#### Step 7 — API Gateway routes

**7.1 — Create the integration.** **API Gateway → fitness-assistant-dev-api → Integrations → Create**: Lambda function `fitness-assistant-dev-payment`, payload `2.0`.

*The runbook has no screenshot of this action; the form is the same as in [5.4.6 Step 6.1](../5.4.6-Gym-Service/#step-6--connect-the-gym-lambda-to-api-gateway).*

**7.2 — Create the routes.** `ANY /me` and `ANY /admin` are already owned by other services, so Payment uses specific prefixes:

| Group | Routes |
|---|---|
| Public payments and provider webhooks | `ANY /payments`, `ANY /payments/{proxy+}` — covers `GET /payments/webhook/vnpay`, `POST /payments/webhook/{provider}`, `GET /payments/vnpay/return` |
| User | `ANY /me/payments`, `/me/wallet`, `/me/pt-wallet`, `/me/withdrawals` — each with its `/{proxy+}` route |
| Admin | `ANY /admin/payments`, `ANY /admin/payments/{proxy+}` |

`/internal` and `/internal/{proxy+}` are never created.

**7.3 — Check the attachment.** Open **Integrations → Attach integrations to routes**, select each Payment route and confirm it points at `fitness-assistant-dev-payment` — a route without an integration returns `Not Found`.

![Route ANY /payments/{proxy+} showing Lambda function fitness-assistant-dev-payment](/images/workshop/runbook/img140.jpg)

#### Step 8 — Jobs Lambda and the reconciliation schedule

`fitness-assistant-dev-payment-jobs` uses the same role, artifact, VPC and environment as the HTTP Lambda.

**8.1 — Fill in the function.** **Lambda → Create function**, name `fitness-assistant-dev-payment-jobs`, runtime **Node.js 22.x**, role `fitness-assistant-dev-payment-lambda-role`, **Create function**.

![Author from scratch, name payment-jobs, runtime and the Payment role](/images/workshop/runbook/img141.jpg)

**8.2 — Set the handler.** `dist/jobs-lambda.handler`, **Save**.

![Handler dist/jobs-lambda.handler and Save](/images/workshop/runbook/img142.jpg)

**8.3 — Set memory and timeout.** **Memory** `1024` MB, **Timeout** `1` min `0` sec, **Save**.

![Memory 1024 MB, timeout 1 minute, Save](/images/workshop/runbook/img143.jpg)

**8.4 — Attach the VPC.** Same VPC, subnets and security group, **Save**. Load the same `payment-lambda.zip` code and copy the environment variables.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img144.jpg)

**8.5 — Create the scheduler role.** `fitness-assistant-dev-payment-jobs-scheduler-role` (trust `scheduler.amazonaws.com`, inline policy `fitness-assistant-dev-invoke-payment-jobs` for the Payment jobs Lambda only).

*The runbook has no screenshot of this action.*

**8.6 — Name the schedule.** **EventBridge → Schedules → Create schedule**: name `fitness-assistant-dev-payment-reconciliation`, **Recurring schedule**, **Rate-based schedule**, rate `5` `minutes`.

![Schedule name, Recurring schedule, Rate-based, rate 5 minutes](/images/workshop/runbook/img145.jpg)

**8.7 — Choose the target.** Select the **AWS Lambda — Invoke** tile, pick `fitness-assistant-dev-payment-jobs` and enter the payload `{"job": "reconciliation"}`.

![AWS Lambda Invoke, function payment-jobs and the reconciliation payload](/images/workshop/runbook/img146.jpg)

**8.8 — Choose the settings.** Keep retry on with maximum age `0` hours `5` minutes and `2` retry attempts, DLQ **None**, the AWS-owned key, and **Use existing role** with `fitness-assistant-dev-payment-jobs-scheduler-role`. Then click **Next** and create the schedule.

![Retry 5 minutes / 2 attempts, DLQ None, existing scheduler role, Next](/images/workshop/runbook/img147.jpg)

{{% notice note %}}
The banner at the top of the last three screenshots still names the previously created Gym schedule (`fitness-assistant-dev-gym-referral-settlement`); the form itself is for the Payment reconciliation schedule.
{{% /notice %}}

Every 5 minutes the reconciliation job polls the gateway for pending confirmations, retries activations and refund cancellations, and cleans up stale transactions.

#### Step 9 — Wire Gym to Payment {#gym-to-payment}

Gym was deployed before Payment existed, so it has to be told about it:

**9.1 — Add the variable to both Gym functions.** Add `PAYMENT_LAMBDA_NAME=fitness-assistant-dev-payment` to **both** `fitness-assistant-dev-gym` and `fitness-assistant-dev-gym-jobs` (payout and referral settlement also call Payment). No `PAYMENT_SERVICE_URL` is needed with direct invoke.

**9.2 — Extend the Gym role's invoke policy** (or add `fitness-assistant-dev-gym-invoke-payment`):

```json
{
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": [
    "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-auth",
    "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-user",
    "arn:aws:lambda:ap-southeast-1:<account-id>:function:fitness-assistant-dev-payment"
  ]
}
```

*The runbook has no screenshots of Step 9.*

The Gym scheduler role does not need this permission — the scheduler only invokes `gym-jobs`, and it is `gym-jobs` that calls Payment.

The payment loop is now closed:

```
Gym Lambda ──direct invoke──► Payment Lambda ──► Payment DB ──► Provider (VNPAY)
                                                                   │ webhook
Gym Lambda ◄──callback── Payment Lambda ◄── API Gateway /payments ◄┘
```

The remaining work for this service is configuring at least one real sandbox provider (VNPAY first, since it is the code default) with its callback/webhook URLs, so checkout can be tested end to end.
