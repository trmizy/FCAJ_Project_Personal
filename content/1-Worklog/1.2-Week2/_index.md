---
title: "Week 2"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 1.2. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Analyze the frontend, backend and any microservices in `fitness-assistant` in depth.
- Identify each service's port, dependencies and required environment variables from the actual source (not assumed defaults).
- Draw the request flow between frontend, backend/API layer and database.

### Tasks Performed

- Read through the backend source tree (routes, controllers/services, ORM/schema files) to identify real service boundaries.
- Reviewed `.env.example` (or equivalent) files, if present, to list actual required environment variables.
- Reviewed the frontend source to identify its framework, build tool, and how it calls the backend (base API URL, proxy config).
- Sketched a request-flow diagram: browser → frontend → backend service(s) → database/cache.

### Results Achieved

- A verified map of services/ports/environment variables backed by actual files in the repository.
- TODO: Insert the finalized request-flow diagram (draw.io or equivalent) once validated against a working local run.

### Difficulties

- Distinguishing between the application's own internal API routing (a plain Express/Node router, for example) and an actual **Amazon API Gateway** service — these are conceptually different and must not be conflated in the architecture description.

### How It Was Resolved

- Documented explicitly, for every "gateway"-like component found in source, whether it is application code (e.g. a reverse proxy or internal router) or a genuine AWS managed service, and carried that distinction through to the Workshop and Proposal sections.

### AWS Skills / Services Learned

- Refresher on reverse proxy vs. API Gateway concepts.
- Note-taking discipline for translating an existing codebase into an accurate infrastructure diagram.

### Evidence Still Required

- TODO: Screenshot(s) of the codebase structure (IDE or `tree` output).
- TODO: Exported request-flow diagram.
- TODO: List of confirmed environment variables per service.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Review backend routes/services/ORM schema | [TODO_DATE] | [TODO_DATE] | `fitness-assistant` source |
| 2 | Review frontend structure and API base URL config | [TODO_DATE] | [TODO_DATE] | `fitness-assistant` source |
| 3 | List confirmed environment variables per service | [TODO_DATE] | [TODO_DATE] | `.env.example` files |
| 4 | Draft request-flow diagram | [TODO_DATE] | [TODO_DATE] | draw.io |

### Completion Checklist

- [ ] Backend service boundaries documented from source
- [ ] Frontend framework and API base URL confirmed
- [ ] Environment variables listed per service
- [ ] Draft request-flow diagram created

### Related Workshop Section

- [5.2 Architecture](../../5-Workshop/5.2-Architecture/)
