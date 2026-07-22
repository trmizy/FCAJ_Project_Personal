---
title: "Week 3"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Review the Dockerfile(s) that already exist in `fitness-assistant` and identify whether they are development-only or production-ready.
- Draft production-oriented Dockerfiles (multi-stage builds, no dev watchers, `.dockerignore`, non-root user where compatible).
- Validate the containers locally with Docker Compose before moving to AWS.

### Tasks Performed

- Inspected existing Dockerfile(s) per service/app for base image, build steps and CMD/ENTRYPOINT.
- Drafted `Dockerfile.production.example` for the services that need it, based on the actual build tooling found in source (e.g. actual `npm run build` script name).
- Added a `.dockerignore` example to avoid copying `node_modules`, `.env`, and other local artifacts into the image.
- Ran a local Docker Compose build to confirm the production-style images start and serve traffic on the expected ports.

### Results Achieved

- Draft production Dockerfile(s) that build successfully locally.
- TODO: Record final image sizes before/after optimization.

### Difficulties

- Ensuring the production build step actually matches the script names defined in the project's own `package.json`/build configuration, rather than a generic guess.

### How It Was Resolved

- Read the actual `package.json` scripts (or equivalent) before writing any `RUN` build step, so the Dockerfile only calls commands that exist in the source repository.

### AWS Skills / Services Learned

- Container image best practices that map to Amazon ECR requirements (tagging, minimizing layers, avoiding embedded secrets).

### Evidence Still Required

- TODO: `docker build` command output.
- TODO: `docker images` output showing image sizes.
- TODO: Screenshot of the container running locally in production mode.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Review existing Dockerfile(s) | [TODO_DATE] | [TODO_DATE] | `fitness-assistant` source |
| 2 | Draft `Dockerfile.production.example` per service | [TODO_DATE] | [TODO_DATE] | — |
| 3 | Add `.dockerignore` and verify no secrets are copied into images | [TODO_DATE] | [TODO_DATE] | — |
| 4 | Validate with local Docker Compose build/run | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] Existing Dockerfiles reviewed
- [ ] Production Dockerfile draft created per service
- [ ] `.dockerignore` in place
- [ ] Local Docker Compose build/run verified

### Related Workshop Section

- [5.5 Production Containers](../../5-Workshop/5.5-Production-Containers/)
