---
title: "5.5.6 Monitoring and alerting with Amazon CloudWatch"
date: 2026-10-23
weight: 6
chapter: false
pre: " <b> 5.5.6. </b> "
---

This page shows how the DEV environment is observed through **logs, metrics and alarms**, how an alert reaches a person, and how to test each layer. All values below were read from the live account.

#### 1. Monitoring layers

| Layer | AWS service | What it covers |
|---|---|---|
| Logs | Amazon CloudWatch Logs | One log group per Lambda, plus the Chat task and the database migrator |
| Metrics | Amazon CloudWatch Metrics | Lambda, API Gateway, Aurora, SQS, NAT Gateway and ECS built-in metrics |
| Alarms | Amazon CloudWatch Alarms | 12 alarms on errors, 5xx responses, database load and NAT health |
| Notification | Amazon SNS | Topic `fitness-assistant-dev-app-alerts` with a confirmed e-mail subscription |
| Tracing | AWS X-Ray | Active tracing on the six API Lambdas (auth, user, fitness, gym, payment, AI) |
| Cost | AWS Budgets | Monthly budget with three notifications |

The alarms and the topic are created by the CloudFormation stack `fitness-assistant-dev-app-monitoring`, so they are reproducible and not clicked together by hand.

#### 2. Logs

| Log group | Retention | Note |
|---|---|---|
| `/aws/lambda/fitness-assistant-dev-<service>` and `-jobs`, `-worker`, `-migrate` | Never expire (default) | Structured JSON written by `pino`: level 30 is info, 40 warning, 50 error |
| `/ecs/fitness-assistant-dev-chat` | 30 days | Chat service |
| `/ecs/fitness-assistant-dev-db-migrator` | 14 days | One-off database migrator |

Two CloudWatch Logs Insights queries cover most of the troubleshooting:

```
fields @timestamp, @message
| filter @message like /"level":50/
| sort @timestamp desc
| limit 20
```

```
fields @timestamp, @message
| filter @message like /Task timed out|AccessDenied|ECONNREFUSED|P1001/
| sort @timestamp desc
| limit 20
```

The first lists the latest errors of a function; the second finds the four most common infrastructure failures (timeout, missing permission, refused connection, database unreachable). The meaning of each message is listed in [5.5.4](../5.5.4-Background-Jobs-Logs/).

#### 3. Metrics worth watching

| Namespace | Metric | Why |
|---|---|---|
| `AWS/Lambda` | `Errors`, `Throttles`, `Duration`, `ConcurrentExecutions` | Function health and the 30-second timeout |
| `AWS/ApiGateway` | `Count`, `4xx`, `5xx`, `Latency` | Client mistakes versus server failures at the entry point |
| `AWS/RDS` | `ServerlessDatabaseCapacity`, `CPUUtilization` | Aurora Serverless v2 scaling and load |
| `AWS/SQS` | `ApproximateNumberOfMessagesVisible` on the queue and its dead-letter queue | Backlog of AI jobs, failed jobs |
| `AWS/NATGateway` | `ActiveConnectionCount`, `PacketsDropCount`, `ErrorPortAllocation` | Outbound path used by Bedrock and e-mail |

#### 4. Alarms

All 12 alarms use `TreatMissingData: notBreaching`, so a stopped environment does not raise false alerts. Each alarm sends both its **ALARM** and its **OK** transition to the SNS topic.

| Alarm | Metric | Condition |
|---|---|---|
| `fitness-assistant-dev-auth-lambda-errors` | `AWS/Lambda` `Errors`, Sum | ≥ 5 in 5 minutes |
| `fitness-assistant-dev-user-lambda-errors` | same | ≥ 5 in 5 minutes |
| `fitness-assistant-dev-fitness-lambda-errors` | same | ≥ 5 in 5 minutes |
| `fitness-assistant-dev-gym-lambda-errors` | same | ≥ 5 in 5 minutes |
| `fitness-assistant-dev-payment-lambda-errors` | same | ≥ 5 in 5 minutes |
| `fitness-assistant-dev-ai-lambda-errors` | same | ≥ 5 in 5 minutes |
| `fitness-assistant-dev-apigw-5xx-high` | `AWS/ApiGateway` `5xx`, Sum | ≥ 10 in 5 minutes |
| `fitness-assistant-dev-aurora-cpu-high` | `AWS/RDS` `CPUUtilization`, Average | > 80 for 2 periods of 5 minutes |
| `fitness-assistant-dev-aurora-capacity-pinned` | `AWS/RDS` `ServerlessDatabaseCapacity`, Average | ≥ 1.8 ACU for 3 periods of 5 minutes (the cluster scales between 0.5 and 2.0 ACU, so this means it is pinned near the maximum) |
| `NAT-Gateway-High-Active-Connections` | `ActiveConnectionCount`, Average | > 1000 |
| `NAT-Gateway-Packet-Drops` | `PacketsDropCount`, Sum | > 100 |
| `NAT-Gateway-Port-Allocation-Errors` | `ErrorPortAllocation`, Sum | > 0 |

