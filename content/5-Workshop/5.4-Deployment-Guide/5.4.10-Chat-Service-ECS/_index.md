---
title: "5.4.10 Chat Service on ECS Fargate"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 5.4.10. </b> "
---

Chat is the only service that does not run on Lambda: Socket.IO keeps a connection open for the whole chat session, which does not fit Lambda's per-invocation model. It runs as one container on ECS Fargate, behind its own Application Load Balancer.

| Item | Value |
|---|---|
| Logical database | `fitness_assistant_chat` (3 Prisma migrations) |
| Secrets | `fitness-assistant/dev/chat-database` (migration), `fitness-assistant/dev/chat-database-url` (runtime), `fitness-assistant/dev/internal-service-secret` |
| Image | ECR `fitness-assistant-dev-chat:dev-20260922-1` |
| Runtime | Cluster `fitness-assistant-dev-cluster`, service `fitness-assistant-dev-chat-service`, task definition `fitness-assistant-dev-chat` — 0.5 vCPU / 1 GB, container port 3005 |
| Entry points | Socket.IO → ALB `fitness-assistant-dev-chat-alb` (HTTP 80); REST → API Gateway `ANY /chat/{proxy+}` → ALB |

```
Internet ─:80─► chat-alb-sg ─:3005─► chat-sg (Fargate task, private subnets) ─:5432─► aurora-sg
```

#### Part A — Database

**Step 1 — Database secret.** Secrets Manager → *Other type of secret* → **Plaintext**, reusing the username/password/host/port of a working database secret and changing only the database name:

```json
{
  "username": "<Aurora username>",
  "password": "<Aurora password>",
  "host": "fitness-assistant-dev-aurora.cluster-<id>.ap-southeast-1.rds.amazonaws.com",
  "port": 5432,
  "database": "fitness_assistant_chat"
}
```

Name `fitness-assistant/dev/chat-database`, description "Chat Service Aurora PostgreSQL database – dev", default `aws/secretsmanager` key, rotation off. The secret only stores connection details — the database itself is created by the migration Lambda.

![Secrets list before adding the Chat secret](/images/workshop/runbook/img236.jpg)

![Plaintext JSON with placeholder credentials](/images/workshop/runbook/img237.jpg)

![Secret name fitness-assistant/dev/chat-database](/images/workshop/runbook/img238.jpg)

![Rotation left off](/images/workshop/runbook/img239.jpg)

![Review and store](/images/workshop/runbook/img240.jpg)

**Step 2 — Migration role.** `fitness-assistant-dev-chat-migrate-role` ("Execution role for Chat Service database migration Lambda") with `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole` and the inline policy `fitness-assistant-dev-chat-migrate-secret` (`secretsmanager:GetSecretValue` on `fitness-assistant/dev/chat-database*` only). No Bedrock, SQS, OpenSearch or invoke permissions — the migration needs only logs, VPC access and its secret.

![IAM → Roles → Create role](/images/workshop/runbook/img241.jpg)

![Trusted entity: AWS service → Lambda](/images/workshop/runbook/img242.jpg)

![Selecting AWSLambdaVPCAccessExecutionRole](/images/workshop/runbook/img243.jpg)

![Role name fitness-assistant-dev-chat-migrate-role](/images/workshop/runbook/img244.jpg)

![The two managed policies](/images/workshop/runbook/img245.jpg)

![Role created](/images/workshop/runbook/img246.jpg)

![Inline policy for the Chat database secret](/images/workshop/runbook/img248.jpg)

![Policy name fitness-assistant-dev-chat-migrate-secret](/images/workshop/runbook/img250.jpg)

![Role with three permission entries](/images/workshop/runbook/img251.jpg)

**Step 3 — Migration Lambda.** At this point the account already ran 15 functions:

![Lambda functions list (15 functions) before the Chat migration Lambda](/images/workshop/runbook/img252.jpg)

Create `fitness-assistant-dev-chat-migrate` (Node.js 22.x, x86_64, role above), upload `backend/services/chat-service/artifacts/chat-migrate-lambda.zip`, handler `dist/migrate-lambda.handler`, 1024 MB, 1 minute, `DATABASE_SECRET_ID=fitness-assistant/dev/chat-database`, both private app subnets + Lambda SG.

![Create function fitness-assistant-dev-chat-migrate](/images/workshop/runbook/img253.jpg)

![Custom execution role](/images/workshop/runbook/img254.jpg)

