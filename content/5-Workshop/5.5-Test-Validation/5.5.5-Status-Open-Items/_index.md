---
title: "5.5.5 Validation status and open items"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.5.5. </b> "
---

#### Status at the latest checkpoint

| Component | AWS deployment | Migration | End-to-end test | Status |
|---|---|---|---|---|
| Shared infrastructure (VPC, subnets, SGs, NAT, IGW) | Complete | — | — | **Complete** |
| Aurora PostgreSQL | Complete | 7/7 databases restored | Verified | **Complete** |
| Auth Service | Deployed | Complete | Passed (including a transaction-atomicity fix) | **Complete** |
| User Service | Deployed | Complete | Passed | **Complete** |
| Fitness Service | Deployed | Complete | Pending | Needs verification |
| Gym Service | Deployed | Complete | Pending | Needs verification |
| Payment Service | Deployed | Complete | Pending | Needs verification |
| AI / Worker / Jobs | Deployed | Complete | Pending | Needs verification |
| Chat Service (REST + Socket.IO) | Deployed | Complete | Pending | Needs verification |
| Frontend (S3 + CloudFront) | Deployed | — | Pending full integration | Needs verification |
| CI/CD — CI (PR validation) | Deployed, active | — | Real (every push) | **Complete** |
| CI/CD — CD (deploy pipeline) | Active, exercised for real | — | Real (Lambda, ECS and infra all exercised) | **Complete** |

#### CI/CD — exactly what's real today

| Piece | Status | Evidence |
|---|---|---|
| `pr-validation.yml` (lint, typecheck, unit tests, IaC lint, Docker build) | **Active**, runs on every PR | Real GitHub Actions runs, green |
| `docker-test.yml` (fast Docker test + Critical DB Integration) | **Active**, runs on every push | Real GitHub Actions runs, green |
| `dev-build.yml` (Gate 1 — build/hash Lambda zips, no AWS access) | **Active**, auto-runs on push to `aws-deploy` | Real automatic run, correctly skips when no Lambda service changed |
| `dev-deploy.yml` (Gate 2 — real Lambda code deploy) | **Active**, manual dispatch, reviewer-gated | **Exercised for real**: a dry run, then a real deploy of the `ai` service (3 functions updated, smoke-tested) |
| `chat-deploy.yml` (Gate 3 — ECS Fargate image deploy) | **Active**, manual dispatch, reviewer-gated | **Exercised for real** on 2026-10-16 — task definition now at revision 9 |
| `infra-plan.yml` / `infra-deploy.yml` (Gates 4–5 — API Gateway CloudFormation changes) | **Active**, manual dispatch, reviewer-gated | **Exercised for real**: a genuine `execute-change-set` ran successfully and the stack is in sync with its template |

#### Plan to close the open items

| Item | Concrete check to pass |
|---|---|
| Fitness E2E | Create a workout plan, log a workout, see stats; reminders appear in the jobs log |
| Gym E2E | Browse gyms/PTs, generate and scan a QR check-in, owner views members |
| Payment E2E | Configure VNPAY sandbox credentials, pay for a PT contract, receive the return/webhook, see the reconciliation job confirm it |
| AI / Worker / Jobs | `POST /ai/ask` answers from Nova Pro; a plan generation completes through SQS; the first knowledge job bootstraps the 1024-dimension OpenSearch indexes; auto-accept runs |
| Chat E2E | Tests C6 and C8 in [5.5.3](../5.5.3-Chat-Health-SocketIO/) |
| Frontend integration | Every page of the user and admin flows works against the AWS backends (tests T5–T7 in [5.5.2](../5.5.2-Auth-Frontend-Smoke-Test/)) |
| Bugs found during E2E | Fixed, redeployed and re-tested |
| Admin account access | **Done 2026-10-21** (see [5.4.13 Step 12](../../5.4-Deployment-Guide/5.4.13-CD-Pipeline-Activation/)): an ADMIN login is available on the deployed app. The owner changes the temporary password in the app after first login. |
| Cost controls | DEV "sleep" strategy: Aurora down to 0 ACU when idle, Chat service to 0 tasks out of hours, NAT Gateway only when needed |
| Monitoring | **Done**: 12 CloudWatch alarms notify an SNS topic with a confirmed e-mail subscription; a monthly AWS Budget alerts on cost |

#### Postponed on purpose (not blockers for DEV)

- Remediating the remaining 12 seed accounts.
- HTTPS for the Chat ALB specifically (needs a domain and an ACM certificate — the ALB itself still only has an HTTP:80 listener). **The frontend already has real HTTPS** via the CloudFront distribution in front of the S3 bucket, confirmed live; that part of this item is done, not postponed.
