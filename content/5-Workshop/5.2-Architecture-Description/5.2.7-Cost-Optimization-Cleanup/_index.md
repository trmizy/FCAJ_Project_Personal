---
title: "5.2.7 Cost Optimization and Clean-up"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.2.7. </b> "
---

### Cost Levers Already in Use

- **Lambda over EC2 for six of eight services.** Pay-per-invocation means a DEV environment that is idle most of the day is not paying for a running instance the whole time — the exact trade-off already reasoned through once in [Week 8](../../../1-Worklog/1.8-Week8/) when deciding whether to self-host the AI model on EC2.
- **Aurora Serverless v2 with a low ACU floor.** The cluster is currently held at a 0.5 ACU minimum rather than 0, deliberately: letting it auto-pause and auto-resume on every request burst would make smoke tests during active development noisy (a resume adds latency that looks like a failure if you're not expecting it). The floor is planned to drop to 0 ACU once the active development phase settles down, which would let the database cost approach zero during idle periods.
- **One Aurora cluster with seven logical databases**, instead of seven separate clusters — one cluster's baseline cost instead of seven.
- **S3 static website hosting for the frontend**, instead of a Lambda, Fargate task, or EC2 instance serving static files — near-zero marginal cost for a build that doesn't change at request time.
- **A single NAT Gateway** (not one per Availability Zone) for the DEV environment's outbound traffic — a deliberate single point of egress rather than paying for per-AZ redundancy that DEV does not need yet.
- **Fargate task sized to the workload, not guessed:** the Chat Service's 0.5 vCPU / 1 GB dev sizing was set based on what a single Socket.IO service under light DEV load actually needs, not a default/largest-available size.

### Planned, Not Yet Implemented

- **A DEV environment "sleep" strategy** — pausing or scaling down resources outside working hours (Aurora to 0 ACU, the Chat Fargate service to 0 tasks) is an explicit next step, not yet automated. Until it is, DEV incurs some cost even when nobody is actively testing it.
- **CloudFront in front of the S3 frontend** — the frontend is currently served directly from an S3 website endpoint rather than through CloudFront with Origin Access Control. This is a security and performance gap as much as a cost one (no CDN caching yet), and is blocked on CloudFront not being usable in this environment yet rather than on a deliberate cost decision.

### Clean-up

This project does not yet have its own dedicated Workshop clean-up page with a verified teardown sequence (the original MVP plan's [5.16 Cleanup](../../5.16-Cleanup/) describes the superseded EC2-based teardown and needs to be rewritten for the serverless resources listed in [5.2.1](../5.2.1-Architecture-Overview/) — Lambdas, the Aurora cluster, the Fargate service/cluster/ALB, the API Gateway, the S3 buckets, and the VPC networking). Until that rewrite happens, treat [5.16 Cleanup](../../5.16-Cleanup/) as describing an earlier architecture, not this one.
