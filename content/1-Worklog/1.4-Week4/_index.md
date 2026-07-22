---
title: "Week 4"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 1.4. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Design a first AWS architecture proposal for the MVP, based strictly on the services confirmed in Week 2–3 (not on a generic template architecture).
- Produce a draw.io architecture diagram.
- Draft the VPC, subnet and Security Group plan.

### Tasks Performed

- Reviewed the actual `fitness-assistant` topology confirmed in source: a React/Vite frontend, an application-level API gateway container (`backend/gateway`), and multiple backend microservices (auth, user, fitness, AI/RAG, plus chat/gym/payment which exist in source but are heavier or lack production Dockerfiles).
- Decided which services belong in the MVP versus Future Development, based on evidence (does a production Dockerfile exist? does it need extra infrastructure such as a vector database or a self-hosted LLM?).
- Drew a first-draft AWS architecture diagram (single EC2 host running Docker Compose, Amazon RDS for PostgreSQL, Amazon ECR for images).
- Started drafting the VPC/subnet/Security Group layout.

### Results Achieved

- A documented, evidence-based MVP scope (see [Proposal](../../2-Proposal/) for the finalized version).
- TODO: Attach the exported draw.io diagram once finalized.

### Difficulties

- The application's own internal `backend/gateway` container is easy to confuse with **Amazon API Gateway**; the architecture diagram had to make this distinction explicit.
- The AI service depends on a self-hosted LLM runtime, which has real CPU/RAM requirements that must be reflected honestly in the instance-sizing plan rather than assuming a Free Tier instance is sufficient.

### How It Was Resolved

- Labeled the application gateway container explicitly as "Application Gateway (backend/gateway container on EC2)" in every diagram and document, reserving "Amazon API Gateway" only for the actual AWS managed service (currently not used by this MVP).
- Added an explicit sizing warning for the AI/RAG service in the architecture notes, to be elaborated in the [EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) workshop section.

### AWS Skills / Services Learned

- VPC design fundamentals (public/private subnets, route tables, Internet Gateway).
- How to translate a docker-compose based application topology into an AWS network diagram.

### Evidence Still Required

- TODO: Final architecture diagram (`/images/workshop/architecture/fitness-assistant-aws-architecture.png` and the downloadable `.drawio` source).
- TODO: Screenshot of the VPC design whiteboarding/draft.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Decide MVP vs. future-development service scope | [TODO_DATE] | [TODO_DATE] | Weeks 2–3 findings |
| 2 | Draft AWS architecture diagram | [TODO_DATE] | [TODO_DATE] | draw.io |
| 3 | Draft VPC/subnet/Security Group plan | [TODO_DATE] | [TODO_DATE] | — |
| 4 | Review draft with mentor/self-review checklist | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] MVP scope documented with justification
- [ ] Draft architecture diagram created
- [ ] Draft VPC/subnet/Security Group plan written
- [ ] Diagram and plan reviewed

### Related Workshop Section

- [5.2 Architecture](../../5-Workshop/5.2-Architecture/)
