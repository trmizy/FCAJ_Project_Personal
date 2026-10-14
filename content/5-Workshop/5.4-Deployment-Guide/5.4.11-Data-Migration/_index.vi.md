---
title: "5.4.11 Migration dữ liệu lên Aurora"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 5.4.11. </b> "
---

Schema trên Aurora đã được tạo bởi migration Lambda của từng service. Bước cuối cùng này chuyển **dữ liệu** của 7 database PostgreSQL local vào đó — giữ nguyên ID gốc, không seed lại — bằng một ECS Fargate task chạy một lần, thực thi `pg_restore` bên trong VPC.

Thứ tự được chốt trước để không có gì bị hỏng giữa chừng:

1. Upload 7 dump và manifest lên một S3 bucket private.
2. Đảm bảo đủ 7 logical database trên Aurora (bao gồm `fitness_assistant_chat`).
3. Áp dụng schema migration mới nhất cho cả 7.
4. Build và push image migrator lên ECR.
5. Chạy một task preflight chỉ đọc.
6. Restore từng database.
7. So sánh row count / primary key.
8. Sau đó mới xử lý file người dùng đã upload và dữ liệu vector.

#### Bước 1 — Bucket migration private

S3 → *Create bucket* `fitness-assistant-data-migration-dev-<account-id>` ở `ap-southeast-1`: **bật Block all public access**, **bật versioning**, mã hoá SSE-S3, không bật static website. Một bucket riêng giữ dump tách biệt khỏi bucket frontend công khai và bucket upload của người dùng.

![Đã tạo bucket fitness-assistant-data-migration-dev](/images/workshop/runbook/img336.jpg)

Tạo các prefix `full-local-migration/2026-09/dumps/`, `manifests/` và `user-files/`.

![Create folder](/images/workshop/runbook/img337.jpg)

![full-local-migration/](/images/workshop/runbook/img338.jpg)

![2026-09/ với dumps/, manifests/ và user-files/](/images/workshop/runbook/img339.jpg)

#### Bước 2 — Upload dump và manifest

Upload nguyên vẹn 7 dump đã audit (không giải nén, không chuyển sang SQL): `gymcoach_auth`, `_user`, `_fitness`, `_gym`, `_payment`, `_chat` và `_ai` `.data.dump` — tổng 72.9 MB — rồi upload `manifest.json` SHA-256 vào `manifests/`.

![Upload 7 dump (72.9 MB) vào dumps/](/images/workshop/runbook/img340.jpg)

![Upload thành công: 7 file](/images/workshop/runbook/img342.jpg)

![Upload manifest.json vào manifests/](/images/workshop/runbook/img343.jpg)

{{% notice warning %}}
Không bao giờ upload `.env`, `.env.production`, mật khẩu database, `JWT_SECRET`, `INTERNAL_SERVICE_SECRET`, AWS credential hay API key của provider vào bucket này.
{{% /notice %}}

#### Bước 3 — Image migrator

Một image tối giản chỉ có `pg_restore` và AWS CLI, dùng được cho cả 7 database (và sau này cho CI/CD). Tạo ECR repository `fitness-assistant-dev-db-migrator` (private, mutable, AES-256).

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

![Push fitness-assistant-dev-db-migrator:dev-20260923-1](/images/workshop/runbook/img345.jpg)

#### Bước 4 — Role

**Execution role** `fitness-assistant-dev-db-migrator-execution-role` (ECS task, `AmazonECSTaskExecutionRolePolicy`) — pull image và ghi log.

![AmazonECSTaskExecutionRolePolicy](/images/workshop/runbook/img346.jpg)

![Role fitness-assistant-dev-db-migrator-execution-role, trust ecs-tasks](/images/workshop/runbook/img347.jpg)

**Task role** `fitness-assistant-dev-db-migrator-task-role` với inline policy `fitness-assistant-dev-db-migrator-runtime` — chỉ đọc prefix dumps, và đọc credential Aurora:

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

![Policy fitness-assistant-dev-db-migrator-runtime: S3 và Secrets Manager](/images/workshop/runbook/img349.jpg)

