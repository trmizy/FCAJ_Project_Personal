---
title: "Week 6"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 1.6. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Provision Amazon RDS for PostgreSQL to replace the containerized `postgres:15-alpine` used in local development.
- Run Prisma migrations against RDS for each service that owns a database.
- Verify connectivity from the application tier only (private access).

### Tasks Performed

- Created a DB subnet group across the two private subnets from Week 5.
- Launched an Amazon RDS PostgreSQL instance with **public access disabled**, encryption at rest enabled, and automated backups configured.
- Attached the RDS Security Group so that inbound port 5432 is only allowed from the EC2 application Security Group, matching the real database-per-service design used by `fitness-assistant` (each service — auth, user, fitness, ai, chat — has its own logical database and its own Prisma schema/migrations).
- Ran `prisma migrate deploy` for each service against the new RDS endpoint, using the project's own Prisma schemas (no hand-written SQL DDL).
- Ran the project's seed scripts where available, to load baseline data.
- Verified connectivity from an EC2 instance in the same VPC (not from a personal machine over the public internet, since RDS is private).

### Results Achieved

- Migrations applied for the services included in MVP scope.
- TODO: Confirm final list of databases created (`gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, and any others in MVP scope) and record evidence.

### Difficulties

- The `user-service` production Dockerfile does not automatically run `prisma migrate deploy` on startup (unlike `auth-service` and `ai-service`), so migrations for that service need to be triggered explicitly rather than assumed to run automatically.

### How It Was Resolved

- Documented this inconsistency explicitly in [Workshop 5.7](../../5-Workshop/5.7-RDS-PostgreSQL/) and ran `user-service` migrations as a manual/explicit step rather than assuming the container handles it.

### AWS Skills / Services Learned

- Amazon RDS provisioning, DB subnet groups, automated backups, encryption at rest.
- Running Prisma migrations against a managed database instead of a local container.

### Evidence Still Required

- TODO: Screenshot of the RDS instance configuration (with credentials redacted).
- TODO: Terminal output of `prisma migrate deploy` succeeding per service.
- TODO: Screenshot/log of a successful connectivity test from EC2.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Create DB subnet group and RDS instance | [TODO_DATE] | [TODO_DATE] | [Workshop 5.7](../../5-Workshop/5.7-RDS-PostgreSQL/) |
| 2 | Configure Security Group for private-only access | [TODO_DATE] | [TODO_DATE] | [Workshop 5.6](../../5-Workshop/5.6-Network-Infrastructure/) |
| 3 | Run Prisma migrations per service | [TODO_DATE] | [TODO_DATE] | `prisma/schema.prisma` per service |
| 4 | Verify connectivity and seed data | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] RDS PostgreSQL instance created (private access only)
- [ ] DB subnet group and Security Group configured
- [ ] Prisma migrations applied per service
- [ ] Connectivity verified from EC2, not from the public internet

### Related Workshop Section

- [5.7 RDS PostgreSQL](../../5-Workshop/5.7-RDS-PostgreSQL/)
