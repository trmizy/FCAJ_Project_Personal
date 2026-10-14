---
title: "5.4.11 Data migration to Aurora"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 5.4.11. </b> "
---

The schemas on Aurora were created by each service's migration Lambda. This last step moved the **data** of the 7 local PostgreSQL databases into them — keeping the original IDs, without reseeding — using a one-shot ECS Fargate task that runs `pg_restore` inside the VPC.

The order was fixed in advance so nothing could be corrupted halfway:

1. Upload the 7 dumps and their manifest to a private S3 bucket.
2. Make sure all 7 logical databases exist on Aurora (including `fitness_assistant_chat`).
3. Apply the latest schema migrations to all 7.
4. Build and push a migrator image to ECR.
5. Run a read-only preflight task.
6. Restore every database.
7. Compare row counts / primary keys.
8. Only then handle uploaded files and vector data.

#### Step 1 — Private migration bucket

S3 → *Create bucket* `fitness-assistant-data-migration-dev-<account-id>` in `ap-southeast-1`: **Block all public access on**, **versioning enabled**, SSE-S3 encryption, no static website. A dedicated bucket keeps dumps away from the public frontend bucket and the user-uploads bucket.

![Bucket fitness-assistant-data-migration-dev created](/images/workshop/runbook/img336.jpg)

Create the prefixes `full-local-migration/2026-09/dumps/`, `manifests/` and `user-files/`.

![Create folder](/images/workshop/runbook/img337.jpg)

![full-local-migration/](/images/workshop/runbook/img338.jpg)

![2026-09/ with dumps/, manifests/ and user-files/](/images/workshop/runbook/img339.jpg)

#### Step 2 — Upload the dumps and the manifest

Upload the 7 audited dumps unchanged (not unzipped, not converted to SQL): `gymcoach_auth`, `_user`, `_fitness`, `_gym`, `_payment`, `_chat` and `_ai` `.data.dump` — 72.9 MB in total — then the SHA-256 `manifest.json` to `manifests/`.

![Uploading the 7 dumps (72.9 MB) to dumps/](/images/workshop/runbook/img340.jpg)

![Upload succeeded: 7 files](/images/workshop/runbook/img342.jpg)

![Uploading manifest.json to manifests/](/images/workshop/runbook/img343.jpg)

{{% notice warning %}}
Never upload `.env`, `.env.production`, database passwords, `JWT_SECRET`, `INTERNAL_SERVICE_SECRET`, AWS credentials or provider API keys to this bucket.
{{% /notice %}}

#### Step 3 — Migrator image

A minimal image with only `pg_restore` and the AWS CLI, reusable for all 7 databases (and later for CI/CD). Create the ECR repository `fitness-assistant-dev-db-migrator` (private, mutable, AES-256).

![Create repository fitness-assistant-dev-db-migrator](/images/workshop/runbook/img344.jpg)

`tools/db-migrator/Dockerfile`:

```dockerfile
FROM postgres:16-bookworm
RUN apt-get update \
    && apt-get install -y --no-install-recommends awscli ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'db-migrator ready'"]
```

```powershell
docker build -t fitness-assistant-db-migrator:dev .
docker run --rm fitness-assistant-db-migrator:dev "pg_restore --version && aws --version"   # pg_restore 16.15, aws-cli 2.9.19
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag fitness-assistant-db-migrator:dev <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-db-migrator:dev-20260923-1
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-db-migrator:dev-20260923-1
```

![Pushing fitness-assistant-dev-db-migrator:dev-20260923-1](/images/workshop/runbook/img345.jpg)

#### Step 4 — Roles

**Execution role** `fitness-assistant-dev-db-migrator-execution-role` (ECS task, `AmazonECSTaskExecutionRolePolicy`) — pulls the image and writes logs.

![AmazonECSTaskExecutionRolePolicy](/images/workshop/runbook/img346.jpg)

![Role fitness-assistant-dev-db-migrator-execution-role, trusted by ecs-tasks](/images/workshop/runbook/img347.jpg)