![Handler dist/migrate-lambda.handler](/images/workshop/runbook/img255.jpg)

![Memory 1024 MB, timeout 1 minute](/images/workshop/runbook/img256.jpg)

![No environment variables yet](/images/workshop/runbook/img257.jpg)

![DATABASE_SECRET_ID for the Chat database](/images/workshop/runbook/img258.jpg)

![No VPC configured yet](/images/workshop/runbook/img259.jpg)

![Attach both private app subnets and the Lambda SG](/images/workshop/runbook/img260.jpg)

**Step 4 — Run the migration.** Test event `chat-migrate` with `{}`. Expected: `status: ok`, `database: fitness_assistant_chat`, `databaseCreated: true` (false if it already existed), `migrateExitCode: 0`, 3 migrations applied. If it fails, record the error instead of re-running it repeatedly.

![Test event chat-migrate](/images/workshop/runbook/img261.jpg)

![Result: status ok, database created, 3 migrations applied](/images/workshop/runbook/img262.jpg)

#### Part B — Container image

**Step 5 — ECR repository.** ECR → *Create repository*: private, name `fitness-assistant-dev-chat`, tag mutability **Mutable** (tags are reused during DEV; production should use commit-based tags such as `git-a84f23c`), AES-256 encryption, scan on push if offered.

![Existing private repositories (from the earlier container phase)](/images/workshop/runbook/img263.jpg)

![Create repository fitness-assistant-dev-chat](/images/workshop/runbook/img264.jpg)

**Step 6 — Push the image** from PowerShell on the workstation. Build only if the image is missing:

```powershell
docker images gymini-chat-service
# only if missing:
docker build --platform linux/amd64 -t gymini-chat-service:aws-local -f backend/services/chat-service/Dockerfile .

aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag gymini-chat-service:aws-local <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
```

`Login Succeeded` must appear before tagging; `'aws' is not recognized`, `Unable to locate credentials` or `AccessDeniedException` mean stopping to fix the CLI setup first.

![Local image gymini-chat-service:aws-local (146 MB compressed)](/images/workshop/runbook/img265.jpg)

![docker login to ECR: Login Succeeded](/images/workshop/runbook/img266.jpg)

![Tagging the image with the ECR URI](/images/workshop/runbook/img267.jpg)

![docker push: all layers pushed](/images/workshop/runbook/img268.jpg)

![Image tag dev-20260922-1 in the repository](/images/workshop/runbook/img269.jpg)

#### Part C — Logs and IAM

**Step 7 — Log group.** CloudWatch → *Create log group* `/ecs/fitness-assistant-dev-chat` (ECS convention, not `/aws/lambda/...`), retention 30 days.

![Create log group /ecs/fitness-assistant-dev-chat, 1-month retention](/images/workshop/runbook/img270.jpg)

![Log groups list](/images/workshop/runbook/img271.jpg)

**Step 8 — Task execution role** (used by ECS itself to pull the image, write logs and inject secrets — not by the application). Trusted entity **Elastic Container Service → Elastic Container Service Task**, managed policy `AmazonECSTaskExecutionRolePolicy`, name `fitness-assistant-dev-chat-execution-role`, plus an inline policy `fitness-assistant-dev-chat-execution-secrets` allowing `secretsmanager:GetSecretValue` on the Chat secrets.

![IAM roles list](/images/workshop/runbook/img272.jpg)

![Use case: Elastic Container Service Task](/images/workshop/runbook/img273.jpg)

![AmazonECSTaskExecutionRolePolicy](/images/workshop/runbook/img274.jpg)

![Role name fitness-assistant-dev-chat-execution-role, trusted by ecs-tasks.amazonaws.com](/images/workshop/runbook/img275.jpg)

![Permissions summary](/images/workshop/runbook/img276.jpg)

![Role created — add an inline policy](/images/workshop/runbook/img277.jpg)

![Inline policy for the Chat secrets](/images/workshop/runbook/img278.jpg)

![Execution role with both policies](/images/workshop/runbook/img279.jpg)

**Step 9 — Task role** (what the Chat code uses at runtime). Same trusted entity, no managed policy, name `fitness-assistant-dev-chat-task-role`, inline policy `fitness-assistant-dev-chat-service-invoke` allowing `lambda:InvokeFunction` on `fitness-assistant-dev-auth` and `fitness-assistant-dev-user` only. No Secrets Manager permissions here — secrets are injected by the execution role.

