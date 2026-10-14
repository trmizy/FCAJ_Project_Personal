---
title: "5.4.7 Payment Service"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.4.7. </b> "
---

The Payment Service handles wallet top-ups, PT-contract payments, withdrawals and the provider webhooks. Its sensitive internal endpoints (checkout, wallet transfer, contract release, no-show, termination, gym withdrawals) are only reachable through direct Lambda invoke from Gym, User and AI — never through the public API.

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

Create `fitness-assistant/dev/payment-database` (`database = fitness_assistant_payment`), then upload `payment-migrate-lambda.zip` (~69 MiB) and `payment-lambda.zip` to the deployments bucket.

![Uploading payment-lambda.zip and payment-migrate-lambda.zip (105.1 MB)](/images/workshop/runbook/img123.jpg)

#### Step 2 — Migration role

`fitness-assistant-dev-payment-migrate-role` with the two managed policies and an inline policy `fitness-assistant-dev-payment-migration-secret` for `fitness-assistant/dev/payment-database*` only.

![Role fitness-assistant-dev-payment-migrate-role](/images/workshop/runbook/img124.jpg)

![Inline policy for the Payment database secret](/images/workshop/runbook/img125.jpg)

![Policy name fitness-assistant-dev-payment-migration-secret](/images/workshop/runbook/img126.jpg)

#### Step 3 — Migration Lambda

`fitness-assistant-dev-payment-migrate`: 1024 MB, 15 minutes, handler `dist/migrate-lambda.handler`, `DATABASE_SECRET_ID=fitness-assistant/dev/payment-database`, both private app subnets and the Lambda SG, code from S3 in copy mode.

![Create function fitness-assistant-dev-payment-migrate](/images/workshop/runbook/img127.jpg)

![Memory 1024 MB, timeout 15 minutes](/images/workshop/runbook/img128.jpg)

![Handler dist/migrate-lambda.handler](/images/workshop/runbook/img129.jpg)

![DATABASE_SECRET_ID for the Payment database](/images/workshop/runbook/img130.jpg)

![VPC configuration](/images/workshop/runbook/img131.jpg)

#### Step 4 — Run the 11 migrations

Check that the secret really says `database = fitness_assistant_payment`, then invoke the function once with `{}`. The handler has a safety guard that only accepts this database name, creates the logical database if it is missing, and only runs `prisma migrate deploy`.

**Expected result:** `database = fitness_assistant_payment`, `migrateExitCode = 0`, `11 migrations found`, `All migrations have been successfully applied.`

![Migration result: status ok, fitness_assistant_payment, migrations applied](/images/workshop/runbook/img132.jpg)

#### Step 5 — Runtime role

`fitness-assistant-dev-payment-lambda-role` with the two managed policies plus:

- `fitness-assistant-dev-payment-database-secret` for the Payment secret;
- `fitness-assistant-dev-payment-service-invoke`:

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

![Role fitness-assistant-dev-payment-lambda-role](/images/workshop/runbook/img133.jpg)

![The role with its two managed and two inline policies](/images/workshop/runbook/img134.jpg)

#### Step 6 — Payment Lambda

`fitness-assistant-dev-payment`, 1024 MB, 30 s, handler `dist/lambda.handler`, code `s3://fitness-assistant-deployments-dev-<account-id>/payment-lambda.zip`, the same VPC as the other database Lambdas.

![Create function fitness-assistant-dev-payment](/images/workshop/runbook/img135.jpg)

![Memory 1024 MB, timeout 30 seconds](/images/workshop/runbook/img136.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img137.jpg)

![Code from payment-lambda.zip in S3](/images/workshop/runbook/img138.jpg)

![Payment Lambda VPC configuration](/images/workshop/runbook/img139.jpg)

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

#### Step 7 — API Gateway routes

Create the Lambda integration `fitness-assistant-dev-payment` (payload 2.0). `ANY /me` and `ANY /admin` are already owned by other services, so Payment uses specific prefixes:

| Group | Routes |
|---|---|
| Public payments and provider webhooks | `ANY /payments`, `ANY /payments/{proxy+}` — covers `GET /payments/webhook/vnpay`, `POST /payments/webhook/{provider}`, `GET /payments/vnpay/return` |
| User | `ANY /me/payments`, `/me/wallet`, `/me/pt-wallet`, `/me/withdrawals` — each with its `/{proxy+}` route |
| Admin | `ANY /admin/payments`, `ANY /admin/payments/{proxy+}` |

`/internal` and `/internal/{proxy+}` are never created. Afterwards, open **Integrations → Attach integrations to routes** and confirm every Payment route points at `fitness-assistant-dev-payment` — a route without an integration returns `Not Found`.

![Payment routes attached to the Payment integration](/images/workshop/runbook/img140.jpg)

#### Step 8 — Jobs Lambda and the reconciliation schedule

`fitness-assistant-dev-payment-jobs`: same role, artifact, VPC and environment as the HTTP Lambda, handler `dist/jobs-lambda.handler`, 1024 MB, 1 minute.

![Create function fitness-assistant-dev-payment-jobs](/images/workshop/runbook/img141.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img142.jpg)

![Memory 1024 MB, timeout 1 minute](/images/workshop/runbook/img143.jpg)

![Jobs Lambda VPC configuration](/images/workshop/runbook/img144.jpg)

Create `fitness-assistant-dev-payment-jobs-scheduler-role` (trust `scheduler.amazonaws.com`, inline policy `fitness-assistant-dev-invoke-payment-jobs` for the Payment jobs Lambda only), then the schedule `fitness-assistant-dev-payment-reconciliation`: `rate(5 minutes)`, payload `{"job": "reconciliation"}`, enabled, 5 minutes / 2 retries, no DLQ, AWS-owned key.

![Schedule fitness-assistant-dev-payment-reconciliation at rate(5 minutes)](/images/workshop/runbook/img145.jpg)

![Target fitness-assistant-dev-payment-jobs with payload {"job": "reconciliation"}](/images/workshop/runbook/img146.jpg)

![Settings with the Payment scheduler role](/images/workshop/runbook/img147.jpg)

Every 5 minutes the reconciliation job polls the gateway for pending confirmations, retries activations and refund cancellations, and cleans up stale transactions.

#### Step 9 — Wire Gym to Payment {#gym-to-payment}

Gym was deployed before Payment existed, so it has to be told about it:

1. Add `PAYMENT_LAMBDA_NAME=fitness-assistant-dev-payment` to **both** `fitness-assistant-dev-gym` and `fitness-assistant-dev-gym-jobs` (payout and referral settlement also call Payment). No `PAYMENT_SERVICE_URL` is needed with direct invoke.
2. Extend the Gym role's invoke policy (or add `fitness-assistant-dev-gym-invoke-payment`):

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

The Gym scheduler role does not need this permission — the scheduler only invokes `gym-jobs`, and it is `gym-jobs` that calls Payment.

The payment loop is now closed:

```
Gym Lambda ──direct invoke──► Payment Lambda ──► Payment DB ──► Provider (VNPAY)
                                                                   │ webhook
Gym Lambda ◄──callback── Payment Lambda ◄── API Gateway /payments ◄┘
```

The remaining work for this service is configuring at least one real sandbox provider (VNPAY first, since it is the code default) with its callback/webhook URLs, so checkout can be tested end to end.
