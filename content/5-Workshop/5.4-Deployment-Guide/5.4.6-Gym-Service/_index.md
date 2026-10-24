---
title: "Gym Service"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.4.6. </b> "
---

The Gym Service handles gyms, PT listings, owner and admin tools, collaborations and QR check-in. It is the first service with a second secret of its own: the key that signs check-in QR codes.

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

| Item | Value |
|---|---|
| Logical database | `fitness_assistant_gym` (9 Prisma migrations) |
| Secret | `fitness-assistant/dev/gym-database` |
| Functions | `fitness-assistant-dev-gym`, `fitness-assistant-dev-gym-jobs` |
| Calls | Auth, User and (after [5.4.7](../5.4.7-Payment-Service/)) Payment Lambdas |

#### Step 1 — Create the database secret

**1.1 — Choose the secret type and fill in the pairs.** Open **Secrets Manager → Store a new secret**, choose **Other type of secret**, then add the same five key/value rows as the other services: `username`, `password`, `host`, `port` and `database` = `fitness_assistant_gym`. Then click **Next** and save the secret as `fitness-assistant/dev/gym-database`.

![Other type of secret, five key/value rows, Next button (password redacted)](/images/workshop/runbook/img104.jpg)

*The runbook has no screenshot of the final name and **Store** click.*

#### Step 2 — Upload the artifacts

**2.1 — Upload `gym-lambda.zip`.** Open the S3 bucket `fitness-assistant-deployments-dev-<account-id>`, click **Upload**, add `gym-lambda.zip` (~36 MiB — small enough for a direct upload, but S3 is used for consistency) and click **Upload**. `gym-migrate-lambda.zip` (~69 MiB) must go through S3 the same way.

![gym-lambda.zip in the file list and the Upload button](/images/workshop/runbook/img105.jpg)

**2.2 — Check the result.** The status page must show **Succeeded** next to the file. Click **Close**.

![Status Succeeded and the Close button](/images/workshop/runbook/img106.jpg)

{{% notice warning %}}
At this point in the runbook the Gym migration was skipped, even though the service has 9 migrations: the Lambda and its routes can be deployed, but every route that touches the database fails until `fitness_assistant_gym` has its schema. The migration was run with a `fitness-assistant-dev-gym-migrate` function following the [common pattern](../#common-pattern) — it appears in the function list in [5.4.10](../5.4.10-Chat-Service-ECS/) — and the deployment status table records the Gym migration as complete.
{{% /notice %}}

#### Step 3 — Create the runtime role

**3.1 — Create the role.** In **IAM → Roles → Create role**, choose **AWS service → Lambda**, attach the two managed policies and name it `fitness-assistant-dev-gym-lambda-role`.

*The runbook has no screenshot of this action.*

**3.2 — Add the secret policy.** On the role, open **Add permissions → Create inline policy**, switch to **JSON**, and paste the policy below. Name it `fitness-assistant-dev-gym-database-secret`.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
    "Resource": "arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/gym-database*"
  }]
}
```

![JSON editor with the GetSecretValue / DescribeSecret statement](/images/workshop/runbook/img107.jpg)

**3.3 — Add the invoke policy.** Create a second inline policy in the same way, named `fitness-assistant-dev-gym-service-invoke`, allowing `lambda:InvokeFunction` on `fitness-assistant-dev-auth` and `fitness-assistant-dev-user` only.

![JSON editor with the lambda:InvokeFunction statement for Auth and User](/images/workshop/runbook/img108.jpg)

**3.4 — Check the role.** Both inline policies must now be listed on the role.

![The two inline policies listed on the role](/images/workshop/runbook/img109.jpg)

Payment is deliberately not in the invoke list yet — it is added in [5.4.7](../5.4.7-Payment-Service/#gym-to-payment) once the Payment Lambda exists.

#### Step 4 — Create the Gym Lambda

**4.1 — Fill in the function.** Open **Lambda → Create function**, keep **Author from scratch**, set the name to `fitness-assistant-dev-gym` and the runtime to **Node.js 22.x** (x86_64). Under **Additional settings → Custom execution role** choose `fitness-assistant-dev-gym-lambda-role`, then click **Create function**.

![Author from scratch, name, runtime Node.js 22.x and the existing role](/images/workshop/runbook/img110.jpg)

**4.2 — Set memory and timeout.** Open **Configuration → General configuration → Edit**, set **Memory** to `1024` MB and **Timeout** to `0` min `30` sec, then click **Save**.

![Memory 1024 MB, timeout 0 min 30 sec, Save](/images/workshop/runbook/img111.jpg)

**4.3 — Set the handler.** Open **Code → Runtime settings → Edit**, enter `dist/lambda.handler` and click **Save**.

![Handler dist/lambda.handler and Save](/images/workshop/runbook/img112.jpg)

**4.4 — Load the code.** Open **Upload from → Amazon S3 location**, keep **Copy mode**, paste `s3://fitness-assistant-deployments-dev-<account-id>/gym-lambda.zip` and click **Update**.

![S3 link to gym-lambda.zip and Update](/images/workshop/runbook/img113.jpg)

#### Step 5 — Environment variables and VPC

**5.1 — Add the variables.** Open **Configuration → Environment variables → Edit** and add:

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/gym-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `INTERNAL_SERVICE_SECRET` | the shared service-to-service value |
| `CHECKIN_TOKEN_SECRET` | a new, strong random value |

