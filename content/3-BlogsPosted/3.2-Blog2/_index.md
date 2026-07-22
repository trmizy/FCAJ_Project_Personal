---
title: "Blog 2: Migrating PostgreSQL to Amazon RDS"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 3.2. </b> "
---

## Migrating PostgreSQL from Docker to Amazon RDS

**Status:** Draft

**Publish date:** [TODO_DATE]

**Post URL:** [TODO_BLOG_URL]

**Cover image:** TODO screenshot — not yet captured.

### Objective

Document the move from a single `postgres:15-alpine` Docker container (used by all backend services in local development) to Amazon RDS for PostgreSQL, while preserving the application's existing **database-per-service** design (each of the seven backend services keeps its own logical database and its own Prisma schema/migrations).

### Summary

`fitness-assistant` already models its data with Prisma, one `schema.prisma` and one `migrations/` folder per service, all pointing at different databases on the same Postgres instance in local development (`gymcoach_auth`, `gymcoach_user`, `gymcoach_fitness`, `gymcoach_ai`, etc.). This post explains how that same multi-database layout was reproduced on a single private Amazon RDS instance, and how `prisma migrate deploy` was run against it per service.

### Main Content

- Creating a DB subnet group across two private subnets and an RDS instance with public access disabled.
- Creating one logical database per MVP service on the RDS instance.
- Running `prisma migrate deploy` per service against the RDS endpoint, and calling out that `user-service`'s production Dockerfile does **not** run this automatically on container start (unlike `auth-service`/`ai-service`), so it had to be run as an explicit step.
- Verifying connectivity only from inside the VPC, never opening RDS to the public internet.
- TODO: Insert real migration command output and a redacted connection test screenshot.

### What I Learned

- How to keep a "database-per-service" design intact when moving from a single Docker container to a single managed RDS instance with multiple databases.
- Why it matters to check a production Dockerfile's `CMD` line service-by-service instead of assuming they all behave the same way.

{{% notice warning %}}
Never publish a real RDS endpoint, master username, or password in this post. Use `[TODO_RDS_ENDPOINT]`, `[TODO_DATABASE_NAME]`, `[TODO_DATABASE_USER]` placeholders until credentials are safely redacted for a public audience.
{{% /notice %}}
