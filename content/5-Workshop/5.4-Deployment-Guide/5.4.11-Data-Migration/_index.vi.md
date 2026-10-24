---
title: "Migration dữ liệu lên Aurora"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 5.4.11. </b> "
---

Schema trên Aurora đã được tạo bởi migration Lambda của từng service. Bước cuối cùng này chuyển **dữ liệu** của 7 database PostgreSQL local vào đó — giữ nguyên ID gốc, không seed lại — bằng một ECS Fargate task chạy một lần, thực thi `pg_restore` bên trong VPC.

Trong mọi ảnh bên dưới, các **khung đỏ** đánh dấu ô cần nhập hoặc nút cần bấm của bước nhỏ được viết ngay phía trên ảnh.

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

**1.1 — Tạo bucket.** S3 → *Create bucket* `fitness-assistant-data-migration-dev-<account-id>` ở `ap-southeast-1`: **bật Block all public access**, **bật versioning**, mã hoá SSE-S3, không bật static website. Một bucket riêng giữ dump tách biệt khỏi bucket frontend công khai và bucket upload của người dùng. Banner xác nhận đã tạo.

![Banner "Successfully created bucket" và tên bucket](/images/workshop/runbook/img336.jpg)

**1.2 — Tạo folder đầu tiên.** Bấm **Create folder**, nhập tên `full-local-migration` rồi bấm **Create folder** lần nữa. Sau đó lặp lại cho `2026-09` bên trong, và `dumps`, `manifests`, `user-files` bên trong `2026-09`. Ảnh cho thấy form (ô tên folder và nút Create folder).

![Ô tên folder và nút Create folder](/images/workshop/runbook/img337.jpg)

**1.3 — Mở `full-local-migration/`.** Folder còn trống; bấm **Create folder** để thêm `2026-09`.

![full-local-migration/ và nút Create folder](/images/workshop/runbook/img338.jpg)

**1.4 — Kiểm tra kết quả.** `2026-09/` chứa ba folder `dumps/`, `manifests/` và `user-files/`.

![2026-09/ với dumps/, manifests/ và user-files/](/images/workshop/runbook/img339.jpg)

#### Bước 2 — Upload dump và manifest

**2.1 — Thêm 7 dump.** Mở `dumps/`, bấm **Upload → Add files** và chọn nguyên vẹn 7 dump đã audit (không giải nén, không chuyển sang SQL): `gymcoach_auth`, `_user`, `_fitness`, `_gym`, `_payment`, `_chat` và `_ai` `.data.dump` — tổng 72.9 MB. Destination phải là `…/full-local-migration/2026-09/dumps/`.

![Add files, 7 file (72.9 MB) và đường dẫn destination](/images/workshop/runbook/img340.jpg)

**2.2 — Bắt đầu upload và kiểm tra.** Bấm **Upload** ở cuối trang. Trang trạng thái phải báo **Upload succeeded** với 7 file và 0 lỗi. Bấm **Close**.

![Upload succeeded: 7 file, 72.9 MB, Close](/images/workshop/runbook/img342.jpg)

**2.3 — Upload manifest.** Mở `manifests/`, bấm **Upload → Add files**, chọn `manifest.json` SHA-256 và bấm **Upload**.

![manifest.json (10.1 KB), destination manifests/ và nút Upload](/images/workshop/runbook/img343.jpg)

{{% notice warning %}}
Không bao giờ upload `.env`, `.env.production`, mật khẩu database, `JWT_SECRET`, `INTERNAL_SERVICE_SECRET`, AWS credential hay API key của provider vào bucket này.
{{% /notice %}}

#### Bước 3 — Image migrator

Một image tối giản chỉ có `pg_restore` và AWS CLI, dùng được cho cả 7 database (và sau này cho CI/CD).

**3.1 — Tạo ECR repository.** ECR → *Create repository*: private, tên `fitness-assistant-dev-db-migrator`, tag mutability **Mutable**, AES-256, rồi **Create**. (Công tắc scan-on-push đã deprecated được bật sẵn trong console này.)

![Tên repository, Mutable và nút Create](/images/workshop/runbook/img344.jpg)