![Task role fitness-assistant-dev-chat-task-role created](/images/workshop/runbook/img280.jpg)

![Inline policy: invoke the Auth and User Lambdas](/images/workshop/runbook/img281.jpg)

![Policy name fitness-assistant-dev-chat-service-invoke](/images/workshop/runbook/img282.jpg)

#### Part D — Network

**Step 10 — Security group for the task.** EC2 → Security Groups → *Create*: `fitness-assistant-dev-chat-sg` ("Security group for Chat Service Fargate tasks"), no inbound rule yet, default outbound (the task calls the Auth/User Lambdas, Aurora and DNS).

![Security groups before the Chat groups](/images/workshop/runbook/img283.jpg)

![Create fitness-assistant-dev-chat-sg with no inbound rules](/images/workshop/runbook/img284.jpg)

**Step 11 — Let the task reach Aurora.** RDS → `fitness-assistant-dev-aurora` → *Connectivity & security* → open the Aurora security group → *Edit inbound rules* → PostgreSQL 5432 from **security group** `fitness-assistant-dev-chat-sg` ("Allow Chat Fargate tasks to Aurora"). Never `0.0.0.0/0` on 5432.

![Aurora connectivity & security](/images/workshop/runbook/img285.jpg)

![Aurora security group inbound rules](/images/workshop/runbook/img286.jpg)

![Adding 5432 from the Chat security group](/images/workshop/runbook/img287.jpg)

**Step 12 — ECS cluster.** ECS → Clusters → *Create cluster*: `fitness-assistant-dev-cluster`, infrastructure **Fargate only**, no EC2 capacity, no Service Connect.

![No clusters yet](/images/workshop/runbook/img288.jpg)

![Create cluster fitness-assistant-dev-cluster, Fargate only](/images/workshop/runbook/img289.jpg)

![Cluster active](/images/workshop/runbook/img290.jpg)

#### Part E — Runtime secrets and task definition

**Step 13 — Runtime secrets.** The Chat code reads `CHAT_DATABASE_URL`, not `DATABASE_URL`. Create `fitness-assistant/dev/chat-database-url` holding `postgresql://USERNAME:PASSWORD@<aurora-endpoint>:5432/fitness_assistant_chat?schema=public` (URL-encode special characters in the password, e.g. `@` → `%40`), stored under the JSON key `CHAT_DATABASE_URL`. Reuse the shared internal secret as `fitness-assistant/dev/internal-service-secret` (same value the Lambdas use, never a new one). Extend the execution role policy to both secrets.

![Secrets list](/images/workshop/runbook/img291.jpg)

![Secret name fitness-assistant/dev/chat-database-url](/images/workshop/runbook/img292.jpg)

![Execution role policy extended to the new secret](/images/workshop/runbook/img293.jpg)

**Step 14 — Task definition.** ECS → Task definitions → *Create new task definition*:

| Setting | Value |
|---|---|
| Family | `fitness-assistant-dev-chat` |
| Launch type / OS | AWS Fargate, Linux/X86_64, network mode `awsvpc` |
| Task size | 0.5 vCPU, 1 GB |
| Task role / execution role | `fitness-assistant-dev-chat-task-role` / `fitness-assistant-dev-chat-execution-role` |
| Container | `chat-service`, essential, image `…/fitness-assistant-dev-chat:dev-20260922-1` |
| Port mapping | 3005/TCP, app protocol HTTP, name `chat-http` |
| Environment | `NODE_ENV=production`, `CHAT_SERVICE_PORT=3005`, `CORS_ORIGIN=<S3 website URL>`, `ENABLE_REST_CORS=true`, `AUTH_LAMBDA_NAME`, `USER_LAMBDA_NAME` |
| Secrets (**ValueFrom**) | `CHAT_DATABASE_URL` ← `<chat-database-url secret ARN>:CHAT_DATABASE_URL::`; `INTERNAL_API_SECRET` (alias `INTERNAL_SERVICE_SECRET`) ← internal-service-secret |
| Logging | `awslogs`, group `/ecs/fitness-assistant-dev-chat`, region `ap-southeast-1`, stream prefix `chat` |
| Health check | none in the task; the ALB checks `/health` (the image may not contain curl/wget) |

![No task definitions yet](/images/workshop/runbook/img294.jpg)

![Family, Fargate, 0.5 vCPU / 1 GB, task and execution roles](/images/workshop/runbook/img295.jpg)

![Container chat-service, image dev-20260922-1, port 3005](/images/workshop/runbook/img296.jpg)

