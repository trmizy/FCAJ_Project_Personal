---
title: "5.5 Production Containers"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.5. </b> "
---

### Analysis of Existing Dockerfiles

Most services in `fitness-assistant` already ship a **production-oriented multi-stage Dockerfile** alongside a separate `Dockerfile.dev`:

| Service | Production `Dockerfile`? | Notes |
| --- | --- | --- |
| `frontend/web` | Yes | Multi-stage: `pnpm build` → static `dist/` served by `nginx:1.25-alpine` on port 80. Bakes `VITE_API_URL`, `VITE_SOCKET_URL`, `VITE_CHAT_WS_URL` in as build ARGs. |
| `backend/gateway` | Yes | Multi-stage (`base`/`deps`/`builder`/`runner`), `node:20-alpine`, `tsc` build, `EXPOSE 3000`. |
| `backend/services/auth-service` | Yes | Multi-stage; `CMD sh -c "prisma migrate deploy && node dist/server.js"` (runs migrations on start). |
| `backend/services/ai-service` | Yes | Same pattern as `auth-service`, `EXPOSE 3003`. |
| `backend/services/user-service` | Yes | Base image `node:20-slim` (installs `openssl`, `fonts-dejavu-core` for PDF generation). `CMD node dist/server.js` — **does not** run `prisma migrate deploy` automatically, unlike `auth-service`/`ai-service`. |
| `backend/services/fitness-service` | Yes | Same multi-stage pattern as siblings. |
| `backend/services/chat-service` | Yes | Same multi-stage pattern (not in MVP scope). |
| `backend/services/gym-service` | **No** — only `Dockerfile.dev` exists | Not in MVP scope; would need a production Dockerfile authored before deployment. |
| `backend/services/payment-service` | **No** — only `Dockerfile.dev` exists | Not in MVP scope; same gap as `gym-service`. |

{{% notice warning %}}
Do not claim `gym-service` or `payment-service` have a production-ready container — they do not, as of this Workshop. If they are added to a future deployment, a production Dockerfile must be written and tested first.
{{% /notice %}}

### What "Production" Means Here

- Multi-stage build: a `deps`/`builder` stage installs dependencies and compiles TypeScript; a `runner` stage copies only the built artifacts and production `node_modules`.
- No dev file-watcher (`nodemon`, `vite dev`, etc.) — the frontend serves a static build via Nginx; backend services run the compiled `dist/server.js` directly.
- `.env` files are never copied into the image; runtime configuration comes from environment variables injected by Docker Compose / the deployment environment.
- A `.dockerignore` file excludes `node_modules`, `.env`, and other local artifacts from the build context.

### Example: `.dockerignore`

See [`/files/docker/.dockerignore.example`](/files/docker/.dockerignore.example) for a reference `.dockerignore` covering `node_modules`, `.env*`, `dist`, and local editor files.

### Example: Production Dockerfile Pattern

See [`/files/docker/Dockerfile.production.example`](/files/docker/Dockerfile.production.example) for a reference multi-stage Dockerfile matching the pattern already used by `auth-service`/`ai-service`/`fitness-service` in the source repository (this is a **reference example**, not a literal copy of the source file — always check the actual service's `package.json` build script before adapting it).

### Non-Root User

The existing Dockerfiles in `fitness-assistant` run as the image's default user. TODO: verify whether a non-root `USER` directive is compatible with each service (in particular `user-service`, which writes to a local `uploads/` directory) before adding one, and record the result here.

### Health Check

TODO: confirm whether each service's Dockerfile defines a `HEALTHCHECK` (the multi-stage images `apk add wget`, suggesting a wget-based healthcheck is used in at least some services) — verify per service and record findings here rather than assuming.

### Building Images

```bash
docker build -t fitness-assistant/auth-service:local -f backend/services/auth-service/Dockerfile .
docker build -t fitness-assistant/frontend:local \
  --build-arg VITE_API_URL=http://localhost:3000 \
  -f frontend/web/Dockerfile .
```

{{% notice note %}}
Confirm the exact build context path for each service before running these commands — some multi-stage Dockerfiles in a pnpm workspace expect the build context to be the **repository root**, not the service subfolder, because they need access to `backend/shared` and the root `pnpm-lock.yaml`.
{{% /notice %}}

### Inspecting Images

```bash
docker images | grep fitness-assistant
```

TODO: record actual image sizes once built.

### Image Scanning

TODO: if a scanning tool (e.g. `docker scout`, `trivy`, or Amazon ECR's built-in basic scanning) is used, record the tool and findings here. Not yet executed.

### Tagging Strategy

Recommended: tag each image with both a semantic/date-based tag and `latest`, e.g. `service:2026-07-15` and `service:latest`, so a specific deployed version can always be identified and rolled back to. See [5.8 ECR](../5.8-ECR/) for the full tagging convention used when pushing to Amazon ECR.