**3.2 — Viết Dockerfile.** `tools/db-migrator/Dockerfile`:

```dockerfile
FROM postgres:16-bookworm
RUN apt-get update \
    && apt-get install -y --no-install-recommends awscli ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'db-migrator ready'"]
```

**3.3 — Build, test, đăng nhập, tag và push.** Từ PowerShell trong `tools/db-migrator`:

```powershell
docker build -t fitness-assistant-db-migrator:dev .
docker run --rm fitness-assistant-db-migrator:dev "pg_restore --version && aws --version"   # pg_restore 16.15, aws-cli 2.9.19
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
docker tag fitness-assistant-db-migrator:dev <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-db-migrator:dev-20260923-1
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-db-migrator:dev-20260923-1
```

Ảnh chỉ cho thấy lần push cuối: mọi layer `Pushed` và dòng digest.

![Lệnh docker push và dòng digest cuối](/images/workshop/runbook/img345.jpg)

#### Bước 4 — Role

**4.1 — Execution role, policy.** **IAM → Roles → Create role → AWS service → Elastic Container Service Task**, rồi tìm `AmazonECSTaskExecutionRolePolicy`, tick và bấm **Next** — role này kéo image và ghi log.

![Tìm AmazonECSTaskExecutionRolePolicy, dòng đã tick và Next](/images/workshop/runbook/img346.jpg)

**4.2 — Execution role, tên.** `fitness-assistant-dev-db-migrator-execution-role` (trusted bởi `ecs-tasks.amazonaws.com`), rồi **Create role**.

![Tên role và Create role](/images/workshop/runbook/img347.jpg)

**4.3 — Task role.** Tạo `fitness-assistant-dev-db-migrator-task-role` tương tự (cùng trusted entity, không managed policy — banner ở đầu form của nó là xác nhận execution role trước đó), rồi thêm inline policy `fitness-assistant-dev-db-migrator-runtime` — chỉ đọc prefix dumps và đọc credential Aurora:

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

![Tên task role và nút Create role](/images/workshop/runbook/img350.jpg)

**4.4 — Dán policy.** Trong policy editor (JSON) dán policy ở trên và bấm **Next**.

![JSON runtime policy và Next](/images/workshop/runbook/img348.jpg)

**4.5 — Đặt tên và tạo.** `fitness-assistant-dev-db-migrator-runtime`, **Create policy**; phần tóm tắt liệt kê S3 và Secrets Manager.

![Tên policy fitness-assistant-dev-db-migrator-runtime và Create policy](/images/workshop/runbook/img349.jpg)

#### Bước 5 — Task definition

ECS → *Create new task definition* `fitness-assistant-dev-db-migrator`: Fargate, Linux/X86_64, `awsvpc`, **1 vCPU / 2 GB**, hai role, container `db-migrator` với image `…/fitness-assistant-dev-db-migrator:dev-20260923-1`, không cần port mapping, environment `AWS_REGION=ap-southeast-1`, `DB_SECRET_ID=fitness-assistant/dev/chat-database`, `DUMP_S3_PREFIX=s3://fitness-assistant-data-migration-dev-<account-id>/full-local-migration/2026-09/dumps`, log vào `/ecs/fitness-assistant-dev-db-migrator`, ephemeral storage mặc định (dư thừa so với 73 MB dump). Không đặt command — nó được ghi đè lúc chạy.

**5.1 — Family, launch type và kích thước.** Family `fitness-assistant-dev-db-migrator`, **AWS Fargate**, Linux/X86_64, CPU **1 vCPU**, memory **2 GB**.

![Family, Fargate, 1 vCPU và 2 GB](/images/workshop/runbook/img351.jpg)

**5.2 — Role và container.** Task role `fitness-assistant-dev-db-migrator-task-role`, task execution role `fitness-assistant-dev-db-migrator-execution-role`, tên container `db-migrator`, image URI `<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/fitness-assistant-dev-db-migrator:dev-20260923-1`.

![Task role, execution role, tên container và image URI](/images/workshop/runbook/img352.jpg)

**5.3 — Port mapping.** Console điền sẵn container port 80; runbook không cần port, nên xoá mapping đó (**Remove**) — ảnh cho thấy giá trị mặc định chưa đụng tới.

