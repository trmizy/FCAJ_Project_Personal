---
title: "Chat Service on ECS Fargate"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 5.4.10. </b> "
---

Chat is the only service that does not run on Lambda: Socket.IO keeps a connection open for the whole chat session, which does not fit Lambda's per-invocation model. It runs as one container on ECS Fargate, behind its own Application Load Balancer.

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

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

**Step 1 — Database secret.** Reuse the username/password/host/port of a working database secret and change only the database name. The secret only stores connection details — the database itself is created by the migration Lambda.

**1.1 — Open Secrets Manager.** The list shows the existing secrets (AI, payment, gym, fitness, user, base). Click **Store a new secret**.

![Secrets list and the Store a new secret button](/images/workshop/runbook/img236.jpg)

**1.2 — Paste the JSON.** Choose **Other type of secret**, open the **Plaintext** tab and replace the content with the JSON below (placeholders — use the real Aurora credentials; the screenshot's own placeholders are in Vietnamese).

```json
{
  "username": "<Aurora username>",
  "password": "<Aurora password>",
  "host": "fitness-assistant-dev-aurora.cluster-<id>.ap-southeast-1.rds.amazonaws.com",
  "port": 5432,
  "database": "fitness_assistant_chat"
}
```

![Other type of secret, Plaintext tab and the JSON editor](/images/workshop/runbook/img237.jpg)

**1.3 — Name it.** Name `fitness-assistant/dev/chat-database`, description "Chat Service Aurora PostgreSQL database – dev", then **Next**. The default `aws/secretsmanager` key stays.

![Secret name, description and Next](/images/workshop/runbook/img238.jpg)

**1.4 — Leave rotation off.** Keep **Automatic rotation** off and click **Next**.

![Automatic rotation switch (off) and Next](/images/workshop/runbook/img239.jpg)

**1.5 — Store it.** Review the summary and click **Store**.

![Review page and the Store button](/images/workshop/runbook/img240.jpg)

**Step 2 — Migration role.** `fitness-assistant-dev-chat-migrate-role` ("Execution role for Chat Service database migration Lambda") with `AWSLambdaBasicExecutionRole` + `AWSLambdaVPCAccessExecutionRole` and the inline policy `fitness-assistant-dev-chat-migrate-secret` (`secretsmanager:GetSecretValue` on `fitness-assistant/dev/chat-database*` only). No Bedrock, SQS, OpenSearch or invoke permissions — the migration needs only logs, VPC access and its secret.

**2.1 — Start the role.** **IAM → Roles → Create role**.

![IAM roles list and Create role](/images/workshop/runbook/img241.jpg)

**2.2 — Trusted entity.** **AWS service**, use case **Lambda**, **Next**.

![AWS service, use case Lambda and Next](/images/workshop/runbook/img242.jpg)

**2.3 — Pick the managed policies.** Search `AWSLambdaVPCAccessExecutionRole` and tick it next to `AWSLambdaBasicExecutionRole` (2 selected), then **Next**.

![Search AWSLambdaVPCAccessExecutionRole, the ticked row and Next](/images/workshop/runbook/img243.jpg)

**2.4 — Name the role.** `fitness-assistant-dev-chat-migrate-role`, description "Execution role for Chat Service database migration Lambda".

![Role name and description](/images/workshop/runbook/img244.jpg)

**2.5 — Create the role.** The summary lists the two managed policies; click **Create role**.

![The two managed policies and Create role](/images/workshop/runbook/img245.jpg)

**2.6 — Add an inline policy.** On the new role click **Add permissions → Create inline policy**.

![Role created and the Add permissions button](/images/workshop/runbook/img246.jpg)

**2.7 — Write the policy.** Switch to **JSON** and allow `secretsmanager:GetSecretValue` on `arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/chat-database*`.

![JSON editor with the Chat secret statement](/images/workshop/runbook/img248.jpg)

**2.8 — Name and create it.** `fitness-assistant-dev-chat-migrate-secret`, **Create policy**.

![Policy name and Create policy](/images/workshop/runbook/img250.jpg)

**2.9 — Check the role.** It now has three permission entries.

![Role with the inline policy fitness-assistant-dev-chat-migrate-secret](/images/workshop/runbook/img251.jpg)

**Step 3 — Migration Lambda.** At this point the account already ran 15 functions.

**3.1 — Open the function list.** **Lambda → Functions** shows 15 functions; click **Create function**.

![Functions (15) and Create function](/images/workshop/runbook/img252.jpg)

**3.2 — Fill in the function.** **Author from scratch**, name `fitness-assistant-dev-chat-migrate`, runtime **Node.js 22.x** (x86_64), and in the custom execution role panel choose `fitness-assistant-dev-chat-migrate-role`, **Save**.

![Author from scratch, name, runtime and the migrate role](/images/workshop/runbook/img253.jpg)

**3.3 — Create it.** Check that the custom execution role is the migrate role and click **Create function**.

![Custom execution role link and Create function](/images/workshop/runbook/img254.jpg)

**3.4 — Upload the code.** **Upload from → .zip file** with `backend/services/chat-service/artifacts/chat-migrate-lambda.zip`, then **Update**.

*The runbook has no screenshot of this upload; the dialog is the same as in [5.4.8 Step 2.6](../5.4.8-AI-Service-Core/).*

**3.5 — Set the handler.** **Code → Runtime settings → Edit**: `dist/migrate-lambda.handler`, **Save**.

![Handler dist/migrate-lambda.handler and Save](/images/workshop/runbook/img255.jpg)

**3.6 — Set memory and timeout.** **Memory** `1024` MB, **Timeout** `1` min `0` sec, **Save**.

![Memory 1024 MB, timeout 1 minute, Save](/images/workshop/runbook/img256.jpg)

**3.7 — Open the environment variables.** There are none yet; click **Edit**.

![Environment variables (0) and the Edit button](/images/workshop/runbook/img257.jpg)

**3.8 — Add the variable.** `DATABASE_SECRET_ID` = `fitness-assistant/dev/chat-database`, **Save**.

![DATABASE_SECRET_ID for the Chat database and Edit](/images/workshop/runbook/img258.jpg)

**3.9 — Open the VPC settings.** No VPC is configured yet; click **Edit**.

![No VPC configuration and the Edit button](/images/workshop/runbook/img259.jpg)

**3.10 — Attach the VPC.** The project VPC, both private app subnets and the Lambda SG, **Save**.

![VPC, two private app subnets, Lambda security group and Save](/images/workshop/runbook/img260.jpg)

**Step 4 — Run the migration.**

**4.1 — Create the test event.** On the **Test** tab choose **Create new event**, name `chat-migrate`, keep `{}` and click **Test**.

![Event name chat-migrate and the Test button](/images/workshop/runbook/img261.jpg)

**4.2 — Read the result.** Expected: `status: ok`, `database: fitness_assistant_chat`, `databaseCreated: true` (false if it already existed), `migrateExitCode: 0`, 3 migrations applied. If it fails, record the error instead of re-running it repeatedly.

![Executing function succeeded and the response with 3 migrations applied](/images/workshop/runbook/img262.jpg)

#### Part B — Container image

**Step 5 — ECR repository.**

**5.1 — Open ECR.** The private repositories (8) come from the earlier container phase. Click **Create repository**.

![Private repositories (8) and Create repository](/images/workshop/runbook/img263.jpg)

**5.2 — Fill in the repository.** Private, name `fitness-assistant-dev-chat`, tag mutability **Mutable** (tags are reused during DEV; production should use commit-based tags such as `git-a84f23c`), AES-256 encryption, then **Create**. The scan-on-push option now shows as "deprecated" in this console.

![Repository name, Mutable and Create](/images/workshop/runbook/img264.jpg)

**Step 6 — Push the image** from PowerShell on the workstation. Build only if the image is missing:

```powershell
docker images gymini-chat-service
# only if missing:
docker build --platform linux/amd64 -t gymini-chat-service:aws-local -f backend/services/chat-service/Dockerfile .

aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag gymini-chat-service:aws-local <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1
```

**6.1 — Check the local image.** Run `docker images gymini-chat-service`; the image `gymini-chat-service:aws-local` (146 MB compressed) must be listed.

![The docker images command and the image row](/images/workshop/runbook/img265.jpg)

**6.2 — Log in to ECR.** Run the `aws ecr get-login-password … | docker login …` line. `Login Succeeded` must appear before tagging; `'aws' is not recognized`, `Unable to locate credentials` or `AccessDeniedException` mean stopping to fix the CLI setup first.

![The login command and Login Succeeded](/images/workshop/runbook/img266.jpg)

**6.3 — Tag the image.** Run `docker tag …` with the ECR URI and the tag `dev-20260922-1`.

![The docker tag command](/images/workshop/runbook/img267.jpg)

**6.4 — Push.** Run `docker push …`; every layer must say `Pushed` and the last line shows the digest.

![The docker push command and the final digest line](/images/workshop/runbook/img268.jpg)

**6.5 — Check in ECR.** Open the repository: the tag `dev-20260922-1` is listed (image index plus its two images).

![Tag dev-20260922-1 in the repository](/images/workshop/runbook/img269.jpg)

#### Part C — Logs and IAM

**Step 7 — Log group.**

**7.1 — Create it.** **CloudWatch → Log groups → Create log group**: name `/ecs/fitness-assistant-dev-chat` (ECS convention, not `/aws/lambda/...`), retention **1 month (30 days)**, then **Create**.

![Log group name, retention 1 month and Create](/images/workshop/runbook/img270.jpg)

**7.2 — Check the list.** Filter the log group list for `/ecs/fitness-assistant-dev-chat`.

![Log groups list and the filter box](/images/workshop/runbook/img271.jpg)

**Step 8 — Task execution role** (used by ECS itself to pull the image, write logs and inject secrets — not by the application).

**8.1 — Start the role.** **IAM → Roles → Create role** (the banner is the earlier policy confirmation).

![IAM roles list and Create role](/images/workshop/runbook/img272.jpg)

**8.2 — Trusted entity.** **AWS service**, service **Elastic Container Service**, use case **Elastic Container Service Task**.

![AWS service, Elastic Container Service and the Task use case](/images/workshop/runbook/img273.jpg)

**8.3 — Managed policy.** Search `AmazonECSTaskExecutionRolePolicy`, tick it and click **Next**.

![Search AmazonECSTaskExecutionRolePolicy, ticked row and Next](/images/workshop/runbook/img274.jpg)

**8.4 — Name the role.** `fitness-assistant-dev-chat-execution-role`, description "ECS task execution role for Chat Service dev"; the trust policy names `ecs-tasks.amazonaws.com`.

![Role name and description](/images/workshop/runbook/img275.jpg)

**8.5 — Create the role.** The summary shows one managed policy; click **Create role**.

![AmazonECSTaskExecutionRolePolicy and Create role](/images/workshop/runbook/img276.jpg)

**8.6 — Add an inline policy.** On the created role open **Add permissions → Create inline policy**.

![Add permissions menu with Create inline policy](/images/workshop/runbook/img277.jpg)

**8.7 — Write the policy.** `secretsmanager:GetSecretValue` on the Chat secrets (at first only `chat-database*`; it is extended in Step 13). Name it `fitness-assistant-dev-chat-execution-secrets`.

![JSON editor with the Chat secret statement and Next](/images/workshop/runbook/img278.jpg)

**8.8 — Check the role.** It now has the managed policy plus the inline policy.

![Execution role with both policies](/images/workshop/runbook/img279.jpg)

**Step 9 — Task role** (what the Chat code uses at runtime). Same trusted entity (ECS Task), no managed policy, name `fitness-assistant-dev-chat-task-role`. No Secrets Manager permissions here — secrets are injected by the execution role.

**9.1 — Create the role and open Add permissions.** The role exists with 0 policies; click **Add permissions → Create inline policy**.

![Task role created and Add permissions](/images/workshop/runbook/img280.jpg)

**9.2 — Write the policy.** JSON: `lambda:InvokeFunction` on `fitness-assistant-dev-auth` and `fitness-assistant-dev-user` only, then **Next**.

![JSON editor: invoke the Auth and User Lambdas, Next](/images/workshop/runbook/img281.jpg)

**9.3 — Name and create it.** `fitness-assistant-dev-chat-service-invoke`, **Create policy**.

![Policy name and Create policy](/images/workshop/runbook/img282.jpg)

#### Part D — Network

**Step 10 — Security group for the task.**

**10.1 — Open Security groups.** **EC2 → Security Groups** lists the five existing groups; click **Create security group**.

![Security groups before the Chat groups and Create security group](/images/workshop/runbook/img283.jpg)

**10.2 — Fill in the group.** Name `fitness-assistant-dev-chat-sg`, description "Security group for Chat Service Fargate tasks", the project VPC, **no inbound rule yet**, default outbound (the task calls the Auth/User Lambdas, Aurora and DNS). Click **Create security group**.

![Name, description, VPC, no inbound rules and Create security group](/images/workshop/runbook/img284.jpg)

**Step 11 — Let the task reach Aurora.** Never open 5432 to `0.0.0.0/0`.

**11.1 — Open the Aurora security group.** **RDS → `fitness-assistant-dev-aurora` → Connectivity & security**, then click the Aurora security group link under **Security group rules**.

![Aurora security group link in Security group rules](/images/workshop/runbook/img285.jpg)

**11.2 — Edit the inbound rules.** On the **Inbound rules** tab click **Edit inbound rules**.

![Inbound rules (2) and Edit inbound rules](/images/workshop/runbook/img286.jpg)

**11.3 — Add the rule.** **Add rule**: PostgreSQL, TCP 5432, source = the security group `fitness-assistant-dev-chat-sg`, description "Allow Chat Fargate tasks to Aurora", then **Save rules**.

![Add rule, the new PostgreSQL row with the Chat SG, Save rules](/images/workshop/runbook/img287.jpg)

**Step 12 — ECS cluster.**

**12.1 — Start the cluster.** **ECS → Clusters** shows none; click **Create cluster**.

![Clusters (0) and Create cluster](/images/workshop/runbook/img288.jpg)

**12.2 — Fill in the cluster.** Name `fitness-assistant-dev-cluster`, infrastructure **Fargate only**, no EC2 capacity, no Service Connect, then **Create**.

![Cluster name, Fargate only and Create](/images/workshop/runbook/img289.jpg)

**12.3 — Check the cluster.** It appears in the list.

![Cluster fitness-assistant-dev-cluster listed](/images/workshop/runbook/img290.jpg)

#### Part E — Runtime secrets and task definition

**Step 13 — Runtime secrets.** The Chat code reads `CHAT_DATABASE_URL`, not `DATABASE_URL`.

**13.1 — Open Secrets Manager.** The new `chat-database` secret is at the top of the list. Click **Store a new secret** again.

![Secrets list with chat-database and Store a new secret](/images/workshop/runbook/img291.jpg)

**13.2 — Create the URL secret.** **Other type of secret**, a key/value row with key `CHAT_DATABASE_URL` and value `postgresql://USERNAME:PASSWORD@<aurora-endpoint>:5432/fitness_assistant_chat?schema=public` (URL-encode special characters in the password, e.g. `@` → `%40`). Name `fitness-assistant/dev/chat-database-url`, description "Chat Service PostgreSQL connection URL - dev", then **Next** and store it.

![Secret name, description and Next](/images/workshop/runbook/img292.jpg)

**13.3 — Internal secret.** Reuse the shared internal secret as `fitness-assistant/dev/internal-service-secret` (same value the Lambdas use, never a new one).

*The runbook has no screenshot of this action.*

**13.4 — Extend the execution role policy.** In `fitness-assistant-dev-chat-execution-secrets` list both ARNs (`chat-database*` and `chat-database-url*`; also the internal secret) and click **Next**.

![Policy editor with both secret ARNs and Next](/images/workshop/runbook/img293.jpg)

**Step 14 — Task definition.** **ECS → Task definitions → Create new task definition**:

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

**14.1 — Open the page.** There are no task definitions yet; click **Create new task definition**.

![Task definitions (0) and Create new task definition](/images/workshop/runbook/img294.jpg)

**14.2 — Family, size and roles.** Family `fitness-assistant-dev-chat`, **AWS Fargate**, **Linux/X86_64**, **.5 vCPU**, **1 GB**, task role `fitness-assistant-dev-chat-task-role`, execution role `fitness-assistant-dev-chat-execution-role`.

![Family, Fargate, OS, CPU, memory, task role and execution role](/images/workshop/runbook/img295.jpg)

**14.3 — Container.** Name `chat-service`, essential **Yes**, image URI `<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-chat:dev-20260922-1`, container port `3005`, TCP, port name `chat-http`, app protocol HTTP.

![Container name, image URI and port mapping 3005](/images/workshop/runbook/img296.jpg)

**14.4 — Environment.** Add the eight variables. For the two secret entries, `CHAT_DATABASE_URL` and `INTERNAL_SERVICE_SECRET`, choose value type **ValueFrom** and paste the full secret ARN plus the JSON key suffix (for example `…:CHAT_DATABASE_URL::`). Plain values go in the other six rows.

**14.5 — Logging.** Tick **Use log collection**, destination **Amazon CloudWatch**, `awslogs-group` = `/ecs/fitness-assistant-dev-chat`, `awslogs-region` = `ap-southeast-1`, `awslogs-stream-prefix` = `chat`.

![Log collection to /ecs/fitness-assistant-dev-chat](/images/workshop/runbook/img298.jpg)

**14.6 — Storage and tags.** Leave ephemeral storage at 20 GiB; add tags `Project=fitness-assistant`, `Environment=dev`, `Service=chat`; click **Create**.

![Ephemeral storage, the three tags and Create](/images/workshop/runbook/img299.jpg)

{{% notice info %}}
Secrets must use **ValueFrom** with the full secret ARN so the container receives the real connection string at start. Never paste real secret values into plain environment variables.
{{% /notice %}}

#### Part F — Load balancer

**Step 15 — ALB security group.** HTTP 80 from `0.0.0.0/0` (the frontend itself is still HTTP; HTTPS 443 comes with a domain and ACM certificate).

**15.1 — Check the list.** The banner confirms `chat-sg` was created (6 groups). Click **Create security group**.

![Chat SG created banner and Create security group](/images/workshop/runbook/img300.jpg)

**15.2 — Fill in the group.** Name `fitness-assistant-dev-chat-alb-sg`, description "ALB security group for Fitness Assistant Chat dev", the project VPC; inbound rule **HTTP**, source **Anywhere-IPv4 0.0.0.0/0**; **Create security group**.

![Name, description, VPC, inbound HTTP from anywhere and Create](/images/workshop/runbook/img301.jpg)

**15.3 — Check it.** The banner confirms the creation; the group has one inbound entry (HTTP 80, 0.0.0.0/0).

![ALB security group created and its inbound rule](/images/workshop/runbook/img302.jpg)

**Step 16 — Only the ALB may reach the task.** Port 3005 is never opened to `0.0.0.0/0`.

**16.1 — Edit the task group's inbound rules.** In `fitness-assistant-dev-chat-sg` add **Custom TCP**, port `3005`, source = security group `fitness-assistant-dev-chat-alb-sg`, description "Allow Chat ALB to reach ECS task", then **Save rules**.

![Custom TCP 3005 from the ALB security group and Save rules](/images/workshop/runbook/img303.jpg)

**16.2 — Check.** `chat-sg` now has one inbound rule: Custom TCP 3005 from the ALB SG.

![chat-sg inbound rule 3005 from the ALB SG](/images/workshop/runbook/img304.jpg)

**Step 17 — Second public subnet.** An internet-facing ALB needs two Availability Zones, so `fitness-assistant-dev-public-b` (10.0.2.0/24, `ap-southeast-1b`) was added — see [5.4.1, step 6](../5.4.1-Shared-Network/#second-public-subnet).

**Step 18 — Target group.**

**18.1 — Open Target groups.** **EC2 → Target groups** shows none; click **Create target group**.

![Target groups (none) and Create target group](/images/workshop/runbook/img308.jpg)

**18.2 — Settings.** Target type **IP addresses** (Fargate uses `awsvpc`, so not *Instances*), name `fitness-assistant-dev-chat-tg`, protocol HTTP, port `3005`, IPv4, the project VPC, protocol version HTTP1.

![IP addresses, name, HTTP 3005 and the VPC](/images/workshop/runbook/img309.jpg)

**18.3 — Health check.** Path `/health`; healthy threshold 2, unhealthy 3, timeout 5 s, interval 20 s, success code 200.

![Health check path /health, thresholds, timeout, interval and success codes](/images/workshop/runbook/img310.jpg)

**18.4 — Register no targets.** The ECS service registers task IPs itself; just click **Next**.

![Register targets page (no IP added) and Next](/images/workshop/runbook/img311.jpg)

**18.5 — Review and create.** Check the summary (HTTP 3005, `/health`, 0 targets) and click **Create target group**.

![Review: fitness-assistant-dev-chat-tg and Create target group](/images/workshop/runbook/img312.jpg)

**18.6 — Stickiness.** Afterwards set deregistration delay to 30 s and **Turn on stickiness**: load-balancer generated cookie, 1 day — this suits Socket.IO's polling fallback.

![Stickiness with a load balancer cookie for 1 day](/images/workshop/runbook/img313.jpg)

**Step 19 — Application Load Balancer.** `fitness-assistant-dev-chat-alb`, internet-facing, IPv4, subnets `public-a` and `public-b`, security group `fitness-assistant-dev-chat-alb-sg` only, listener HTTP:80 → forward to `fitness-assistant-dev-chat-tg`.

**19.1 — Open Load balancers.** None yet; click **Create load balancer**.

![Load balancers (none) and Create load balancer](/images/workshop/runbook/img314.jpg)

**19.2 — Choose the type.** Click **Create** under **Application Load Balancer**.

![Create under Application Load Balancer](/images/workshop/runbook/img315.jpg)

**19.3 — Basic configuration and network mapping.** Name `fitness-assistant-dev-chat-alb`, **Internet-facing**, **IPv4**, the project VPC, and tick both zones with their public subnets: `ap-southeast-1a` → `public-a`, `ap-southeast-1b` → `public-b`. Choose the security group `fitness-assistant-dev-chat-alb-sg` only (further down the page).

![Name, Internet-facing, IPv4, VPC and the two zones with public-a / public-b](/images/workshop/runbook/img316.jpg)

**19.4 — Listener.** Protocol **HTTP**, port `80`, default action **Forward to target groups**, target group `fitness-assistant-dev-chat-tg`. Then click **Create load balancer**.

![Listener HTTP:80, Forward to target groups and the chat target group](/images/workshop/runbook/img317.jpg)

**19.5 — Read the DNS name.** Open the new load balancer; state **Provisioning** while it starts. Record the DNS name `fitness-assistant-dev-chat-alb-<id>.ap-southeast-1.elb.amazonaws.com`, and open the **HTTP:80** listener.

![Load balancer details, DNS name and the HTTP:80 listener](/images/workshop/runbook/img318.jpg)

**Step 20 — Idle timeout 120 s.**

**20.1 — Edit the attribute.** ALB → **Attributes → Edit**: **Connection idle timeout** `0` hours `2` minutes `0` seconds (120 s), better suited to long-lived WebSocket connections; **Save changes**.

![Connection idle timeout 0 hours 2 minutes 0 seconds](/images/workshop/runbook/img319.jpg)

**Step 21 — Hide internal paths.** The default listener action forwards every path, including `/internal/*` and `/metrics`. Add two rules to *HTTP:80*; `/health`, `/chat/*` and `/socket.io/*` still reach the container.

**21.1 — Rule 1: `/internal/*`.** In the listener click **Add rule**. Condition **Path** with the value `/internal/*` (value matching); action **Return fixed response**: response code `404`, content type `text/plain`, body `Not found`; click **Next**.

![Path /internal/*, Return fixed response 404 text/plain and Next](/images/workshop/runbook/img320.jpg)

**21.2 — Priority.** Set priority `1` (above the default rule) and click **Next**, then create the rule.

![Priority 1 above the default rule and Next](/images/workshop/runbook/img321.jpg)

**21.3 — Rule 2: `/metrics`.** Repeat 21.1–21.2 with path `/metrics` and priority `2` (the same fixed 404 response).

*The runbook has no screenshot of the second rule; the ECS service screen in Step 22 lists both rules.*

#### Part G — Service

**Step 22 — ECS service.** **Cluster → Services → Create**:

| Setting | Value |
|---|---|
| Compute | Launch type **FARGATE**, platform `LATEST` |
| Task definition | `fitness-assistant-dev-chat` (latest revision) |
| Service name | `fitness-assistant-dev-chat-service`, replica, **1 desired task** |
| Networking | `private-app-a` + `private-app-b` only, security group `fitness-assistant-dev-chat-sg`, **public IP off** |
| Load balancing | existing ALB `fitness-assistant-dev-chat-alb`, container `chat-service 3005:3005`, existing listener HTTP:80, existing target group `fitness-assistant-dev-chat-tg` |
| Health check grace period | 60 s |
| Service Connect / discovery / auto scaling | off |

**22.1 — Open the cluster.** The banner says task definition `fitness-assistant-dev-chat:1` was created; the cluster has no services. Click **Create** in the Services tab.

![Task definition created banner, Services (0) and Create](/images/workshop/runbook/img322.jpg)

**22.2 — Compute.** Compute options **Launch type**, launch type **Fargate**, platform version **LATEST**.

![Launch type, Fargate and LATEST](/images/workshop/runbook/img323.jpg)

**22.3 — Service details.** Task definition family `fitness-assistant-dev-chat`, revision (latest — the screenshot shows `1`), service name `fitness-assistant-dev-chat-service`.

![Task definition family, revision and service name](/images/workshop/runbook/img324.jpg)

**22.4 — Deployment configuration.** Scheduling strategy **Replica**, **Desired tasks** `1`, health check grace period `60` seconds (the screenshot still shows the empty default `0`).

![Replica and desired tasks 1](/images/workshop/runbook/img325.jpg)

**22.5 — Networking.** The project VPC, the two private app subnets (`private-app-a`, `private-app-b`), **Use an existing security group** with `fitness-assistant-dev-chat-sg`, and **Public IP** turned off.

![VPC, private app subnets, chat-sg and Public IP turned off](/images/workshop/runbook/img326.jpg)

**22.6 — Load balancer.** Tick **Use load balancing**, type **Application Load Balancer**, container `chat-service 3005:3005`, **Use an existing load balancer** `fitness-assistant-dev-chat-alb`.

![Application Load Balancer, container chat-service 3005:3005 and the existing ALB](/images/workshop/runbook/img327.jpg)

**22.7 — Listener and target group.** **Use an existing listener** `HTTP:80` (the rules list shows `/internal/*` priority 1, `/metrics` priority 2 and the default rule) and **Use an existing target group** `fitness-assistant-dev-chat-tg`.

![Existing listener HTTP:80 with its three rules and the existing target group](/images/workshop/runbook/img328.jpg)

**22.8 — Create.** Leave VPC Lattice, auto scaling, volume and tags off, and click **Create**.

![Target group name and the Create button](/images/workshop/runbook/img329.jpg)

Desired count stays **1**: Socket.IO session state is kept in memory, so a second task would split sessions until a shared adapter (e.g. Redis) is added. Right after creation the service shows *Running 0 / Pending 1* while it pulls the image, injects secrets and creates the ENI. If a task stops, read *Stopped reason* and the service *Events* instead of recreating the service.

**Step 23 — Verify.**

**23.1 — Service state.** The service is **Active**, deployment **Completed** and the tasks column reads **1/1 Tasks running**.

![Service active: 1/1 tasks running, deployment completed](/images/workshop/runbook/img330.jpg)

**23.2 — Target health.** In the target group, **Healthy** is 1 and the registered target `10.0.11.164:3005` is **Healthy**.

![Healthy 1 and target 10.0.11.164:3005](/images/workshop/runbook/img331.jpg)

**23.3 — Call it.** Open `http://<alb-dns>/health`, and the Socket.IO handshake `http://<alb-dns>/socket.io/?EIO=4&transport=polling`, which must answer `0{"sid":"…","upgrades":["websocket"],…}` — not 404, 502 or 503. See [5.5.3](../../5.5-Test-Validation/5.5.3-Chat-Health-SocketIO/).

#### Part H — Wire it into the API and the frontend

**Step 24 — REST through API Gateway.**

**24.1 — Create the integration.** In `fitness-assistant-dev-api` create an integration attached to route `ANY /chat/{proxy+}`: type **HTTP URI**, method `ANY`, URL `http://<alb-dns>/chat/{proxy}`, then **Create**. The `{proxy}` part matters — `/chat/conversations` must reach the backend as `/chat/conversations`.

![Route ANY /chat/{proxy+}, HTTP URI, method ANY, the ALB URL and Create](/images/workshop/runbook/img333.jpg)

**24.2 — Test.** `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/chat/conversations` (a Bearer token is needed for real data).

**Step 25 — Frontend.** Set the Socket.IO URL (`VITE_CHAT_WS_URL`) to the ALB, rebuild and republish with the [redeploy procedure](../5.4.3-Frontend-S3/#redeploy):

```
REST:      Frontend → API Gateway → /chat/{proxy+} → Chat ALB → ECS
Socket.IO: Frontend → Chat ALB → /socket.io/ → ECS
```

**Step 26 — Roll out the fixed task definition.** ECS → `fitness-assistant-dev-cluster` → `fitness-assistant-dev-chat-service` → *Update* → task definition `fitness-assistant-dev-chat:3`, everything else unchanged, *Force new deployment*. Target state: 1 running, 0 pending, deployment *Completed*, and no more `URL must start with postgresql://` in `/ecs/fitness-assistant-dev-chat`.

*The runbook has no screenshot of Steps 25 and 26.*
