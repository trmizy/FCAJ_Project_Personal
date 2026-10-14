---
title: "5.2.6 Scalability and Operations"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.2.6. </b> "
---

### How Each Component Scales

| Component | Scaling Model | Notes |
|---|---|---|
| Auth / User / Fitness / Gym / Payment / AI Lambdas | Per-invocation, automatic, scales to zero when idle | No capacity planning needed for the current DEV traffic level; the trade-off is cold starts on an idle function, not yet measured/tuned. |
| Chat Service (ECS Fargate) | Manual task count today (dev sizing: 0.5 vCPU / 1 GB, effectively fixed at 1 task) | No Auto Scaling policy attached yet — a deliberate DEV-stage simplification, not an oversight; tracked as a gap, not a finished design. |
| Aurora PostgreSQL Serverless v2 | Auto-scales capacity (ACU) between a configured floor and ceiling | Currently held at a 0.5 ACU floor rather than letting it scale to 0, specifically to avoid auto-pause/resume latency interfering with ongoing smoke tests during active development (see [5.2.7](../5.2.7-Cost-Optimization-Cleanup/)). |
| API Gateway, S3, EventBridge, SQS | Fully managed, scales automatically with no configuration from this project | No capacity ceiling has been hit or is expected to be hit at DEV traffic levels. |

### Decoupling Background Work From the Request Path

Scheduled work (Payment reconciliation, Gym/Fitness reminders) runs on Amazon EventBridge Scheduler rules, one per service, rather than inside a request handler — so a user's HTTP request is never the thing that triggers a reconciliation run. Asynchronous AI work goes through Amazon SQS to a dedicated AI Worker Lambda, so a slow model completion cannot hold open — or time out — a synchronous API Gateway request. This separation is why the AI feature has three Lambdas (HTTP, Worker, Jobs) instead of one: each handles a different timing requirement rather than one function trying to do all three.

### Operational Gaps, Tracked Honestly

This system is deployed and partially verified, not yet "finished and hardened." The gaps below are the ones explicitly carried in the internal deployment runbook's own status tracking, not discovered after the fact:

- **CI/CD does not exist yet.** Every deployment so far — a new Lambda version, a Fargate task definition revision, a database migration — has been a manual console or CLI step. This is the single largest remaining piece of operational work (see [5.1 Overview](../../5.1-Overview/)).
- **No CloudWatch Alarms configured yet.** Logs exist for every Lambda and the Fargate task, but nothing currently pages or emails on an error spike, a Lambda throttle, or an Aurora capacity ceiling being hit. Monitoring today is "go read the logs," not "get alerted."
- **End-to-end validation is incomplete.** Per the status table in [5.2.1](../5.2.1-Architecture-Overview/), only Auth and User have a full passing E2E pass recorded; Fitness, Gym, Payment, AI/Worker/Jobs, Chat, and the frontend integration are deployed but still need one.
- **No Auto Scaling configured for the Chat Fargate service.** A single fixed task is enough for DEV-level concurrent chat sessions today; this would need revisiting before any real multi-user load.

### Why These Gaps Are Listed Here Instead of Omitted

This report's [Definition of Done](../../5.1-Overview/) commits to not claiming a step succeeded without evidence. The same principle applies to operational maturity: a serverless architecture that auto-scales its compute is not automatically "production-ready" just because Lambda and Fargate handle the scaling mechanics — the missing CI/CD, alarms, and E2E coverage above are exactly the kind of gap that a purely architectural description could paper over, so they are named here instead.
