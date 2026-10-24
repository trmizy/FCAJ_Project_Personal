---
title: "Troubleshooting"
date: 2026-10-23
weight: 8
chapter: false
pre: " <b> 5.8. </b> "
---

This page lists the real problems met while deploying and operating Gymini on AWS, how each one was found, how it was fixed, and what to check first next time. Every entry was confirmed against logs, API responses or the AWS console, not guessed.

| # | Problem | Layer | Status |
|---|---|---|---|
| 1 | Login blocked by CORS | API Gateway | Fixed |
| 2 | Chat blocked as mixed content | CloudFront, ALB | Fixed |
| 3 | Chat returns 503 after the environment is switched on | ECS, ALB, CloudFront | Fixed, one manual step remains |
| 4 | Lambda times out or returns 500 in a "cold" environment | VPC, Aurora | Fixed by start order |
| 5 | Chat task crashes with `URL must start with postgresql://` | ECS, Secrets Manager | Fixed |
| 6 | Bedrock model quota is 0 on the main account | Bedrock | Fixed with a cross-account role |
| 7 | Bedrock calls still denied (Converse, marketplace model) | IAM | Fixed |
| 8 | Password-reset link never appears | Auth Lambda, SMTP | Worked around, controlled |
| 9 | CI/CD gates failing or refusing to start | GitHub Actions, CloudFormation | Fixed |
| 10 | A stale CloudFormation change set | CloudFormation | Avoided |

### 1. Login blocked by CORS

- **Symptom:** the login page shows a generic error. The browser console reports that `/auth/login` was blocked by CORS policy because no `Access-Control-Allow-Origin` header is present.
- **How it was found:** a direct `curl` to `/auth/login` returned the correct `401` for a wrong password, so the service was healthy. Reading the API's own CORS configuration showed that `AllowOrigins` still listed only the old S3 website URL.
- **Fix:** add the CloudFront URL to `AllowOrigins` with a single additive `update-api --cors-configuration` call, keeping the old origin. Re-test both the preflight and the real `POST`: both now carry `access-control-allow-origin` with the CloudFront domain.
- **Next time:** when the frontend moves to a new domain, update the API's allowed origins in the same change.

### 2. Chat blocked as mixed content

- **Symptom:** the chat panel shows "Network Error".
- **Cause:** the page is served over HTTPS by CloudFront, but the frontend pointed the Socket.IO client straight at the chat load balancer over plain HTTP. Browsers block that combination. The load balancer only has an HTTP listener on port 80; a custom domain and a certificate would be needed to add HTTPS.
- **Fix:** add a CloudFront origin for the load balancer (`http-only` towards the origin) and a behavior `/socket.io/*` with caching disabled and all viewer headers forwarded, then set `chatWsUrl` in `runtime-config.json` to the CloudFront domain. The browser now talks to one HTTPS origin.
- **Verify:** `GET /socket.io/?EIO=4&transport=polling` through CloudFront returns `200` with an Engine.IO handshake (`sid`, `upgrades: ["websocket"]`).

### 3. Chat returns 503 after the environment is switched on

- **Symptom:** CloudFront reaches the load balancer but the answer is `503`.
- **Causes found:** (a) the ECS service had `desiredCount: 0`, so the target group had no healthy target; (b) the load balancer is on demand and gets a **new DNS name** every time it is recreated, so the CloudFront origin and the runtime configuration still pointed at the previous one.
- **Fix:** scale the ECS service to 1, point the CloudFront origin to the current load balancer DNS name, and write the HTTPS chat URL back into `runtime-config.json`. Wait for the distribution to finish deploying, then repeat the Engine.IO check.
- **Next time:** after `dev-start`, check three things in order: ECS running count, CloudFront origin domain, `chatWsUrl`.

### 4. Lambda times out or returns 500 in a "cold" environment

