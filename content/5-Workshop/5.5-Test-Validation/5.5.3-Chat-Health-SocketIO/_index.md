---
title: "Chat health and Socket.IO"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.5.3. </b> "
---

| # | Test | How | Expected result | Status |
|---|---|---|---|---|
| C1 | ECS service is stable | ECS → `fitness-assistant-dev-cluster` → *Services* | `fitness-assistant-dev-chat-service` Active, 1/1 tasks running, deployment *Completed* | Passed |
| C2 | ALB sees a healthy task | EC2 → Target groups → `fitness-assistant-dev-chat-tg` → *Targets* | One private IP (10.0.10.x / 10.0.11.x) on port 3005, status **Healthy** | Passed |
| C3 | HTTP health through the ALB | `GET http://<chat-alb-dns>/health` | HTTP 200 | Passed |
| C4 | Socket.IO handshake | `GET http://<chat-alb-dns>/socket.io/?EIO=4&transport=polling` | Body starts with `0{"sid":"…","upgrades":["websocket"],"pingInterval":…,"pingTimeout":…}` — not 404, 502 or 503 | Verified during deployment |
| C5 | Internal paths hidden | `GET http://<chat-alb-dns>/internal/x` and `/metrics` | Fixed `404 Not Found` from the ALB listener rules; the request never reaches the container | Listener rules in place |
| C6 | REST through API Gateway | `GET https://<api-id>.execute-api.ap-southeast-1.amazonaws.com/chat/conversations` | Reaches the Chat backend: 401 without a token, the conversation list with a valid Bearer token | To include in the final E2E pass |
| C7 | Runtime secret wiring | CloudWatch log group `/ecs/fitness-assistant-dev-chat` after revision 3 | No `URL must start with postgresql://`; the service connects to `fitness_assistant_chat` | To confirm in the log after the revision 3 rollout |
| C8 | Real-time messaging | Two users open the same conversation in the frontend and exchange messages | Messages appear live for both without refreshing | To include in the final E2E pass |

#### Evidence

![C1 — service active with 1/1 tasks running](/images/workshop/runbook/img330.jpg)

![C2 — target 10.0.11.164:3005 healthy](/images/workshop/runbook/img331.jpg)

![C5 — listener rules: /internal/* and /metrics answered by the ALB, default to the target group](/images/workshop/runbook/img328.jpg)

#### If something fails

| Symptom | Cause to check |
|---|---|
| Task goes from PENDING to STOPPED | *Stopped reason*: image pull (ECR/NAT), secret injection (execution role policy), or the container crashing on start (log group) |
| Target *Unhealthy* | Chat SG must allow 3005 from the ALB SG; `/health` must return 200 within 5 s; grace period long enough for start-up |
| 502 / 503 from the ALB | No healthy target registered yet, or the task restarting |
| Socket.IO connects then drops | ALB idle timeout (set to 120 s) and target-group stickiness; only 1 task while session state is in memory |