![Port mapping mặc định 80 (cần xoá)](/images/workshop/runbook/img353.jpg)

**5.4 — Environment variable và logging.** Thêm `AWS_REGION`, `DB_SECRET_ID` và `DUMP_S3_PREFIX` với các giá trị ở trên và giữ tick **Use log collection**.

![Ba environment variable và Use log collection](/images/workshop/runbook/img354.jpg)

**5.5 — Storage và tạo.** Giữ ephemeral storage mặc định (console hiện 21) và bấm **Create**.

![Số lượng ephemeral storage và Create](/images/workshop/runbook/img355.jpg)

#### Bước 6 — Inject database URL như một secret (revision 2)

**6.1 — Mở rộng execution role.** Cho execution role quyền `secretsmanager:GetSecretValue` trên secret `chat-database-url`: **Add permissions → Create inline policy → JSON** với statement `ReadDatabaseUrl`, đặt tên `fitness-assistant-dev-db-migrator-secret`.

![JSON editor: statement ReadDatabaseUrl](/images/workshop/runbook/img356.jpg)

**6.2 — Tạo revision 2.** Từ task definition chọn **Create new revision** và thêm secret environment variable `DATABASE_URL`, value type *ValueFrom*, giá trị `<ARN secret chat-database-url>:CHAT_DATABASE_URL::`; xoá `DB_SECRET_ID` vì không còn cần. Màn hình xác nhận hiện `fitness-assistant-dev-db-migrator:2` ở trạng thái ACTIVE cùng hai role.

![Task definition fitness-assistant-dev-db-migrator:2 đã tạo và active](/images/workshop/runbook/img357.jpg)

Script suy ra URL server từ `DATABASE_URL` và đổi tên database theo từng lần restore, nên một credential phục vụ cả 7 logical database trên cùng cluster.

#### Bước 7 — Preflight (chỉ đọc)

**7.1 — Run new task.** ECS → `fitness-assistant-dev-cluster` → *Tasks → Run new task*: FARGATE, `fitness-assistant-dev-db-migrator:2`, 1 task, private app subnet, security group `fitness-assistant-dev-chat-sg` (đã được phép vào Aurora ở 5432 và vào Secrets Manager endpoint), tắt public IP, không load balancer.

*Runbook không có ảnh của phần networking trong form này.*

**7.2 — Ghi đè command.** Trong **Container overrides → db-migrator** dán vào **Command override**:

```bash
set -euo pipefail; echo "=== DB MIGRATOR PREFLIGHT START ==="; echo "Region=$AWS_REGION"; echo "Prefix=$DUMP_S3_PREFIX"; test -n "${DATABASE_URL:-}"; PSQL_URL="${DATABASE_URL%%\?*}"; mkdir -p /work/dumps; aws s3 ls "$DUMP_S3_PREFIX/"; aws s3 cp "$DUMP_S3_PREFIX/" /work/dumps/ --recursive --only-show-errors; ls -lh /work/dumps; for f in gymcoach_auth.data.dump gymcoach_user.data.dump gymcoach_fitness.data.dump gymcoach_gym.data.dump gymcoach_payment.data.dump gymcoach_chat.data.dump gymcoach_ai.data.dump; do test -s "/work/dumps/$f"; pg_restore -l "/work/dumps/$f" >/dev/null; echo "OK dump: $f"; done; echo "Checking Aurora databases..."; psql "$PSQL_URL" -v ON_ERROR_STOP=1 -Atc "select datname from pg_database where datname in ('fitness_assistant','fitness_assistant_user','fitness_assistant_fitness','fitness_assistant_gym','fitness_assistant_payment','fitness_assistant_chat','fitness_assistant_ai') order by datname;"; echo "=== DB MIGRATOR PREFLIGHT OK ==="
```

Các environment override bên dưới giữ ba biến (các dòng `AWS_REGION`, `DB_SECRET_ID` và `DUMP_S3_PREFIX` trong ảnh). Bấm **Create** để chạy task.

![Ô Command override và giá trị environment override](/images/workshop/runbook/img358.jpg)

