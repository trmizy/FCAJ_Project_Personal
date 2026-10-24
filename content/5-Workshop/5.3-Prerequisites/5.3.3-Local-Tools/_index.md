---
title: "Local tools"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.3.3. </b> "
---

The deployment was run from a Windows workstation with PowerShell. The tools below are needed to build the artifacts that the console steps upload.

| Tool | Used for |
|---|---|
| Git | Cloning the application repository (`fitness-assistant`) |
| Node.js 22 + pnpm | Building each service and producing its Lambda ZIP artifacts under `backend/services/<service>/artifacts/` (Lambda runtime is Node.js 22.x) |
| AWS CLI v2 | `aws ecr get-login-password`, `aws s3 sync` for the frontend, and `aws ecs run-task` for the data migration |
| Docker Desktop | Building the Chat Service image and the database migrator image for `linux/amd64` and pushing them to Amazon ECR |
| A browser with developer tools | Checking API calls from the S3-hosted frontend (Network tab, CORS errors, HTTP 401/429 responses) |

#### Build artifacts per service

Each backend service produces separate artifacts for its HTTP handler, its background jobs and its schema migration, all from the same build:

| Artifact | Handler | Purpose |
|---|---|---|
| `<service>-lambda.zip` | `dist/lambda.handler` | HTTP API (API Gateway payload format 2.0) |
| `<service>-lambda.zip` (same ZIP) | `dist/jobs-lambda.handler` | Scheduled jobs invoked by EventBridge Scheduler |
| `<service>-migrate-lambda.zip` | `dist/migrate-lambda.handler` | Creates the service's logical database if missing and runs `prisma migrate deploy` |
| `ai-worker-lambda.zip` | `dist/worker-lambda.handler` | AI Worker consuming the SQS queue |

ZIPs larger than the direct-upload limit (for example the ~69 MiB migration artifacts) are uploaded to the deployments bucket `fitness-assistant-deployments-dev-<account-id>` first and attached to the function with **Upload from → Amazon S3 location**. Every artifact bundles the Prisma query engine for Linux (`rhel-openssl-3.0.x`), so the same ZIP built on Windows runs on Lambda.

{{% notice warning %}}
Never put `.env` files, database passwords, `JWT_SECRET`, `INTERNAL_SERVICE_SECRET`, AWS credentials or payment provider keys into an artifact, an image or an S3 bucket. All of them are resolved at runtime from AWS Secrets Manager or the function configuration.
{{% /notice %}}