**Task role** `fitness-assistant-dev-db-migrator-task-role` with the inline policy `fitness-assistant-dev-db-migrator-runtime` — read the dumps prefix only, and read the Aurora credential:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadMigrationDumps",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::fitness-assistant-data-migration-dev-<account-id>/full-local-migration/2026-09/dumps/*"]
    },
    {
      "Sid": "ListMigrationDumpPrefix",
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": ["arn:aws:s3:::fitness-assistant-data-migration-dev-<account-id>"],
      "Condition": { "StringLike": { "s3:prefix": ["full-local-migration/2026-09/dumps/*"] } }
    },
    {
      "Sid": "ReadAuroraCredential",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:fitness-assistant/dev/chat-database-*"]
    }
  ]
}
```

![Runtime policy JSON](/images/workshop/runbook/img348.jpg)

![Policy fitness-assistant-dev-db-migrator-runtime: S3 and Secrets Manager](/images/workshop/runbook/img349.jpg)

![Task role fitness-assistant-dev-db-migrator-task-role](/images/workshop/runbook/img350.jpg)

#### Step 5 — Task definition

ECS → *Create new task definition* `fitness-assistant-dev-db-migrator`: Fargate, Linux/X86_64, `awsvpc`, **1 vCPU / 2 GB**, the two roles, container `db-migrator` with image `…/fitness-assistant-dev-db-migrator:dev-20260923-1`, no port mapping needed, environment `AWS_REGION=ap-southeast-1`, `DB_SECRET_ID=fitness-assistant/dev/chat-database`, `DUMP_S3_PREFIX=s3://fitness-assistant-data-migration-dev-<account-id>/full-local-migration/2026-09/dumps`, logs to `/ecs/fitness-assistant-dev-db-migrator`, default ephemeral storage (far more than the 73 MB of dumps). No command is set — it is overridden at run time.

![Family fitness-assistant-dev-db-migrator: Fargate, 1 vCPU, 2 GB](/images/workshop/runbook/img351.jpg)

![Task and execution roles, container db-migrator and its image](/images/workshop/runbook/img352.jpg)

![Container settings](/images/workshop/runbook/img353.jpg)

![Environment variables and log collection](/images/workshop/runbook/img354.jpg)

![Ephemeral storage, then Create](/images/workshop/runbook/img355.jpg)

#### Step 6 — Inject the database URL as a secret (revision 2)

Give the execution role `secretsmanager:GetSecretValue` on the `chat-database-url` secret (inline policy `fitness-assistant-dev-db-migrator-secret`), then create **revision 2** with a secret environment variable `DATABASE_URL`, value type *ValueFrom*, value `<chat-database-url secret ARN>:CHAT_DATABASE_URL::`. `DB_SECRET_ID` is no longer needed.

![Execution role policy for the database URL secret](/images/workshop/runbook/img356.jpg)

![Task definition fitness-assistant-dev-db-migrator:2 active](/images/workshop/runbook/img357.jpg)

The script derives the server URL from `DATABASE_URL` and switches the database name per restore, so one credential serves all 7 logical databases on the same cluster.

#### Step 7 — Preflight (read-only)

ECS → `fitness-assistant-dev-cluster` → *Tasks → Run new task*: FARGATE, `fitness-assistant-dev-db-migrator:2`, 1 task, private app subnets, security group `fitness-assistant-dev-chat-sg` (already allowed into Aurora on 5432 and into the Secrets Manager endpoint), public IP disabled, no load balancer. Command override for `db-migrator`:

```bash
set -euo pipefail; echo "=== DB MIGRATOR PREFLIGHT START ==="; echo "Region=$AWS_REGION"; echo "Prefix=$DUMP_S3_PREFIX"; test -n "${DATABASE_URL:-}"; PSQL_URL="${DATABASE_URL%%\?*}"; mkdir -p /work/dumps; aws s3 ls "$DUMP_S3_PREFIX/"; aws s3 cp "$DUMP_S3_PREFIX/" /work/dumps/ --recursive --only-show-errors; ls -lh /work/dumps; for f in gymcoach_auth.data.dump gymcoach_user.data.dump gymcoach_fitness.data.dump gymcoach_gym.data.dump gymcoach_payment.data.dump gymcoach_chat.data.dump gymcoach_ai.data.dump; do test -s "/work/dumps/$f"; pg_restore -l "/work/dumps/$f" >/dev/null; echo "OK dump: $f"; done; echo "Checking Aurora databases..."; psql "$PSQL_URL" -v ON_ERROR_STOP=1 -Atc "select datname from pg_database where datname in ('fitness_assistant','fitness_assistant_user','fitness_assistant_fitness','fitness_assistant_gym','fitness_assistant_payment','fitness_assistant_chat','fitness_assistant_ai') order by datname;"; echo "=== DB MIGRATOR PREFLIGHT OK ==="
```

