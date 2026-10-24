---
title: "Auth Service and API Gateway"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.4.2. </b> "
---

Auth is the first service every user flow depends on, so it was deployed first, together with the HTTP API that all other Lambda services later attach to. Its logical database is `fitness_assistant` and its secret is `fitness-assistant/dev/database`.

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

#### Step 1 — Run the Auth schema migration

A temporary migration Lambda, `fitness-assistant-dev-auth-migrate`, was created following the [common pattern](../#common-pattern) and invoked once. The sub-steps below configure it and run it.

**1.1 — Set memory and timeout.** Open **Lambda → Functions → `fitness-assistant-dev-auth-migrate` → Configuration → General configuration → Edit**. Enter these values, then click **Save**:

```text
Memory:  1024 MB
Timeout: 5 min 0 sec
```

![Edit basic settings: memory 1024 MB, timeout 5 minutes, Save](/images/workshop/runbook/img003.jpg)

**1.2 — Open the VPC settings.** In **Configuration → VPC**, click **Edit**.

![Configuration → VPC with the Edit button marked](/images/workshop/runbook/img004.jpg)

**1.3 — Attach the function to the private subnets.** In **Edit VPC**, select the VPC `10.0.0.0/16`, both private app subnets (`fitness-assistant-dev-private-app-a` and `-b`) and the security group `fitness-assistant-dev-lambda-sg`, then click **Save**.

![Edit VPC: VPC, two private app subnets and the Lambda security group, then Save](/images/workshop/runbook/img005.jpg)

**1.4 — Set the secret name.** In **Configuration → Environment variables → Edit**, add the following key and value, then click **Save**:

```text
Key:   DATABASE_SECRET_ID
Value: fitness-assistant/dev/database
```

The variable now appears in the list.

![Environment variable DATABASE_SECRET_ID = fitness-assistant/dev/database](/images/workshop/runbook/img006.jpg)

**1.5 — Invoke the migration.** Open the **Test** tab, create a test event with this body, and click **Test**:

```json
{}
```

![Test tab: the Test button at the bottom of the page](/images/workshop/runbook/img002.jpg)

**1.6 — Read the result.** The function must finish with **Executing function: succeeded**, and the response must contain `"status":"ok"`, `"exitCode":0` and the line about the 7 migrations in `prisma/migrations`. All 7 Prisma migrations of the Auth database are applied.

![Result: succeeded, status ok, exitCode 0, 7 migrations found](/images/workshop/runbook/img001.jpg)

Once Auth's own Lambda was verified against Aurora (Step 3), the temporary migration Lambda was deleted.

#### Step 2 — Force the Auth Lambda to pick up a rotated credential

The Auth Lambda caches its database secret per execution environment. After the Aurora password was changed in Secrets Manager, warm containers could still hold the old credential. To force fresh execution environments, add a harmless variable:

**2.1 — Add `DEPLOY_REVISION`.** In **Lambda → `fitness-assistant-dev-auth` → Configuration → Environment variables → Edit**, click **Add environment variable**, enter the key and value below, then click **Save**:

```text
Key:   DEPLOY_REVISION
Value: 20260827-1
```

```
DEPLOY_REVISION = 20260827-1
```

![Adding DEPLOY_REVISION: Add environment variable, new key and value, Save](/images/workshop/runbook/img007.jpg)

The code never reads it; changing the configuration is enough to recycle the environments.

#### Step 3 — Smoke-test a route that really queries the database

**3.1 — Create the test event.** In **`fitness-assistant-dev-auth` → Test**, choose **Create new event** and give it this name:

```text
auth-login-db-smoke
```

Paste the API Gateway v2.0 event below for `POST /auth/login` with an e-mail address that does not exist, then click **Test**:

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

![Test event auth-login-db-smoke: Create new event, event name, Test](/images/workshop/runbook/img008.jpg)

**Expected result:** `statusCode: 401` (invalid credentials). That is a pass: it proves the chain `Auth Lambda → Secrets Manager → Prisma Linux engine → Aurora → users table` works. The response must **not** contain `P1000`, `P1001`, `PrismaClientInitializationError`, `Can't reach database` or `relation "users" does not exist`. A 400 means the payload shape is wrong; a 500 means reading the CloudWatch log before changing anything.

{{% notice tip %}}
Keep Aurora's minimum capacity at **0.5 ACU** while services are still being deployed. With 0 ACU the cluster auto-pauses after a few idle minutes, and the resume delay makes the next smoke test look like a failure.
{{% /notice %}}

#### Step 4 — Create the HTTP API with the Auth integration

**4.1 — Name the API and add the Lambda integration.** In **API Gateway → Create API → HTTP API → Build**, enter this API name and keep the IP address type **IPv4**:

```text
fitness-assistant-dev-api
```

Under **Integrations**, choose type **Lambda**, region `ap-southeast-1`, the function `fitness-assistant-dev-auth` (never the migration Lambda) and payload format version **2.0**. Then click **Next**.

![Configure API: API name, IPv4, Lambda integration and function, Next](/images/workshop/runbook/img009.jpg)

#### Step 5 — Create explicit public routes

**5.1 — Add one route per public endpoint.** On **Configure routes**, add the routes below, each with the integration target `fitness-assistant-dev-auth`. The screenshot shows all 12 rows.

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

![The 12 explicit Auth routes, all pointing at fitness-assistant-dev-auth](/images/workshop/runbook/img010.jpg)

These routes are **not** created: `/auth/internal/*` (service-to-service endpoints protected by `INTERNAL_SERVICE_SECRET`, called by other Lambdas through direct invoke instead) and `GET /metrics` (in-memory Prometheus counters are meaningless when every Lambda execution environment keeps its own). A catch-all `ANY /auth/{proxy+}` would have been faster, but it would also have published `/auth/internal/*` to the internet — explicit routes keep the security boundary.

#### Step 6 — Keep the `$default` stage with auto-deploy

**6.1 — Define the stage.** Click **Next** to reach **Define stages**. Keep this stage name with **Auto-deploy** switched on, so route changes go live without a manual deployment and the invoke URL stays short:

```text
$default
```

Then click **Next**.

![Define stages: $default, Auto-deploy on, Next](/images/workshop/runbook/img011.jpg)

**6.2 — Review and create.** Check that the 12 routes point at `fitness-assistant-dev-auth` and that the stage is `$default (Auto-deploy: enabled)`, then scroll down and click **Create**.

![Review and create: the 12 routes and the $default stage](/images/workshop/runbook/img012.jpg)

The API's invoke URL (`https://<api-id>.execute-api.ap-southeast-1.amazonaws.com`) is what the frontend and the `PAYMENT_PUBLIC_URL` / `AUTH_SERVICE_URL` variables use from here on.

#### Step 7 — Allow the S3 frontend to call the API (CORS) {#cors}

**7.1 — Configure CORS.** After the frontend is published ([5.4.3](../5.4.3-Frontend-S3/)), open **API Gateway → `fitness-assistant-dev-api` → CORS → Configure**, fill in the fields below and click **Save**.

| Setting | Value |
|---|---|
| Access-Control-Allow-Origin | `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com` (HTTP, because the S3 website endpoint has no HTTPS) |
| Allow headers | `authorization`, `content-type` |
| Allow methods | `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS` (the screenshot also lists `HEAD` and `*`) |
| Max age | `300` |
| Allow credentials | Off — the frontend sends `Authorization: Bearer <token>`, not cross-site cookies |

![CORS: origin, headers, methods, max age, credentials off, Save](/images/workshop/runbook/img017.jpg)

**Verification:** open the frontend `/login`, open the browser Network tab and log in with a non-existent e-mail. A `401 {"error":"Invalid credentials"}` from API Gateway proves the full path `S3 website → API Gateway → Auth Lambda → Prisma → Aurora`. A CORS error, 404 or 500 means checking the origin value, the route list and the Lambda log respectively.