- **Symptom:** a call to a Lambda attached to the VPC hangs for the full 30 seconds, or later returns `500`.
- **Causes found:** the NAT Gateway was switched off, so a function that needs the internet (for example to send e-mail) had no outbound path and timed out. After the NAT was back, a database-backed call returned `500` because the Aurora cluster was still `stopped`.
- **Fix:** bring the layers up in order: network (NAT), then the database, then the schedules. The start script does exactly this and only re-enables the EventBridge schedules after Aurora is `available`.
- **Next time:** a timeout points at the network path; a `500` on a database call points at the database being stopped.

### 5. Chat task crashes with `URL must start with postgresql://`

- **Symptom:** the first Chat task fails at start and Prisma reports the invalid URL.
- **Cause:** in the task definition the two secret entries had value type *Value* with a secret **name**, so the container received the name instead of the connection string.
- **Fix:** register a new task definition revision where the secrets use **ValueFrom** with the full secret ARN plus the JSON key suffix, then update the service with a forced new deployment. Secrets never go into plain environment variables.

### 6. Bedrock model quota is 0 on the main account

- **Symptom:** every on-demand model call fails with a quota error.
- **How it was confirmed:** Service Quotas showed the account-level on-demand quota for the chosen models as `0` and not adjustable.
- **Fix:** keep the AI service on Bedrock but call it through a second AWS account that has real quota. A role in that account trusts only the AI Lambda execution roles and requires an `ExternalId`; the AI service assumes it with STS for each call. No static keys are stored anywhere.
- **Result:** logs show successful `llm_call` entries with `provider: bedrock`.

### 7. Bedrock calls still denied after the role existed

- **Symptom:** `AccessDeniedException` in the AI Lambda logs.
- **Causes found:** (a) `bedrock:InvokeModel` does not cover the Converse API, which needs its own action on the same resources; (b) a marketplace model such as the Cohere embedding model needs the calling principal to have `aws-marketplace:ViewSubscriptions` and `aws-marketplace:Subscribe`.
- **Fix:** add `bedrock:Converse` next to `InvokeModel` on the inference profile and its destination model, and add the marketplace actions as a separate small policy. Each change was checked with `iam:SimulatePrincipalPolicy` and then with a real call.

### 8. Password-reset link never appears

- **Symptom:** the reset request returns the generic message and no link, and there is no real mailbox for the seeded admin address.
- **Cause:** in non-production mode the service returns a development reset link only when e-mail is **not configured**. The deployed Lambda has all four SMTP settings, so it really sends and reports success even for an address that does not exist.
- **Controlled workaround:** for a few minutes, switch `NODE_ENV` to development and blank only `SMTP_HOST` on the auth Lambda, request the reset, complete it by invoking the Lambda directly, then restore the original environment from a saved copy and read it back (`NODE_ENV=production`, `SMTP_HOST` restored, all variables present).
- **Next time:** the real fix is a reachable reset flow for real users (see problem 9).

### 9. CI/CD gates failing or refusing to start

| Symptom | Cause | Fix |
|---|---|---|
| A new workflow was rejected: `'name' is already defined` | A duplicated `name:` line after combining a header and a body | Remove the duplicate line, diff against the original |
| A manual workflow does not appear in the list | `workflow_dispatch` only works for workflows on the **default branch** (`master`) | Copy the two manual workflows to `master` byte for byte |
| The apply job failed on an `AccessDenied` for `cloudformation:GetTemplate` | The apply role could not read the change set's template | Add that one action, scoped to the single stack, and verify with a policy simulation |
| The post-apply check failed on every correct apply | It treated the 10 known source-only routes as a failure | Add an opt-in `-AllowKnownSourceOnly` switch, used only by that step; mismatched routes still fail |
| A pull request showed 104 commits and 1,215 files | The branch was cut from a local tip with many unpushed commits | Cut a new branch from the real remote tip and cherry-pick the single commit |

### 10. A stale CloudFormation change set

- **Symptom:** an old change set with no changes looked safe to apply.
- **Cause:** it carried the load balancer DNS name from the day it was created, and that load balancer no longer existed. The digest check only proves the **template** is unchanged, not that baked-in parameter values are still current.
- **Fix:** do not apply it. Create a fresh plan, which has the current parameter value, and apply that one.