![Run task with the preflight command override](/images/workshop/runbook/img358.jpg)

**Expected result** at the end of `/ecs/fitness-assistant-dev-db-migrator`: `=== DB MIGRATOR PREFLIGHT OK ===` — every dump downloads and is readable by `pg_restore -l`, and all 7 databases exist. If the task stops with an error, record the stopped reason and last log lines before going further.

#### Step 8 — Restore

{{% notice warning %}}
**Destructive DEV operation.** This step empties every table (except `_prisma_migrations`) in the 7 Aurora DEV databases and replaces the data with the local dumps. The schema and migration history are not touched. Run it only after the preflight succeeded.
{{% /notice %}}

Same run-task settings, with this command override:

```bash
set -euo pipefail; echo "=== FULL RESTORE START ==="; mkdir -p /work/dumps; aws s3 cp "$DUMP_S3_PREFIX/" /work/dumps/ --recursive --only-show-errors; PSQL_URL="${DATABASE_URL%%\?*}"; BASE="${PSQL_URL%/*}"; restore_db(){ DB="$1"; DUMP="$2"; URL="$BASE/$DB"; echo "=== CLEAN $DB ==="; T=$(psql "$URL" -v ON_ERROR_STOP=1 -Atc "select string_agg(format('%I.%I', schemaname, tablename), ',') from pg_tables where schemaname='public' and tablename <> '_prisma_migrations';"); if [ -n "$T" ]; then psql "$URL" -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE $T RESTART IDENTITY CASCADE;"; fi; echo "=== RESTORE $DB FROM $DUMP ==="; pg_restore --exit-on-error --no-owner --no-privileges --data-only --exclude-table-data=public._prisma_migrations --dbname="$URL" "/work/dumps/$DUMP"; echo "=== DONE $DB ==="; }; restore_db fitness_assistant gymcoach_auth.data.dump; restore_db fitness_assistant_user gymcoach_user.data.dump; restore_db fitness_assistant_fitness gymcoach_fitness.data.dump; restore_db fitness_assistant_gym gymcoach_gym.data.dump; restore_db fitness_assistant_payment gymcoach_payment.data.dump; restore_db fitness_assistant_chat gymcoach_chat.data.dump; restore_db fitness_assistant_ai gymcoach_ai.data.dump; echo "=== FULL RESTORE OK ==="
```

**Expected result:** `=== DONE fitness_assistant_ai ===` followed by `=== FULL RESTORE OK ===`.

#### Step 9 — Handle schema drift with a scripted migrator

The local dumps and the Aurora schemas were not guaranteed to be identical — for example the Gym data could use `brand_id` where the Aurora schema still had `gym_id`, which would make the restore fail or require a deliberate patch. The one-line command was therefore replaced by a script inside the image, selected with a `MODE` variable, and the task definition went through further revisions (up to `fitness-assistant-dev-db-migrator:11`). From PowerShell:

```powershell
$CLUSTER = "fitness-assistant-dev-cluster"
$TASKDEF = "fitness-assistant-dev-db-migrator:11"
$REGION  = "ap-southeast-1"
$NET = "awsvpcConfiguration={subnets=[<private-app-a-id>,<private-app-b-id>],securityGroups=[<chat-sg-id>],assignPublicIp=DISABLED}"

aws ecs run-task `
  --cluster $CLUSTER `
  --task-definition $TASKDEF `
  --launch-type FARGATE `
  --network-configuration $NET `
  --region $REGION `
  --overrides '{\"containerOverrides\":[{\"name\":\"db-migrator\",\"environment\":[{\"name\":\"MODE\",\"value\":\"apply-prepatch\"}]}]}'
```

1. `MODE=apply-prepatch` applies the schema pre-patches; the log must show `schema-prepatch applied` and the task must stop with exit code 0.
2. Review the generated `db-migrator-output/generated/needs-review.fitness_assistant_gym.sql` in the migration bucket and decide the `gym_id → brand_id` case deliberately.
3. Run `MODE=restore`.

#### Result

According to the deployment status table, all **7 of 7** service databases were restored and **23 of 23** audited foreign keys were applied and validated. Uploaded user files (`user-files/`) and re-embedding the local Qdrant data into OpenSearch are separate follow-ups, done only after the relational data was verified.
