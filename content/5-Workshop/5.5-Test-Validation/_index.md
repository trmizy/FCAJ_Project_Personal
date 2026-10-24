---
title: "5.5 Test & validation"
date: 2026-07-15
weight: 5
chapter: false
pre: " <b> 5.5. </b> "
---

This section collects the checks that prove each part of the deployment works, with the evidence captured during the deployment and the exact expected results. Checks that still have to be run as part of the final end-to-end pass are marked as such rather than reported as passed.

1. [5.5.1 Schema migrations](5.5.1-Schema-Migrations/) — every service database created and migrated; data restore verified.
2. [5.5.2 Frontend, API Gateway and Auth](5.5.2-Auth-Frontend-Smoke-Test/) — the request path from the browser to Aurora.
3. [5.5.3 Chat health and Socket.IO](5.5.3-Chat-Health-SocketIO/) — the ECS service, the ALB and the WebSocket handshake.
4. [5.5.4 Background jobs, queues and logs](5.5.4-Background-Jobs-Logs/) — schedules, the SQS worker and CloudWatch Logs.
5. [5.5.5 Validation status and open items](5.5.5-Status-Open-Items/) — what is verified, what is pending, and the plan to close it.
6. [5.5.6 Monitoring and alerting with Amazon CloudWatch](5.5.6-Monitoring-Alerting/) — logs, metrics, alarms, notifications, sample requests and error-case tests.
