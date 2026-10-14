---
title: "5.4.6 Gym Service"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.4.6. </b> "
---

The Gym Service handles gyms, PT listings, owner and admin tools, collaborations and QR check-in. It is the first service with a second secret of its own: the key that signs check-in QR codes.

| Item | Value |
|---|---|
| Logical database | `fitness_assistant_gym` (9 Prisma migrations) |
| Secret | `fitness-assistant/dev/gym-database` |
| Functions | `fitness-assistant-dev-gym`, `fitness-assistant-dev-gym-jobs` |
| Calls | Auth, User and (after [5.4.7](../5.4.7-Payment-Service/)) Payment Lambdas |

#### Step 1 — Create the database secret

Same structure as the other services, with `database = fitness_assistant_gym`.

![Secret fitness-assistant/dev/gym-database (password redacted)](/images/workshop/runbook/img104.jpg)

#### Step 2 — Upload the artifacts

Upload `gym-migrate-lambda.zip` (~69 MiB, so S3 is mandatory) and `gym-lambda.zip` (~36 MiB — small enough for a direct upload, but S3 is used for consistency) to `fitness-assistant-deployments-dev-<account-id>`.

![Uploading gym-lambda.zip (36 MB) to the deployments bucket](/images/workshop/runbook/img105.jpg)

![Upload succeeded](/images/workshop/runbook/img106.jpg)

{{% notice warning %}}
At this point in the runbook the Gym migration was skipped, even though the service has 9 migrations: the Lambda and its routes can be deployed, but every route that touches the database fails until `fitness_assistant_gym` has its schema. The migration was run with a `fitness-assistant-dev-gym-migrate` function following the [common pattern](../#common-pattern) — it appears in the function list in [5.4.10](../5.4.10-Chat-Service-ECS/) — and the deployment status table records the Gym migration as complete.
{{% /notice %}}

#### Step 3 — Create the runtime role

`fitness-assistant-dev-gym-lambda-role` (AWS service → Lambda, the two managed policies), with two inline policies:

- `fitness-assistant-dev-gym-database-secret` — `secretsmanager:GetSecretValue` / `DescribeSecret` on `fitness-assistant/dev/gym-database*`.
- `fitness-assistant-dev-gym-service-invoke` — `lambda:InvokeFunction` on `fitness-assistant-dev-auth` and `fitness-assistant-dev-user`.

![Inline policy for the Gym database secret](/images/workshop/runbook/img107.jpg)

![Inline policy allowing invoke of the Auth and User Lambdas](/images/workshop/runbook/img108.jpg)

![Both inline policies attached to the role](/images/workshop/runbook/img109.jpg)

Payment is deliberately not in the invoke list yet — it is added in [5.4.7](../5.4.7-Payment-Service/#gym-to-payment) once the Payment Lambda exists.

#### Step 4 — Create the Gym Lambda

`fitness-assistant-dev-gym`, Node.js 22.x, x86_64, role `fitness-assistant-dev-gym-lambda-role`, 1024 MB, 30 s, handler `dist/lambda.handler`, code from `s3://fitness-assistant-deployments-dev-<account-id>/gym-lambda.zip` (copy mode).

![Create function fitness-assistant-dev-gym](/images/workshop/runbook/img110.jpg)

![Memory 1024 MB, timeout 30 seconds](/images/workshop/runbook/img111.jpg)

![Handler dist/lambda.handler](/images/workshop/runbook/img112.jpg)

![Code from gym-lambda.zip in S3, copy mode](/images/workshop/runbook/img113.jpg)

#### Step 5 — Environment variables

| Variable | Value |
|---|---|
| `NODE_ENV` | `production` |
| `DATABASE_SECRET_ID` | `fitness-assistant/dev/gym-database` |
| `AUTH_LAMBDA_NAME` | `fitness-assistant-dev-auth` |
| `USER_LAMBDA_NAME` | `fitness-assistant-dev-user` |
| `INTERNAL_SERVICE_SECRET` | the shared service-to-service value |
| `CHECKIN_TOKEN_SECRET` | a new, strong random value |

![Gym Lambda environment variables (both secrets redacted)](/images/workshop/runbook/img114.jpg)

`CHECKIN_TOKEN_SECRET` must be different from `INTERNAL_SERVICE_SECRET`: it signs the QR codes shown to gym members, so leaking one must not compromise the other. `PAYMENT_LAMBDA_NAME` and `FITNESS_LAMBDA_NAME` are not set yet.

![Gym Lambda VPC configuration](/images/workshop/runbook/img115.jpg)

#### Step 6 — Connect the Gym Lambda to API Gateway

Create the Lambda integration `fitness-assistant-dev-gym` (payload 2.0), then the root + greedy route pair for each prefix:

```
ANY /gyms             ANY /gyms/{proxy+}
ANY /pt               ANY /pt/{proxy+}
ANY /me               ANY /me/{proxy+}
ANY /owner            ANY /owner/{proxy+}
ANY /admin            ANY /admin/{proxy+}
ANY /collaborations   ANY /collaborations/{proxy+}
```

![Lambda integration for fitness-assistant-dev-gym](/images/workshop/runbook/img116.jpg)

![Gym routes attached to the integration](/images/workshop/runbook/img117.jpg)

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

`fitness-assistant-dev-gym-jobs`: same role and artifact, handler `dist/jobs-lambda.handler`, 1024 MB, 1 minute, same VPC and environment variables (including `CHECKIN_TOKEN_SECRET`).

![Create function fitness-assistant-dev-gym-jobs](/images/workshop/runbook/img118.jpg)

![Memory 1024 MB, timeout 1 minute](/images/workshop/runbook/img119.jpg)

![Handler dist/jobs-lambda.handler](/images/workshop/runbook/img120.jpg)

![Same gym-lambda.zip from S3](/images/workshop/runbook/img121.jpg)

![Jobs Lambda VPC configuration](/images/workshop/runbook/img122.jpg)

#### Step 8 — Scheduler role and schedules

Create `fitness-assistant-dev-gym-jobs-scheduler-role` (trust `scheduler.amazonaws.com`) with an inline policy `fitness-assistant-dev-invoke-gym-jobs` allowing `lambda:InvokeFunction` on the Gym jobs Lambda only, then two schedules:

| Schedule | Rate | Payload |
|---|---|---|
| `fitness-assistant-dev-gym-membership-payout` | `rate(10 minutes)` | `{"job":"membership-payout-sweep"}` |
| `fitness-assistant-dev-gym-referral-settlement` | `rate(10 minutes)` | `{"job":"referral-settlement-sweep"}` |

Both: flexible window off, enabled, maximum event age 5 minutes, 2 retry attempts, no DLQ, AWS-owned key, the existing scheduler role. Both jobs need the Payment Service, which is why the Gym jobs Lambda also receives `PAYMENT_LAMBDA_NAME` in the next page.
