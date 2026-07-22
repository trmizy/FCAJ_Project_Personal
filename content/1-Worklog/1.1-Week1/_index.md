---
title: "Week 1"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 1.1. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Read and understand the FCAJ internship regulations (https://hcm-rules.awsfcaj.com/3-project/) and the report template requirements.
- Clone and analyze the [Fitness Assistant](https://github.com/trmizy/fitness-assistant) source code at a high level (folder structure, services, README).
- Run the project locally to confirm which services actually exist and how they start.
- Define the scope of the AWS MVP based on what the source code actually supports, not on assumptions.

### Tasks Performed

- Read the FCAJ project rules and the `fcj-workshop-template` structure.
- Cloned `fitness-assistant` and reviewed the top-level folders, `README.md`, and any `docker-compose.yml`.
- Attempted to run the application locally following the project's own instructions.
- Took notes on the real technology stack (frontend framework, backend language/framework, database, cache, auth).
- Drafted an initial, unverified list of AWS services that could plausibly support this stack.

### Results Achieved

- A working understanding of the FCAJ report structure and submission rules.
- A first-pass inventory of the Fitness Assistant repository structure.
- TODO: Confirm whether the local run succeeded end-to-end and record the exact steps that worked.

### Difficulties

- Some services/scripts described informally online may not match what is actually in the repository — required verifying everything directly against source files rather than assuming a "typical microservices" layout.

### How It Was Resolved

- Cross-checked every claim about services/ports/environment variables against actual files (`package.json`, `docker-compose.yml`, `README.md`) instead of relying on general microservices conventions.

### AWS Skills / Services Learned

- AWS Free Tier account model and IAM basics.
- Overview of the AWS services likely relevant to this project (EC2, ECR, RDS, S3, CloudWatch) — conceptual only at this stage, nothing deployed yet.

### Evidence Still Required

- TODO: Screenshot of the application running locally.
- TODO: Terminal output of the local run (build + start).
- TODO: Notes/screenshot confirming the FCAJ rules page and template were reviewed.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Read FCAJ project rules and report template | [TODO_DATE] | [TODO_DATE] | https://hcm-rules.awsfcaj.com/3-project/ |
| 2 | Clone and review `fitness-assistant` repository structure | [TODO_DATE] | [TODO_DATE] | https://github.com/trmizy/fitness-assistant |
| 3 | Run the project locally following its own README | [TODO_DATE] | [TODO_DATE] | Project README |
| 4 | Draft initial MVP scope (draft only, not final) | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] FCAJ rules and template reviewed
- [ ] `fitness-assistant` repository cloned and structure documented
- [ ] Application runs locally with evidence captured
- [ ] Draft MVP scope written down

### Related Workshop Section

- [5.1 Overview](../../5-Workshop/5.1-Overview/)
- [5.3 Prerequisites](../../5-Workshop/5.3-Prerequisites/)
