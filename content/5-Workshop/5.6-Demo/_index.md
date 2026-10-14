---
title: "5.6 Demo"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.6. </b> "
---

{{% notice info %}}
The deployment runbook only contains AWS console evidence. Screenshots and a short screen recording of the running application are captured during the final end-to-end pass ([5.5.5](../5.5-Test-Validation/5.5.5-Status-Open-Items/)) and added to this page; until then the page describes the demo script, so the demo is reproducible by anyone with access to the DEV environment.
{{% /notice %}}

#### Entry points

| What | URL |
|---|---|
| Web application | `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com` |
| REST API | `https://<api-id>.execute-api.ap-southeast-1.amazonaws.com` |
| Real-time chat | `http://fitness-assistant-dev-chat-alb-<id>.ap-southeast-1.elb.amazonaws.com` (used by the frontend for Socket.IO) |

#### 5.6.1 Member journey

1. **Register and log in** — `/register`, verify, then `/login` (Auth Lambda, JWT).
2. **Onboarding and profile** — body profile, goals, profile photo uploaded straight to the private S3 bucket with a presigned URL (User Lambda).
3. **Training** — browse exercises, create or import a workout plan, start and finish a workout; the reminder jobs pick up today's planned workouts (Fitness Lambda + EventBridge).
4. **AI coach** — ask a question in the AI chat (Bedrock Nova Pro, grounded on the OpenSearch knowledge indexes), then request a generated workout or nutrition plan and watch it complete through the SQS worker (AI HTTP Lambda → SQS → AI Worker).
5. **Gyms and personal trainers** — browse gyms and PTs, check in at a gym with the signed QR code (Gym Lambda).
6. **Payment** — top up the wallet or pay for a PT contract through the VNPAY sandbox; the payment is confirmed by the provider callback and the 5-minute reconciliation job (Payment Lambda).
7. **Chat** — open a conversation with a PT; messages arrive live over Socket.IO (Chat on ECS Fargate).

#### 5.6.2 Admin journey

1. Log in with an admin account.
2. **Users** — list users, change a role, disable and re-enable an account (`/auth/users/*`).
3. **PT applications and contracts** — review PT applications and their documents (User Lambda, private S3).
4. **Payments** — review transactions and withdrawals (`/admin/payments/*`).
5. **AI administration** — open the AI overview (`/admin/ai/*`), rate-limited like every AI route.

#### What the demo proves

| Step | AWS path exercised |
|---|---|
| Any page load | S3 static website |
| Login, profile, training, gyms, payments, admin | API Gateway → service Lambda → Aurora (private subnets) |
| AI answers and plans | API Gateway → AI Lambda → Bedrock (via NAT) and OpenSearch (via VPC endpoint), SQS → AI Worker |
| Reminders, settlements, reconciliation | EventBridge Scheduler → jobs Lambdas |
| Live chat | Chat ALB → ECS Fargate → Aurora |

Neither the AI coach nor any other feature of the application replaces medical advice.
