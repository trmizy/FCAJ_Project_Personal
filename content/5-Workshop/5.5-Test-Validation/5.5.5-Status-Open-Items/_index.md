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
| Frontend (S3) | Deployed | — | Pending full integration | Needs verification |
| CI/CD | Not built | — | — | **Incomplete** |

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
| CI/CD | A pipeline builds the artifacts/images and deploys them instead of manual console uploads |
| Cost controls | DEV "sleep" strategy: Aurora down to 0 ACU when idle, Chat service to 0 tasks out of hours, NAT Gateway only when needed |
| Monitoring | CloudWatch alarms on Lambda errors/throttles, DLQ depth, Aurora capacity and Chat target health, notified by e-mail |

#### Postponed on purpose (not blockers for DEV)

- Rotating the ADMIN credential.
- Remediating the remaining 12 seed accounts.
- HTTPS for the frontend and the Chat ALB (needs a domain and an ACM certificate), with CloudFront + Origin Access Control in front of the S3 bucket.