![Revision 1 environment — the two secrets were entered as plain "Value" (the mistake fixed in revision 3)](/images/workshop/runbook/img297.jpg)

![Log collection to /ecs/fitness-assistant-dev-chat](/images/workshop/runbook/img298.jpg)

![Ephemeral storage and tags (Project, Environment, Service)](/images/workshop/runbook/img299.jpg)

{{% notice warning %}}
**Lesson learned.** In revision 1 the secret entries were typed with value type *Value*, so the container received the secret **name** instead of the connection string and Prisma failed with `URL must start with postgresql://`. The fix was a new revision whose secrets use **ValueFrom** with the full secret ARN plus the JSON key suffix (`…:CHAT_DATABASE_URL::`), then **Update service → revision 3 → Force new deployment**. Never paste the real values into plain environment variables.
{{% /notice %}}

#### Part F — Load balancer

**Step 15 — ALB security group.** `fitness-assistant-dev-chat-alb-sg` ("ALB security group for Fitness Assistant Chat dev"): inbound HTTP 80 from `0.0.0.0/0` (the frontend itself is still HTTP; HTTPS 443 comes with a domain and ACM certificate).

![Security groups after creating chat-sg](/images/workshop/runbook/img300.jpg)

![Create fitness-assistant-dev-chat-alb-sg: HTTP 80 from anywhere](/images/workshop/runbook/img301.jpg)

![ALB security group created](/images/workshop/runbook/img302.jpg)

**Step 16 — Only the ALB may reach the task.** In `fitness-assistant-dev-chat-sg` add Custom TCP **3005** with source = security group `fitness-assistant-dev-chat-alb-sg` ("Allow Chat ALB to reach ECS task"). Port 3005 is never opened to `0.0.0.0/0`.

![Inbound rule 3005 from the ALB security group](/images/workshop/runbook/img303.jpg)

![chat-sg now has one inbound rule](/images/workshop/runbook/img304.jpg)

