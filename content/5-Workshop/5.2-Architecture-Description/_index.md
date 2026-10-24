---
title: "Architecture Description"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2. </b> "
---

This section describes the architecture actually deployed for the DEV environment — a serverless-first redesign of the earlier EC2 + Docker Compose MVP plan. It is split into seven pages, each covering one concern:

1. [5.2.1 Architecture Overview](5.2.1-Architecture-Overview/) — the components, the shared infrastructure, and the overall shape of the system.
2. [5.2.2 Architecture Diagram](5.2.2-Architecture-Diagram/) — the component diagram, rendered directly in this report.
3. [5.2.3 Main Request Flows](5.2.3-Main-Request-Flows/) — the Core API path, the Chat path, and the background-processing path, walked through step by step.
4. [5.2.4 AWS Services and Selection Rationale](5.2.4-AWS-Services-Selection/) — which AWS service was used for which job, and why that one rather than an alternative.
5. [5.2.5 Security and IAM](5.2.5-Security-IAM/) — network isolation, per-service least-privilege IAM, and secret handling.
6. [5.2.6 Scalability and Operations](5.2.6-Scalability-Operations/) — how each component scales, and what is still an open operational gap.
7. [5.2.7 Cost Optimization and Clean-up](5.2.7-Cost-Optimization-Cleanup/) — the cost levers already in use and the ones still planned.

{{% notice note %}}
This architecture is documented from an internal deployment runbook kept throughout the project (console steps, environment variables, and screenshots as the system was actually built). Where a detail is not yet confirmed in that runbook, it is marked rather than guessed at — consistent with the [5.1 Overview](../5.1-Overview/)'s Definition of Done.
{{% /notice %}}
