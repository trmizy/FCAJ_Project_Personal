---
title: "5.7 Clean-up"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.7. </b> "
---

{{% notice warning %}}
The DEV environment is still in use for end-to-end testing, so this teardown has **not** been run yet. It lists every resource created in [5.4](../5.4-Deployment-Guide/) in the order that avoids dependency errors. Deleting Aurora, the S3 buckets and the secrets is irreversible — export anything you want to keep first.
{{% /notice %}}

Every resource name starts with `fitness-assistant-dev-` (or `fitness-assistant/dev/` for secrets), and everything lives in `ap-southeast-1`. Use **Resource Groups & Tag Editor** with that prefix to double-check nothing is left.

#### Pausing instead of deleting {#pause}

If the environment is only idle for a while, these steps remove most of the cost without losing anything:

| Resource | Pause action | Effect |
|---|---|---|
| Aurora Serverless v2 | Set minimum capacity to **0 ACU** (auto-pause) | Compute cost stops while idle; storage is kept |
| Chat ECS service | Update service → desired tasks **0** | No Fargate charge |
| NAT Gateway | Delete it and release its Elastic IP; recreate before the next test session | Removes the largest fixed hourly cost; Lambdas lose outbound internet meanwhile |
| OpenSearch Serverless | Already scales to 0 OCU when idle (0–2 OCU group) | No action needed |

#### Full teardown order

1. **EventBridge Scheduler** — delete the 13 schedules (`fitness-assistant-dev-user-*`, `-workout-*`, `-gym-*`, `-payment-reconciliation`, `-ai-*`), then the 5 scheduler roles.
2. **API Gateway** — delete the HTTP API `fitness-assistant-dev-api` (all routes, integrations, CORS and throttling settings go with it).
3. **Chat on ECS**
   1. Update `fitness-assistant-dev-chat-service` to 0 tasks, then delete the service.
   2. Delete the ALB `fitness-assistant-dev-chat-alb`, then the target group `fitness-assistant-dev-chat-tg`.
   3. Deregister and delete the task definitions `fitness-assistant-dev-chat` and `fitness-assistant-dev-db-migrator` (all revisions).
   4. Delete the cluster `fitness-assistant-dev-cluster`.
4. **Lambda**
   1. Remove the SQS trigger (event source mapping) from `fitness-assistant-dev-ai-worker` — deleting a function does not delete its event source mappings.
   2. Delete all functions: `auth`, `user`, `user-jobs`, `fitness`, `fitness-jobs`, `gym`, `gym-jobs`, `payment`, `payment-jobs`, `ai`, `ai-worker`, `ai-jobs`, and the remaining `*-migrate` functions.
5. **SQS** — delete `fitness-assistant-dev-ai-tasks` and `fitness-assistant-dev-ai-tasks-dlq`.
6. **OpenSearch Serverless** — delete the collection `fitness-assistant-dev-ai-vectors`, its data access / network / encryption policies, the OpenSearch application and workspace, the OpenSearch VPC endpoint and the collection group `fitness-assistant-dev-ai`.
7. **Aurora** — optionally take a final snapshot, disable deletion protection if it is on, delete the instance, then the cluster `fitness-assistant-dev-aurora`.
8. **Secrets Manager** — delete every `fitness-assistant/dev/*` secret (database secrets, `chat-database-url`, `internal-service-secret`). Deletion is scheduled with a 7–30 day recovery window unless forced.
9. **ECR** — delete `fitness-assistant-dev-chat`, `fitness-assistant-dev-db-migrator` and the earlier `fitness-assistant/*` repositories from the container phase.
10. **S3** — empty, then delete: the frontend bucket, the uploads bucket, the deployments bucket and the data-migration bucket (versioned: delete all object versions too).
11. **CloudWatch Logs** — delete `/aws/lambda/fitness-assistant-dev-*`, `/ecs/fitness-assistant-dev-chat` and `/ecs/fitness-assistant-dev-db-migrator`.
12. **Network**
    1. Delete the NAT Gateway `fitness-assistant-dev-nat-a`, wait until *Deleted*, then release its Elastic IP.
    2. Delete the interface VPC endpoints (Secrets Manager, OpenSearch).
    3. Delete the security groups: `chat-alb-sg`, `chat-sg`, `vpce-sg`, `lambda-sg`, `aurora-sg` (remove cross-references first).
    4. Delete the subnets, the route tables (`public-rt`, `private-app-rt`, `private-db-rt`), detach and delete the Internet Gateway, then delete `fitness-assistant-dev-vpc`.
13. **IAM** — delete the `fitness-assistant-dev-*` roles (Lambda, ECS task/execution, migrator, scheduler) and their inline policies.
14. **Bedrock** — nothing to delete (no provisioned resources); optionally cancel the Cohere Marketplace subscription.

#### Verify

- **Billing → Bills** and **Cost Explorer** (filter by service, region `ap-southeast-1`) show no new charges for NAT Gateway, Aurora, Fargate, ALB, OpenSearch or public IPv4 addresses after the next day.
- **Resource Groups & Tag Editor** with the `fitness-assistant-dev` prefix returns nothing.