**Step 17 — Second public subnet.** An internet-facing ALB needs two Availability Zones, so `fitness-assistant-dev-public-b` (10.0.2.0/24, `ap-southeast-1b`) was added — see [5.4.1, step 6](../5.4.1-Shared-Network/#second-public-subnet).

**Step 18 — Target group.** EC2 → Target groups → *Create*: target type **IP addresses** (Fargate uses `awsvpc`, so not *Instances*), name `fitness-assistant-dev-chat-tg`, HTTP 3005, IPv4, HTTP1; health check `/health`, healthy 2, unhealthy 3, timeout 5 s, interval 20 s, success code 200. Register no targets — the ECS service registers task IPs itself. Then set deregistration delay 30 s and **stickiness** (load-balancer cookie, 1 day), which suits Socket.IO's polling fallback.

![Target groups](/images/workshop/runbook/img308.jpg)

![IP target type, HTTP 3005](/images/workshop/runbook/img309.jpg)

![Health check /health, thresholds 2/3, 5 s timeout, 20 s interval](/images/workshop/runbook/img310.jpg)

![No targets registered manually](/images/workshop/runbook/img311.jpg)

![Review: fitness-assistant-dev-chat-tg](/images/workshop/runbook/img312.jpg)

![Stickiness with a load-balancer cookie for 1 day](/images/workshop/runbook/img313.jpg)

**Step 19 — Application Load Balancer.** `fitness-assistant-dev-chat-alb`, internet-facing, IPv4, subnets `public-a` and `public-b`, security group `fitness-assistant-dev-chat-alb-sg` only, listener HTTP:80 → forward to `fitness-assistant-dev-chat-tg`. Record the DNS name `fitness-assistant-dev-chat-alb-<id>.ap-southeast-1.elb.amazonaws.com`.

![Load balancers](/images/workshop/runbook/img314.jpg)

![Choose Application Load Balancer](/images/workshop/runbook/img315.jpg)

![Internet-facing, IPv4, public-a and public-b](/images/workshop/runbook/img316.jpg)

![Listener HTTP:80 forwarding to the Chat target group](/images/workshop/runbook/img317.jpg)

![ALB details and DNS name](/images/workshop/runbook/img318.jpg)

**Step 20 — Idle timeout 120 s.** ALB → *Attributes* → idle timeout from 60 to **120 seconds**, better suited to long-lived WebSocket connections.

![Idle timeout set to 2 minutes](/images/workshop/runbook/img319.jpg)

**Step 21 — Hide internal paths.** The default listener action forwards every path, including `/internal/*` and `/metrics`. Add two rules to *HTTP:80*: priority 1, path `/internal/*` → fixed response 404 `text/plain` "Not Found"; priority 2, path `/metrics` → the same. `/health`, `/chat/*` and `/socket.io/*` still reach the container.

![Rule: path /internal/* returns a fixed 404](/images/workshop/runbook/img320.jpg)

![Rule priority 1 above the default rule](/images/workshop/runbook/img321.jpg)

#### Part G — Service

**Step 22 — ECS service.** Cluster → *Services → Create*:

| Setting | Value |
|---|---|
| Compute | Launch type **FARGATE**, platform `LATEST` |
| Task definition | `fitness-assistant-dev-chat` (latest revision) |
| Service name | `fitness-assistant-dev-chat-service`, replica, **1 desired task** |
| Networking | `private-app-a` + `private-app-b` only, security group `fitness-assistant-dev-chat-sg`, **public IP off** |
| Load balancing | existing ALB `fitness-assistant-dev-chat-alb`, container `chat-service 3005:3005`, existing listener HTTP:80, existing target group `fitness-assistant-dev-chat-tg` |
| Health check grace period | 60 s |
| Service Connect / discovery / auto scaling | off |

Desired count stays **1**: Socket.IO session state is kept in memory, so a second task would split sessions until a shared adapter (e.g. Redis) is added.

![Cluster page: task definition fitness-assistant-dev-chat:1 created](/images/workshop/runbook/img322.jpg)

![Launch type Fargate, platform LATEST](/images/workshop/runbook/img323.jpg)

![Service fitness-assistant-dev-chat-service from the task definition family](/images/workshop/runbook/img324.jpg)

![Replica scheduling, 1 desired task](/images/workshop/runbook/img325.jpg)

![Private app subnets, chat-sg, public IP turned off](/images/workshop/runbook/img326.jpg)

![Existing ALB and container chat-service 3005:3005](/images/workshop/runbook/img327.jpg)

![Existing listener (with the /internal and /metrics rules) and target group](/images/workshop/runbook/img328.jpg)

![Final service settings](/images/workshop/runbook/img329.jpg)

Right after creation the service shows *Running 0 / Pending 1* while it pulls the image, injects secrets and creates the ENI. If a task stops, read *Stopped reason* and the service *Events* instead of recreating the service.

**Step 23 — Verify.** The service runs 1/1 tasks and the target group reports one **Healthy** private IP on port 3005.

![Service active: 1/1 tasks running, deployment completed](/images/workshop/runbook/img330.jpg)

![Target 10.0.11.164:3005 healthy](/images/workshop/runbook/img331.jpg)

Then `http://<alb-dns>/health`, and the Socket.IO handshake `http://<alb-dns>/socket.io/?EIO=4&transport=polling`, which must answer `0{"sid":"…","upgrades":["websocket"],…}` — not 404, 502 or 503. See [5.5.3](../../5.5-Test-Validation/5.5.3-Chat-Health-SocketIO/).

#### Part H — Wire it into the API and the frontend

**Step 24 — REST through API Gateway.** In `fitness-assistant-dev-api` create route `ANY /chat/{proxy+}` with an **HTTP URI** integration: method `ANY`, URL `http://<alb-dns>/chat/{proxy}`. The `{proxy}` part matters — `/chat/conversations` must reach the backend as `/chat/conversations`. Test with `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/chat/conversations` (a Bearer token is needed for real data).

![HTTP URI integration for ANY /chat/{proxy+} pointing at the ALB](/images/workshop/runbook/img333.jpg)

**Step 25 — Frontend.** Set the Socket.IO URL (`VITE_CHAT_WS_URL`) to the ALB, rebuild and republish with the [redeploy procedure](../5.4.3-Frontend-S3/#redeploy):

```
REST:      Frontend → API Gateway → /chat/{proxy+} → Chat ALB → ECS
Socket.IO: Frontend → Chat ALB → /socket.io/ → ECS
```

**Step 26 — Roll out the fixed task definition.** ECS → `fitness-assistant-dev-cluster` → `fitness-assistant-dev-chat-service` → *Update* → task definition `fitness-assistant-dev-chat:3`, everything else unchanged, *Force new deployment*. Target state: 1 running, 0 pending, deployment *Completed*, and no more `URL must start with postgresql://` in `/ecs/fitness-assistant-dev-chat`.
