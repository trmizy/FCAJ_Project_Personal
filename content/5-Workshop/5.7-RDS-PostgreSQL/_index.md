---
title: "5.7 RDS PostgreSQL"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.7. </b> "
---

### Why RDS Replaces the postgres Container

infra/compose/docker-compose.dev.yml runs a single postgres:15-alpine container for local development, with each backend service (auth-service, user-service, fitness-service, ai-service, chat-service, gym-service, payment-service) pointing its own DATABASE_URL at a different logical database on that same instance (database-per-service). Amazon RDS for PostgreSQL reproduces this exact layout on a managed, backed-up instance instead of a disposable local container.

### Create the DB Subnet Group

Use the two private subnets from [5.6 Network Infrastructure](../5.6-Network-Infrastructure/).

```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name fitness-assistant-db-subnet-group \
  --db-subnet-group-description "Private subnets for Fitness Assistant RDS" \
  --subnet-ids subnet-xxxxxxxx subnet-yyyyyyyy
```

### Create the RDS Instance (Private Access Only)

```bash
aws rds create-db-instance \
  --db-instance-identifier fitness-assistant-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15 \
  --master-username [TODO_DATABASE_USER] \
  --master-user-password "USE_SECRETS_MANAGER_DO_NOT_PASTE_A_REAL_PASSWORD" \
  --allocated-storage 20 \
  --db-subnet-group-name fitness-assistant-db-subnet-group \
  --vpc-security-group-ids sg-xxxxxxxx \
  --no-publicly-accessible \
  --backup-retention-period 7 \
  --storage-encrypted
```

Key settings, matching the [Proposal](../../2-Proposal/#16-security): public access disabled, encryption at rest enabled, and an explicit backup retention period.

### Security Group

Attach the RDS Security Group so that port 5432 only accepts traffic from the EC2 application Security Group, per [5.6 Network Infrastructure](../5.6-Network-Infrastructure/).

### Credentials

Never hard-code the master password. Store it in AWS Secrets Manager (see [5.11 IAM and Secrets](../5.11-IAM-Secrets/)) and reference it as [TODO_RDS_ENDPOINT], [TODO_DATABASE_NAME], [TODO_DATABASE_USER] in any shared documentation.

### Create the Per-Service Databases

Each backend service expects its own logical database on the instance, matching local development:

```sql
CREATE DATABASE gymcoach_auth;
CREATE DATABASE gymcoach_user;
CREATE DATABASE gymcoach_fitness;
CREATE DATABASE gymcoach_ai;
-- Only create databases for services included in MVP scope.
```

### Run Prisma Migrations

Each MVP service already has its own prisma/schema.prisma and prisma/migrations/ folder -- use the project's own migration tooling, not hand-written SQL DDL:

```bash
DATABASE_URL="postgresql://TODO_DATABASE_USER:PASSWORD@TODO_RDS_ENDPOINT:5432/gymcoach_auth" \
  pnpm --filter @gym-coach/auth-service exec prisma migrate deploy
```

{{% notice warning %}}
user-service's production Dockerfile does not run prisma migrate deploy automatically on container start, unlike auth-service and ai-service. Run its migration explicitly as a separate step; do not assume it happens automatically just because the container is running.
{{% /notice %}}

### Seed Data

If the project's seed scripts are used (pnpm db:seed or the db-seeder service defined in docker-compose.dev.yml), point them at the RDS endpoint the same way. TODO: confirm which seed scripts are appropriate to run against a shared/demo RDS instance versus local-only.

### Verify Connectivity

Connect only from an EC2 instance inside the same VPC, never from a personal machine over the public internet (RDS has public access disabled):

```bash
psql "host=TODO_RDS_ENDPOINT port=5432 dbname=gymcoach_auth user=TODO_DATABASE_USER"
```

### Troubleshooting

See the RDS-specific rows in [5.15 Troubleshooting](../5.15-Troubleshooting/) (connection timeout, password authentication failed, Prisma migration errors).

### Expected Result

- RDS instance shows available status with public access disabled.
- Each MVP service's Prisma migrations apply cleanly against its own database.
- Application containers on EC2 can connect; a personal machine outside the VPC cannot.