**7.3 — Đọc log.** **Kết quả mong đợi** ở cuối `/ecs/fitness-assistant-dev-db-migrator`: `=== DB MIGRATOR PREFLIGHT OK ===` — mọi dump tải xuống được và `pg_restore -l` đọc được, và cả 7 database tồn tại. Nếu task dừng với lỗi, hãy ghi lại stopped reason và các dòng log cuối trước khi đi tiếp.

*Runbook không có ảnh của output log.*

#### Bước 8 — Restore

{{% notice warning %}}
**Thao tác phá huỷ trên DEV.** Bước này làm rỗng mọi bảng (trừ `_prisma_migrations`) trong 7 database Aurora DEV và thay dữ liệu bằng dump local. Schema và lịch sử migration không bị đụng tới. Chỉ chạy sau khi preflight thành công.
{{% /notice %}}

**8.1 — Chạy lại task.** Cùng cài đặt run-task, với command override này:

```bash
set -euo pipefail; echo "=== FULL RESTORE START ==="; mkdir -p /work/dumps; aws s3 cp "$DUMP_S3_PREFIX/" /work/dumps/ --recursive --only-show-errors; PSQL_URL="${DATABASE_URL%%\?*}"; BASE="${PSQL_URL%/*}"; restore_db(){ DB="$1"; DUMP="$2"; URL="$BASE/$DB"; echo "=== CLEAN $DB ==="; T=$(psql "$URL" -v ON_ERROR_STOP=1 -Atc "select string_agg(format('%I.%I', schemaname, tablename), ',') from pg_tables where schemaname='public' and tablename <> '_prisma_migrations';"); if [ -n "$T" ]; then psql "$URL" -v ON_ERROR_STOP=1 -c "TRUNCATE TABLE $T RESTART IDENTITY CASCADE;"; fi; echo "=== RESTORE $DB FROM $DUMP ==="; pg_restore --exit-on-error --no-owner --no-privileges --data-only --exclude-table-data=public._prisma_migrations --dbname="$URL" "/work/dumps/$DUMP"; echo "=== DONE $DB ==="; }; restore_db fitness_assistant gymcoach_auth.data.dump; restore_db fitness_assistant_user gymcoach_user.data.dump; restore_db fitness_assistant_fitness gymcoach_fitness.data.dump; restore_db fitness_assistant_gym gymcoach_gym.data.dump; restore_db fitness_assistant_payment gymcoach_payment.data.dump; restore_db fitness_assistant_chat gymcoach_chat.data.dump; restore_db fitness_assistant_ai gymcoach_ai.data.dump; echo "=== FULL RESTORE OK ==="
```

**Kết quả mong đợi:** `=== DONE fitness_assistant_ai ===` rồi `=== FULL RESTORE OK ===`.

*Runbook không có ảnh của Bước 8.*

#### Bước 9 — Xử lý schema drift bằng migrator dạng script

Dump local và schema Aurora không được đảm bảo giống hệt nhau — ví dụ dữ liệu Gym có thể dùng `brand_id` trong khi schema Aurora vẫn là `gym_id`, khiến restore lỗi hoặc cần một bản vá có chủ đích. Vì vậy command một dòng được thay bằng một script bên trong image, chọn bằng biến `MODE`, và task definition trải qua thêm nhiều revision (tới `fitness-assistant-dev-db-migrator:11`). Từ PowerShell:

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

1. `MODE=apply-prepatch` áp dụng các bản vá schema; log phải hiện `schema-prepatch applied` và task phải dừng với exit code 0.
2. Xem lại file `db-migrator-output/generated/needs-review.fitness_assistant_gym.sql` được sinh ra trong migration bucket và quyết định trường hợp `gym_id → brand_id` một cách có chủ đích.
3. Chạy `MODE=restore`.

*Runbook không có ảnh của Bước 9.*

#### Kết quả

Theo bảng trạng thái triển khai, cả **7 trên 7** database service đã được restore và **23 trên 23** foreign key đã audit được áp dụng và validate. File người dùng đã upload (`user-files/`) và việc embed lại dữ liệu Qdrant local vào OpenSearch là các việc tiếp theo riêng, chỉ làm sau khi dữ liệu quan hệ đã được kiểm chứng.