**Notification path:** alarm → SNS topic `fitness-assistant-dev-app-alerts` → e-mail (1 confirmed subscription, 0 pending). Alarms change state on their own: for example, the API 5xx alarm history shows `OK → ALARM` and `ALARM → OK` transitions on 23 October 2026, and the alarm returned to OK by itself each time.

![CloudWatch alarm list with 12 alarms](/images/workshop/console/cw-alarms-list.jpg)
*The 12 alarms in CloudWatch → Alarms.*

![SNS topic with one confirmed e-mail subscription](/images/workshop/console/sns-subscriptions.jpg)
*The SNS topic with one confirmed e-mail subscription.*

![Lambda configuration page showing Lambda service traces enabled](/images/workshop/console/lambda-tracing.jpg)
*Lambda → Configuration → Monitoring and operations tools: logs and metrics enabled, Lambda service traces (X-Ray) enabled.*

The step-by-step creation of an alarm, with its form, is in [5.4.14](../../5.4-Deployment-Guide/5.4.14-Edge-Database-Monitoring/).

#### 5. Cost monitoring

The budget `fitness-assistant-monthly` has a limit of **15 USD per month** with three notifications: actual spend above 50 percent and above 100 percent of the limit, and forecasted spend above 100 percent. This matters because several resources bill by the hour (NAT Gateway, load balancer, Aurora, endpoints), which is why the environment has an on-demand start and stop procedure ([5.7](../../5.7-Cleanup/)).

#### 6. Tests and validation

**6.1 Sample requests.** These were run against the deployed API and CloudFront; the actual results are listed.

| # | Request | Expected | Result |
|---|---|---|---|
| 1 | `GET /health` | `200` and the service name | `200` `{"status":"ok","service":"auth-service"}` |
| 2 | `POST /auth/login` with a wrong password | `401`, no detail about which field is wrong | `401` `{"error":"Invalid credentials"}` |
| 3 | `POST /auth/login` with malformed JSON (`{"email":`) | `400` and no stack trace | `400` `Bad Request` |
| 4 | `POST /auth/login` with an empty body `{}` | `400` with the missing fields | `400` `Validation failed`, listing `email` and `password` as required |
| 5 | `GET /plans/workout` without a token | `401` | `401` `UNAUTHORIZED` ("Request must carry a valid Bearer token…") |
| 6 | `GET /plans/workout` with a fake token | `401` | `401` `UNAUTHORIZED` ("Invalid or expired token") |
| 7 | `GET /me/gym-memberships` without a token | `401` | `401` `UNAUTHORIZED` ("Authentication required") |
| 8 | `GET /does-not-exist` | `404` from the API Gateway | `404` `{"message":"Not Found"}` |
| 9 | `GET /` on the CloudFront domain | `200`, served from S3 | `200`, `Server: AmazonS3`, response header shows CloudFront |

Example for test 2:

```
curl -s -X POST https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/auth/login \
  -H "content-type: application/json" \
  -d '{"email":"nobody@example.com","password":"wrong"}'
```

**6.2 Log verification.** After tests 2 to 4, the `/aws/lambda/fitness-assistant-dev-auth` log group contains one structured entry per request with the method `POST` and the URL `/auth/login`, and the Lambda `Errors` metric stays at 0: a rejected login is a handled `4xx`, not a function failure.

**6.3 Metric verification.** A few minutes later, `AWS/ApiGateway` `Count` and `4xx` increase by the number of requests sent, while `5xx` stays at 0. Metrics are delayed by one to a few minutes.

**6.4 Alarm test.** To prove the whole alert path without breaking anything, force one alarm into the ALARM state and check that an e-mail arrives, then let it return to OK:

```
aws cloudwatch set-alarm-state \
  --alarm-name fitness-assistant-dev-apigw-5xx-high \
  --state-value ALARM --state-reason "Alert path test"
```

The alarm evaluates its real metric again at the next period and goes back to OK by itself.

**6.5 Error-case checks.** The negative tests above (wrong password, malformed body, missing token, fake token, unknown route) confirm that failures are rejected at the right layer with the right status code, and that none of them raises the function-error alarms.

#### 7. Coverage and gaps

| Covered | Not covered yet |
|---|---|
| Errors on the six API Lambdas | Errors on the worker and the scheduled jobs Lambdas |
| API Gateway 5xx, Aurora CPU and capacity, NAT health | Lambda throttles and duration |
| E-mail notification for ALARM and OK | Dead-letter queue depth, and the Chat target health |
| X-Ray tracing on the API Lambdas | An application dashboard (only a VPC dashboard exists) |
| Monthly cost budget | Retention for the Lambda log groups (they never expire) |

Next steps: add alarms for the worker, the jobs, throttles and the dead-letter queue, set a retention period on the Lambda log groups to limit storage cost, and build one dashboard that puts API latency, errors, queue depth and Aurora capacity on a single screen.