![Task role fitness-assistant-dev-db-migrator-task-role](/images/workshop/runbook/img350.jpg)

#### Bước 5 — Task definition

ECS → *Create new task definition* `fitness-assistant-dev-db-migrator`: Fargate, Linux/X86_64, `awsvpc`, **1 vCPU / 2 GB**, hai role ở trên, container `db-migrator` với image `…/fitness-assistant-dev-db-migrator:dev-20260923-1`, không cần port mapping, environment `AWS_REGION=ap-southeast-1`, `DB_SECRET_ID=fitness-assistant/dev/chat-database`, `DUMP_S3_PREFIX=s3://fitness-assistant-data-migration-dev-<account-id>/full-local-migration/2026-09/dumps`, log vào `/ecs/fitness-assistant-dev-db-migrator`, ephemeral storage mặc định (dư thừa nhiều so với 73 MB dump). Không đặt command — sẽ được override khi chạy.

![Family fitness-assistant-dev-db-migrator: Fargate, 1 vCPU, 2 GB](/images/workshop/runbook/img351.jpg)

![Task role và execution role, container db-migrator và image](/images/workshop/runbook/img352.jpg)

![Thiết lập container](/images/workshop/runbook/img353.jpg)

![Environment variable và log collection](/images/workshop/runbook/img354.jpg)

![Ephemeral storage, rồi Create](/images/workshop/runbook/img355.jpg)

#### Bước 6 — Inject database URL dưới dạng secret (revision 2)

Cấp cho execution role quyền `secretsmanager:GetSecretValue` trên secret `chat-database-url` (inline policy `fitness-assistant-dev-db-migrator-secret`), rồi tạo **revision 2** với secret environment variable `DATABASE_URL`, value type *ValueFrom*, giá trị `<ARN secret chat-database-url>:CHAT_DATABASE_URL::`. Không cần `DB_SECRET_ID` nữa.

![Policy của execution role cho secret database URL](/images/workshop/runbook/img356.jpg)

![Task definition fitness-assistant-dev-db-migrator:2 đang active](/images/workshop/runbook/img357.jpg)

Script tách server URL từ `DATABASE_URL` và đổi tên database cho mỗi lần restore, nên một credential dùng được cho cả 7 logical database trên cùng cluster.

#### Bước 7 — Preflight (chỉ đọc)

ECS → `fitness-assistant-dev-cluster` → *Tasks → Run new task*: FARGATE, `fitness-assistant-dev-db-migrator:2`, 1 task, private app subnet, security group `fitness-assistant-dev-chat-sg` (đã được phép vào Aurora ở 5432 và vào Secrets Manager endpoint), tắt public IP, không có load balancer. Command override cho `db-migrator`:

```bash
set -euo pipefail; echo "=== DB MIGRATOR PREFLIGHT START ==="; echo "Region=$AWS_REGION"; echo "Prefix=$DUMP_S3_PREFIX"; test -n "${DATABASE_URL:-}"; PSQL_URL="${DATABASE_URL%%\?*}"; mkdir -p /work/dumps; aws s3 ls "$DUMP_S3_PREFIX/"; aws s3 cp "$DUMP_S3_PREFIX/" /work/dumps/ --recursive --only-show-errors; ls -lh /work/dumps; for f in gymcoach_auth.data.dump gymcoach_user.data.dump gymcoach_fitness.data.dump gymcoach_gym.data.dump gymcoach_payment.data.dump gymcoach_chat.data.dump gymcoach_ai.data.dump; do test -s "/work/dumps/$f"; pg_restore -l "/work/dumps/$f" >/dev/null; echo "OK dump: $f"; done; echo "Checking Aurora databases..."; psql "$PSQL_URL" -v ON_ERROR_STOP=1 -Atc "select datname from pg_database where datname in ('fitness_assistant','fitness_assistant_user','fitness_assistant_fitness','fitness_assistant_gym','fitness_assistant_payment','fitness_assistant_chat','fitness_assistant_ai') order by datname;"; echo "=== DB MIGRATOR PREFLIGHT OK ==="
```

