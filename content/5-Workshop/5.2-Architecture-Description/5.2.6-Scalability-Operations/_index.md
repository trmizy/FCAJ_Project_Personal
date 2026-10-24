---
title: "5.2.6 Scalability and Operations"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.2.6. </b> "
---

### How each component scales

| Component | Scaling model | Notes |
|---|---|---|
| Service Lambdas (HTTP and jobs) | Per invocation, automatic, scale to zero | 1024 MB each; cold starts on idle functions are the trade-off, not yet measured. No reserved concurrency, so one hot route cannot starve the others by configuration. |
| AI Worker | One Lambda per SQS message (batch size 1) | Throughput grows with queue depth; failed messages go to the DLQ after 2 receives. |
| Chat Service (ECS Fargate) | Fixed at 1 task (0.5 vCPU / 1 GB) | Deliberate: Socket.IO session state is in memory, so a second task would split sessions until a shared adapter (e.g. Redis) exists. No service auto scaling yet. |
| Aurora PostgreSQL Serverless v2 | Capacity in ACUs between a floor and a ceiling | Floor kept at 0.5 ACU during deployment so auto-pause/resume does not disturb smoke tests; can go to 0 when idle. |
| OpenSearch Serverless (NextGen) | 0–2 OCU for indexing and for search | Scales to zero after ~10 idle minutes; the first request afterwards can take 10–30 s. |
| API Gateway, SQS, EventBridge, S3 | Fully managed | No capacity planning needed at DEV traffic. AI routes are intentionally throttled. |

### Keeping slow work out of the request path

Scheduled work runs from EventBridge Scheduler into dedicated jobs functions, so no user request ever triggers a settlement or reconciliation run. Long AI work goes through SQS to the AI Worker (300 s timeout) and knowledge ingestion runs in the AI Jobs function (600 s timeout), while the HTTP function stays under API Gateway's ~30 s integration limit. That is why the AI Service has three functions instead of one.

### Operating the system today

- **Deployments** are manual and documented step by step in [5.4](../../5.4-Deployment-Guide/): ZIPs uploaded from the deployments bucket, task definition revisions rolled out with *Force new deployment*, and schema changes applied with each service's migration function.
- **Logs** for every function and task are in CloudWatch Logs (`/aws/lambda/…`, `/ecs/…`); [5.5.4](../../5.5-Test-Validation/5.5.4-Background-Jobs-Logs/) lists what to look for.
- **Changing a secret** (for example a rotated Aurora password) requires recycling the Lambda execution environments, because functions cache the secret while warm — the Auth deployment did this by editing a harmless `DEPLOY_REVISION` variable.

### CI/CD and monitoring

- **CI/CD is in place** — GitHub Actions validates every PR and deploys Lambda code, the Chat image and the API Gateway stack through reviewer-gated workflows.
- **Monitoring is in place** — 12 CloudWatch alarms (Lambda errors for the six API services, API Gateway 5xx, Aurora CPU and capacity, NAT Gateway health) notify an SNS topic with a confirmed e-mail subscription; a monthly AWS Budget alerts on cost; active X-Ray tracing is on the six API Lambdas.
