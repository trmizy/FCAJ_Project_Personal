---
title: "5.5.4 Background jobs, queues and logs"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.5.4. </b> "
---

#### Schedules

Thirteen EventBridge Scheduler schedules invoke the jobs Lambdas. Each must be **Enabled** and must use its service's own scheduler role.

| Service | Schedule | Cadence | Target | Payload |
|---|---|---|---|---|
| User | `fitness-assistant-dev-user-session-settlement` | 5 min | `user-jobs` | `{"job":"session-settlement"}` |
| User | `fitness-assistant-dev-user-session-auto-confirm` | 10 min | `user-jobs` | `{"job":"session-auto-confirm"}` |
| User | `fitness-assistant-dev-user-reschedule-expiry` | 10 min | `user-jobs` | `{"job":"reschedule-expiry"}` |
| Fitness | `fitness-assistant-dev-workout-upcoming-reminder` | 30 min | `fitness-jobs` | `{"job":"workout-upcoming-reminder"}` |
| Fitness | `fitness-assistant-dev-workout-unfinished-reminder` | 30 min | `fitness-jobs` | `{"job":"workout-unfinished-reminder"}` |
| Gym | `fitness-assistant-dev-gym-membership-payout` | 10 min | `gym-jobs` | `{"job":"membership-payout-sweep"}` |
| Gym | `fitness-assistant-dev-gym-referral-settlement` | 10 min | `gym-jobs` | `{"job":"referral-settlement-sweep"}` |
| Payment | `fitness-assistant-dev-payment-reconciliation` | 5 min | `payment-jobs` | `{"job":"reconciliation"}` |
| AI | `fitness-assistant-dev-ai-autoaccept` | 15 min | `ai-jobs` | `{"job":"personalized-service-autoaccept-sweep"}` |
| AI | `fitness-assistant-dev-ai-local-evidence` | daily 02:00 | `ai-jobs` | `{"job":"local-evidence-refresh"}` |
| AI | `fitness-assistant-dev-ai-pubmed` | daily 02:30 | `ai-jobs` | `{"job":"pubmed-refresh"}` |
| AI | `fitness-assistant-dev-ai-rss` | daily 03:00 | `ai-jobs` | `{"job":"rss-refresh"}` |
| AI | `fitness-assistant-dev-ai-web` | daily 03:30 | `ai-jobs` | `{"job":"web-refresh"}` |

**How to verify a schedule really runs:** open `/aws/lambda/fitness-assistant-dev-<service>-jobs` in CloudWatch Logs — a new invocation must appear at the schedule's cadence, ending without `Task timed out` or an unhandled error. A schedule that never invokes usually means its role lacks `lambda:InvokeFunction` on that exact function ARN.

#### SQS worker

| Check | Expected |
|---|---|
| Queue `fitness-assistant-dev-ai-tasks` | Visibility timeout 600 s (longer than the Worker's 300 s timeout), DLQ `fitness-assistant-dev-ai-tasks-dlq`, maximum receives 2 |
| Trigger on `fitness-assistant-dev-ai-worker` | SQS trigger **Enabled**, batch size 1, *Report batch item failures* on |
| After a plan generation (`POST /plans/workout/generate` then `GET /plans/job/{id}`) | The job finishes, the queue drains, the DLQ stays at 0 messages |

![Queue details: dead-letter queue enabled](/images/workshop/runbook/img191.jpg)

![SQS trigger attached to the AI Worker](/images/workshop/runbook/img194.jpg)

A message in the DLQ means a job failed twice: read the Worker log for that message before re-driving it.

#### CloudWatch Logs

Every Lambda writes to `/aws/lambda/<function-name>` and the Chat task to `/ecs/fitness-assistant-dev-chat`; the migrator writes to `/ecs/fitness-assistant-dev-db-migrator`.

![CloudWatch log groups for the functions](/images/workshop/runbook/img271.jpg)

| Log message | Meaning |
|---|---|
| `PrismaClientInitializationError`, `P1001`, `Can't reach database` | Network path to Aurora (subnets, security groups) or a stale credential |
| `AccessDeniedException` | The role is missing a specific permission (secret, invoke, Bedrock, `aoss:APIAccessAll`, SQS) |
| `403` from OpenSearch | IAM permission or data access policy missing — both layers are required |
| `Task timed out after …` | Work that should be queued (AI) or a function timeout set too low |

{{% notice note %}}
CloudWatch alarms already watch the API Lambdas, API Gateway 5xx, Aurora and the NAT Gateway (see [5.5.6](../5.5.6-Monitoring-Alerting/)). Alarms for the worker, the jobs, throttles and the DLQ depth are still open, so those checks remain manual.
{{% /notice %}}
