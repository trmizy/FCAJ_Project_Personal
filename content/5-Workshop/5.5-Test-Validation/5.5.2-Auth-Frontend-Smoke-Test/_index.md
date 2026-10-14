---
title: "5.5.2 Frontend, API Gateway and Auth"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.5.2. </b> "
---

These checks walk the main request path one layer at a time, so a failure points directly at the layer that broke.

| # | Test | How | Expected result | Status |
|---|---|---|---|---|
| T1 | Lambda → Aurora | Lambda console test event `auth-login-db-smoke` (`POST /auth/login`, unknown e-mail) | `statusCode: 401` "invalid credentials", **no** `P1000`, `P1001`, `PrismaClientInitializationError`, `Can't reach database` or `relation "users" does not exist` | Passed |
| T2 | Static hosting + SPA fallback | Open `http://<frontend-bucket>.s3-website-ap-southeast-1.amazonaws.com/login` directly | The login page renders (not an S3 404) | Passed |
| T3 | Browser → API Gateway → Lambda → Aurora | On `/login`, open DevTools → Network and log in with an unknown e-mail | `POST /auth/login` → `401 {"error":"Invalid credentials"}`, no CORS error | Passed |
| T4 | Every route has an integration | API Gateway → *Integrations → Attach integrations to routes* | Each route shows its Lambda/HTTP target; none returns `{"message":"Not Found"}` | Checked per service during deployment |
| T5 | Internal endpoints are not public | `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/internal/anything` and `/auth/internal/users/batch` | `404 Not Found` from API Gateway (no such route) | To include in the final E2E pass |
| T6 | AI routes are rate-limited | Send several `POST /ai/ask` requests within one second | Some return `429 Too Many Requests`; the frontend shows a "too many requests" message instead of retrying in a loop | To include in the final E2E pass |
| T7 | Real login and profile | Register, verify, log in, open profile/onboarding | 200 responses from `/auth/*` and the User routes, data persisted in Aurora | To include in the final E2E pass |

#### Evidence

T1 — the smoke-test event used against the Auth Lambda:

![Test event auth-login-db-smoke](/images/workshop/runbook/img008.jpg)

T2 — the frontend build published to the website bucket (the `/login` route then loaded directly from the website endpoint):

![Frontend build uploaded to the S3 website bucket](/images/workshop/runbook/img016.jpg)

T4 — routes attached to their integrations, e.g. the Fitness, Payment and AI routes:

![Fitness routes attached to fitness-assistant-dev-fitness](/images/workshop/runbook/img087.jpg)

![Payment routes attached to fitness-assistant-dev-payment](/images/workshop/runbook/img140.jpg)

![AI routes attached to fitness-assistant-dev-ai](/images/workshop/runbook/img234.jpg)

T6 — the production bundle already contains the user-facing messages for throttling and timeouts (HTTP 408/504 "AI took too long", 429 "AI Coach is receiving too many requests", 502/503 "not ready"):

![Bundle check showing the API URL and the 429 handling messages](/images/workshop/runbook/img334.jpg)

#### How to read failures

| Symptom | Layer to inspect |
|---|---|
| CORS error in the browser | API Gateway CORS origin must be exactly the `http://` S3 website URL |
| `{"message":"Not Found"}` | Route missing, or route without an attached integration |
| `{"message":"Internal Server Error"}` / 500 | Lambda CloudWatch log `/aws/lambda/fitness-assistant-dev-<service>` |
| Prisma `P1001` / timeout | Lambda not in the private app subnets, or Aurora SG missing the Lambda SG on 5432 |
| `AccessDeniedException` in the log | The function's role lacks the specific secret / invoke / Bedrock permission |
