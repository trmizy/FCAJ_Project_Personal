---
title: "5.5.1 Schema migrations"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.5.1. </b> "
---

#### What is checked

Every service owns one logical database on the shared Aurora cluster, created and migrated by its own migration Lambda. A migration run passes only if the response contains all of:

- `"status": "ok"` and the expected `database` name (the handler refuses any other name);
- `"migrateExitCode": 0`;
- `All migrations have been successfully applied.` in the Prisma output.

#### Results

| Service | Logical database | Migrations | Evidence |
|---|---|---|---|
| Auth | `fitness_assistant` | 7 | Test result below; the temporary migration Lambda was deleted afterwards |
| User | `fitness_assistant_user` | applied | Migration Lambda `fitness-assistant-dev-user-migrate` ([5.4.4](../../5.4-Deployment-Guide/5.4.4-User-Service/)) |
| Fitness | `fitness_assistant_fitness` | 48 | Run from the S3 artifact, then the migration Lambda was deleted ([5.4.5](../../5.4-Deployment-Guide/5.4.5-Fitness-Service/)) |
| Gym | `fitness_assistant_gym` | 9 | `fitness-assistant-dev-gym-migrate` (visible in the function list in [5.4.10](../../5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)) |
| Payment | `fitness_assistant_payment` | 11 | Test result below |
| AI | `fitness_assistant_ai` | 22 (no `DROP` / `TRUNCATE`) | Test result below |
| Chat | `fitness_assistant_chat` | 3 | Test result below |

**Auth**

![Auth migration result](/images/workshop/runbook/img001.jpg)

![Auth: migrations applied successfully](/images/workshop/runbook/img002.jpg)

**Payment**

![Payment migration: status ok, fitness_assistant_payment, migrations applied](/images/workshop/runbook/img132.jpg)

**AI**

![AI migration: databaseCreated true, migrateExitCode 0](/images/workshop/runbook/img158.jpg)

**Chat**

![Chat migration: database created, 3 migrations applied](/images/workshop/runbook/img262.jpg)

#### Data restore

The data of the 7 local databases was restored with the one-shot Fargate task in [5.4.11](../../5.4-Deployment-Guide/5.4.11-Data-Migration/). Passing criteria and recorded result:

| Check | Expected | Result |
|---|---|---|
| Preflight log | `=== DB MIGRATOR PREFLIGHT OK ===`, every dump readable, all 7 databases present | Passed before the restore was run |
| Restore log | `=== DONE fitness_assistant_ai ===` then `=== FULL RESTORE OK ===` | 7 of 7 databases restored |
| Referential integrity | Every audited foreign key applied and valid | 23 of 23 foreign keys validated |
| Row counts / primary keys | Same counts as the local source per table | Part of the restore verification; repeat after any re-run |

{{% notice tip %}}
A quick way to re-check one database after a restore, from any container or Lambda that can reach Aurora: `select count(*) from <table>;` for the largest tables, compared with the same query on the local database the dump came from.
{{% /notice %}}
