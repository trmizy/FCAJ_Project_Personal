---
title: "5.4.2 Auth Service and API Gateway"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.4.2. </b> "
---

Auth is the first service every user flow depends on, so it was deployed first, together with the HTTP API that all other Lambda services later attach to. Its logical database is `fitness_assistant` and its secret is `fitness-assistant/dev/database`.

#### Step 1 — Run the Auth schema migration

A temporary migration Lambda was created following the [common pattern](../#common-pattern) (1024 MB, 5 minute timeout, VPC attached, `DATABASE_SECRET_ID = fitness-assistant/dev/database`) and invoked once. All 7 Prisma migrations were applied.

![Auth migration Lambda — test invocation result](/images/workshop/runbook/img001.jpg)

![Auth migration — 7 migrations applied successfully](/images/workshop/runbook/img002.jpg)

![Migration Lambda basic settings (memory and timeout)](/images/workshop/runbook/img003.jpg)

![Migration Lambda attached to the VPC](/images/workshop/runbook/img004.jpg)

![VPC configuration: both private app subnets and fitness-assistant-dev-lambda-sg](/images/workshop/runbook/img005.jpg)

![Environment variable DATABASE_SECRET_ID = fitness-assistant/dev/database](/images/workshop/runbook/img006.jpg)

Once Auth's own Lambda was verified against Aurora (Step 3), the temporary migration Lambda was deleted.

#### Step 2 — Force the Auth Lambda to pick up a rotated credential

The Auth Lambda caches its database secret per execution environment. After the Aurora password was changed in Secrets Manager, warm containers could still hold the old credential. To force fresh execution environments, add a harmless variable in **Lambda → `fitness-assistant-dev-auth` → Configuration → Environment variables → Edit**:

```
DEPLOY_REVISION = 20260827-1
```

The code never reads it; changing the configuration is enough to recycle the environments.

![Adding DEPLOY_REVISION to recycle execution environments](/images/workshop/runbook/img007.jpg)

#### Step 3 — Smoke-test a route that really queries the database

In **`fitness-assistant-dev-auth` → Test → Create new event** (`auth-login-db-smoke`), send an API Gateway v2.0 event for `POST /auth/login` with an e-mail address that does not exist:

```json
{
  "version": "2.0",
  "routeKey": "POST /auth/login",
  "rawPath": "/auth/login",
  "rawQueryString": "",
  "headers": {
    "content-type": "application/json",
    "accept": "application/json",
    "host": "example.execute-api.ap-southeast-1.amazonaws.com"
  },
  "requestContext": {
    "accountId": "123456789012",
    "apiId": "test",
    "domainName": "example.execute-api.ap-southeast-1.amazonaws.com",
    "domainPrefix": "example",
    "http": {
      "method": "POST",
      "path": "/auth/login",
      "protocol": "HTTP/1.1",
      "sourceIp": "127.0.0.1",
      "userAgent": "AWS-Lambda-Test"
    },
    "requestId": "auth-db-smoke",
    "routeKey": "POST /auth/login",
    "stage": "$default",
    "time": "27/Aug/2026:09:30:00 +0700",
    "timeEpoch": 1787797800000
  },
  "body": "{\"email\":\"aws-smoke-nonexistent@example.com\",\"password\":\"NotARealPassword123!\"}",
  "isBase64Encoded": false
}
```

![Lambda test event auth-login-db-smoke](/images/workshop/runbook/img008.jpg)

**Expected result:** `statusCode: 401` (invalid credentials). That is a pass: it proves the chain `Auth Lambda → Secrets Manager → Prisma Linux engine → Aurora → users table` works. The response must **not** contain `P1000`, `P1001`, `PrismaClientInitializationError`, `Can't reach database` or `relation "users" does not exist`. A 400 means the payload shape is wrong; a 500 means reading the CloudWatch log before changing anything.

{{% notice tip %}}
Keep Aurora's minimum capacity at **0.5 ACU** while services are still being deployed. With 0 ACU the cluster auto-pauses after a few idle minutes, and the resume delay makes the next smoke test look like a failure.
{{% /notice %}}

#### Step 4 — Create the HTTP API with the Auth integration

**API Gateway → Create API → HTTP API**:

1. API name: `fitness-assistant-dev-api`, IP address type IPv4.
2. **Add integration** → type **Lambda**, region `ap-southeast-1`, function `fitness-assistant-dev-auth`, payload format version **2.0**. (Never the migration Lambda.)

![Create HTTP API fitness-assistant-dev-api with the Auth Lambda integration](/images/workshop/runbook/img009.jpg)

#### Step 5 — Create explicit public routes

On **Configure routes**, add one route per public endpoint, all pointing at `fitness-assistant-dev-auth`:

```
POST   /auth/register
POST   /auth/register/verify
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
POST   /auth/verify
PATCH  /auth/me
GET    /auth/users
PATCH  /auth/users/{userId}/role
PATCH  /auth/users/{userId}/disable
PATCH  /auth/users/{userId}/enable
GET    /health
```

![The 12 explicit Auth routes](/images/workshop/runbook/img010.jpg)

These routes are **not** created: `/auth/internal/*` (service-to-service endpoints protected by `INTERNAL_SERVICE_SECRET`, called by other Lambdas through direct invoke instead) and `GET /metrics` (in-memory Prometheus counters are meaningless when every Lambda execution environment keeps its own). A catch-all `ANY /auth/{proxy+}` would have been faster, but it would also have published `/auth/internal/*` to the internet — explicit routes keep the security boundary.

#### Step 6 — Keep the `$default` stage with auto-deploy

Keep the default `$default` stage with **Auto-deploy** enabled, so route changes go live without a manual deployment and the invoke URL stays short.

![$default stage with auto-deploy](/images/workshop/runbook/img011.jpg)

![Review and create: 12 routes → fitness-assistant-dev-auth, stage $default](/images/workshop/runbook/img012.jpg)

The API's invoke URL (`https://<api-id>.execute-api.ap-southeast-1.amazonaws.com`) is what the frontend and the `PAYMENT_PUBLIC_URL` / `AUTH_SERVICE_URL` variables use from here on.

#### Step 7 — Allow the S3 frontend to call the API (CORS) {#cors}

After the frontend is published ([5.4.3](../5.4.3-Frontend-S3/)), configure **API Gateway → `fitness-assistant-dev-api` → CORS → Configure**:

| Setting | Value |
|---|---|
| Access-Control-Allow-Origin | `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com` (HTTP, because the S3 website endpoint has no HTTPS) |
| Allow headers | `authorization`, `content-type` |
| Allow methods | `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` |
| Max age | `300` |
| Allow credentials | Off — the frontend sends `Authorization: Bearer <token>`, not cross-site cookies |

![CORS configuration for the S3 website origin](/images/workshop/runbook/img017.jpg)

**Verification:** open the frontend `/login`, open the browser Network tab and log in with a non-existent e-mail. A `401 {"error":"Invalid credentials"}` from API Gateway proves the full path `S3 website → API Gateway → Auth Lambda → Prisma → Aurora`. A CORS error, 404 or 500 means checking the origin value, the route list and the Lambda log respectively.
