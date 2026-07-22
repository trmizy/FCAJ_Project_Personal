---
title: "5.4 Run Local"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.4. </b> "
---

{{% notice note %}}
The steps below follow the project's own `README.md` and `infra/compose/docker-compose.dev.yml`. Do not run commands that are not documented in the source repository.
{{% /notice %}}

### Clone the Repository

```bash
git clone https://github.com/trmizy/fitness-assistant.git
cd fitness-assistant
```

### Create the Environment File

The project uses a single root `.env` file (not one per service) referenced by every service via `env_file` in the dev Docker Compose file.

```bash
cp .env.example .env
```

{{% notice warning %}}
Never commit the resulting `.env` file. It is already covered by this repository's `.gitignore`.
{{% /notice %}}

### Real Services (as documented in `docker-compose.dev.yml`)

| Service | Port | Role |
| --- | --- | --- |
| `web` (frontend) | 5173 | React + Vite frontend |
| `api-gateway` | 3000 | Application-level gateway: routing, JWT verification, rate limiting |
| `auth-service` | 3001 | Registration, login, JWT issuance/verification |
| `fitness-service` | 3002 | Exercises, workout plans, workout logs |
| `ai-service` | 3003 | Ollama + Qdrant RAG, AI coaching |
| `user-service` | 3004 | Profiles, InBody records |
| `chat-service` | 3005 | Chat and realtime messaging (not in MVP scope) |
| `gym-service` | 3006 | Gym management (not in MVP scope) |
| `payment-service` | 3007 | Payments/wallet (not in MVP scope) |
| `postgres` | 5433→5432 | PostgreSQL 15 (database-per-service) |
| `redis` | 6379 | Cache and BullMQ queues |
| `qdrant` | 6333/6334 | Vector database for RAG |
| `ollama` | 11434 | Self-hosted LLM runtime |

{{% notice note %}}
This service table is more complete than the one currently printed in the project's own README (which omits `gym-service` and `payment-service`). Both are confirmed present and wired into `infra/compose/docker-compose.dev.yml`.
{{% /notice %}}

### Run with Docker Compose

```bash
docker compose -f infra/compose/docker-compose.dev.yml up -d
```

On a lower-spec machine, an override file is available:

```bash
docker compose -f infra/compose/docker-compose.dev.yml -f infra/compose/docker-compose.low-resource.yml up -d
```

### Check Containers

```bash
docker compose -f infra/compose/docker-compose.dev.yml ps
```

Expected result: all core services (`web`, `api-gateway`, `auth-service`, `user-service`, `fitness-service`, `ai-service`, `postgres`, `redis`, `qdrant`, `ollama`) show a healthy/running state. TODO: attach a real screenshot once verified.

### Check Logs

```bash
docker compose -f infra/compose/docker-compose.dev.yml logs -f api-gateway
```

### Check the Frontend

Open `http://localhost:5173` in a browser. Documented seed login (from the project's README): `john.doe@example.com` / `password123`.

{{% notice warning %}}
This is a documented **seed/demo credential for local development only**. Do not reuse it for any real account, and never use it in a production or public-facing deployment.
{{% /notice %}}

### Check the API

```bash
curl http://localhost:3000/health
```

TODO: Confirm the exact health-check path exposed by the gateway and record the actual response.

### Expected Result

- Frontend loads at `http://localhost:5173` and can log in with the seed account.
- API Gateway responds on port 3000.
- Backend services report healthy in `docker compose ps`.

### Useful Project Commands

From the project's own `package.json` (root, pnpm workspace):

```bash
pnpm install
pnpm test
pnpm run build
```

### Basic Troubleshooting

- If a container exits immediately, check its logs first: `docker compose -f infra/compose/docker-compose.dev.yml logs <service>`.
- If `ollama-model-puller` has not finished pulling `llama3.2:3b` and `nomic-embed-text`, `ai-service` may not be able to answer chat requests yet — wait for it to complete before testing AI features.
- See [5.15 Troubleshooting](../5.15-Troubleshooting/) for a broader table of common errors.