![Six variables listed, with the Edit button (both secrets redacted)](/images/workshop/runbook/img114.jpg)

`CHECKIN_TOKEN_SECRET` must be different from `INTERNAL_SERVICE_SECRET`: it signs the QR codes shown to gym members, so leaking one must not compromise the other. `PAYMENT_LAMBDA_NAME` and `FITNESS_LAMBDA_NAME` are not set yet.

**5.2 — Attach the VPC.** Open **Configuration → VPC → Edit**, choose the project VPC (`10.0.0.0/16`), select both private app subnets (`private-app-a` and `private-app-b`) and the `fitness-assistant-dev-lambda-sg` security group, then click **Save**.

![VPC, the two private app subnets, Lambda security group and Save](/images/workshop/runbook/img115.jpg)

#### Step 6 — Connect the Gym Lambda to API Gateway

**6.1 — Create the integration.** In **API Gateway → fitness-assistant-dev-api → Integrations → Create**, choose **Lambda function**, region `ap-southeast-1`, pick `fitness-assistant-dev-gym` and keep payload format `2.0`.

![Integration type Lambda function and the Gym Lambda selected](/images/workshop/runbook/img116.jpg)

**6.2 — Attach the routes.** Create the root + greedy route pair for each prefix and attach each to this integration:

```
ANY /gyms             ANY /gyms/{proxy+}
ANY /pt               ANY /pt/{proxy+}
ANY /me               ANY /me/{proxy+}
ANY /owner            ANY /owner/{proxy+}
ANY /admin            ANY /admin/{proxy+}
ANY /collaborations   ANY /collaborations/{proxy+}
```

**6.3 — Check one route.** Under **Attach integrations to routes**, select a route such as `ANY /collaborations`; the details on the right must show `fitness-assistant-dev-gym`.

![Route ANY /collaborations selected, Lambda function fitness-assistant-dev-gym](/images/workshop/runbook/img117.jpg)

{{% notice note %}}
`/me`, `/admin` and `/pt` can already exist from the User Service. An HTTP API cannot route the same method and path to two integrations, so when the console reports an existing route it is **not** overwritten — the conflict is resolved by checking which service's code actually owns that path. The Payment Service later avoids the problem entirely by using more specific prefixes such as `/me/wallet`.
{{% /notice %}}

The API now routes:

```
fitness-assistant-dev-api
├── /auth/*          → Auth Lambda
├── User routes      → User Lambda
├── Fitness routes   → Fitness Lambda
└── Gym routes       → Gym Lambda ──► Auth / User Lambda, Aurora (fitness_assistant_gym)
```

#### Step 7 — Create the jobs Lambda

`fitness-assistant-dev-gym-jobs` uses the same role and artifact as the Gym Lambda.

**7.1 — Fill in the function.** Open **Lambda → Create function**, keep **Author from scratch**, set the name to `fitness-assistant-dev-gym-jobs`, runtime **Node.js 22.x**, and under **Additional settings → Custom execution role** choose `fitness-assistant-dev-gym-lambda-role`. Then click **Create function**.

![Author from scratch, name gym-jobs, runtime Node.js 22.x and the existing role](/images/workshop/runbook/img118.jpg)

**7.2 — Set memory and timeout.** **Configuration → General configuration → Edit**: **Memory** `1024` MB, **Timeout** `1` min `0` sec, then **Save**.

![Memory 1024 MB, timeout 1 min 0 sec, Save](/images/workshop/runbook/img119.jpg)

**7.3 — Set the handler.** **Code → Runtime settings → Edit**: `dist/jobs-lambda.handler`, then **Save**.

![Handler dist/jobs-lambda.handler and Save](/images/workshop/runbook/img120.jpg)

**7.4 — Load the code.** **Upload from → Amazon S3 location**: paste the same `gym-lambda.zip` link, keep **Copy mode**, click **Update**.

![Same S3 link to gym-lambda.zip and Update](/images/workshop/runbook/img121.jpg)

**7.5 — Attach the VPC.** **Configuration → VPC → Edit**: same VPC, subnets and security group as the Gym Lambda, then **Save**. Copy the environment variables as well, including `CHECKIN_TOKEN_SECRET`.

![VPC, the two private app subnets, Lambda security group and Save](/images/workshop/runbook/img122.jpg)

#### Step 8 — Scheduler role and schedules

**8.1 — Create the scheduler role.** Create `fitness-assistant-dev-gym-jobs-scheduler-role` (trust `scheduler.amazonaws.com`) with an inline policy `fitness-assistant-dev-invoke-gym-jobs` allowing `lambda:InvokeFunction` on the Gym jobs Lambda only.

*The runbook has no screenshot of this action.*

**8.2 — Create the two schedules** in **EventBridge → Schedules**:

| Schedule | Rate | Payload |
|---|---|---|
| `fitness-assistant-dev-gym-membership-payout` | `rate(10 minutes)` | `{"job":"membership-payout-sweep"}` |
| `fitness-assistant-dev-gym-referral-settlement` | `rate(10 minutes)` | `{"job":"referral-settlement-sweep"}` |

Both: flexible window off, enabled, maximum event age 5 minutes, 2 retry attempts, no DLQ, AWS-owned key, the existing scheduler role. Both jobs need the Payment Service, which is why the Gym jobs Lambda also receives `PAYMENT_LAMBDA_NAME` in the next page.

*The runbook has no screenshot of the schedule creation.*