![Run task với command override cho preflight](/images/workshop/runbook/img358.jpg)

**Kết quả mong đợi** ở cuối `/ecs/fitness-assistant-dev-db-migrator`: `=== DB MIGRATOR PREFLIGHT OK ===` — mọi dump tải về được và `pg_restore -l` đọc được, và đủ 7 database tồn tại. Nếu task dừng với lỗi, ghi lại stopped reason và các dòng log cuối trước khi đi tiếp.

#### Bước 8 — Restore

{{% notice warning %}}
**Thao tác phá huỷ trên DEV.** Bước này làm trống mọi bảng (trừ `_prisma_migrations`) trong 7 database DEV trên Aurora và thay dữ liệu bằng dump local. Schema và lịch sử migration không bị đụng tới. Chỉ chạy sau khi preflight thành công.
{{% /notice %}}

Cùng thiết lập run task, với command override:

```bash
set -euo pipefail; echo "=== FULL RESTORE START ==="; mkdir -p /work/dumps; aws s3 cp "$DUMP_S3_PREFIX/" /work/dumps/ --recursive --only-show-errors; PSQL_URL="${DATABASE_URL%%\?*}"; BASE="${PSQL_URL%/*}"; restore_db(){ DB="$1"; DUMP="$2"; URL="$BASE/$DB"; echo "=== CLEAN $DB ==="; T=$(psql "$URL" -v ON_ERROR_STOP=1 -Atc "select string_agg(format('%I.%I', schemaname, tablename), ',') from pg_tables where schemaname='public' and tablename <> '_prisma_migrations';"); if [ -n "$T" ]; then psql "$URL" -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE $T RESTART IDENTITY CASCADE;"; fi; echo "=== RESTORE $DB FROM $DUMP ==="; pg_restore --exit-on-error --no-owner --no-privileges --data-only --exclude-table-data=public._prisma_migrations --dbname="$URL" "/work/dumps/$DUMP"; echo "=== DONE $DB ==="; }; restore_db fitness_assistant gymcoach_auth.data.dump; restore_db fitness_assistant_user gymcoach_user.data.dump; restore_db fitness_assistant_fitness gymcoach_fitness.data.dump; restore_db fitness_assistant_gym gymcoach_gym.data.dump; restore_db fitness_assistant_payment gymcoach_payment.data.dump; restore_db fitness_assistant_chat gymcoach_chat.data.dump; restore_db fitness_assistant_ai gymcoach_ai.data.dump; echo "=== FULL RESTORE OK ==="
```

**Kết quả mong đợi:** `=== DONE fitness_assistant_ai ===` rồi `=== FULL RESTORE OK ===`.

#### Bước 9 — Xử lý lệch schema bằng migrator có script

Dump local và schema trên Aurora không chắc chắn giống hệt nhau — ví dụ dữ liệu Gym có thể dùng `brand_id` trong khi schema Aurora vẫn còn `gym_id`, khiến restore lỗi hoặc cần một bản patch có chủ đích. Vì vậy lệnh một dòng được thay bằng script bên trong image, chọn chế độ qua biến `MODE`, và task definition được nâng qua nhiều revision (tới `fitness-assistant-dev-db-migrator:11`). Từ PowerShell:

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

1. `MODE=apply-prepatch` áp dụng các pre-patch cho schema; log phải có `schema-prepatch applied` và task dừng với exit code 0.
2. Xem file `db-migrator-output/generated/needs-review.fitness_assistant_gym.sql` được tạo trong bucket migration và quyết định có chủ đích cho trường hợp `gym_id → brand_id`.
3. Chạy `MODE=restore`.

#### Kết quả

Theo bảng trạng thái triển khai, **7 trên 7** database của các service đã được restore và **23 trên 23** foreign key đã audit được áp dụng và xác nhận. File người dùng đã upload (`user-files/`) và việc tạo lại embedding cho dữ liệu Qdrant local vào OpenSearch là các việc tiếp theo riêng, chỉ làm sau khi dữ liệu quan hệ đã được xác nhận.
