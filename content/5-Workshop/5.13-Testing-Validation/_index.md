---
title: "5.13 Testing and Validation"
date: 2026-07-15
weight: 13
chapter: false
pre: " <b> 5.13. </b> "
---

{{% notice warning %}}
No test case below is marked `PASS` until it has actually been executed against a real deployment with evidence captured. The default status is `TODO / Not executed` — do not change it without a linked screenshot, log excerpt, or command output.
{{% /notice %}}

### Test Case Table

| ID | Test | Preconditions | Steps | Expected Result | Evidence | Status |
|----|------|---------------|-------|------------------|----------|--------|
| TC-01 | Frontend accessible | EC2 deployed, DNS/IP known | Open `http://<EC2_IP>/` | Frontend loads without error | TODO | TODO / Not executed |
| TC-02 | User registration | Frontend + auth-service reachable | Submit the registration form with a new account | Account created; success response from `auth-service` | TODO | TODO / Not executed |
| TC-03 | Login | Registered account exists | Submit login form | JWT issued; redirected to authenticated area | TODO | TODO / Not executed |
| TC-04 | JWT-protected endpoint | Valid JWT from TC-03 | Call a protected API route with the JWT | 200 response with expected data | TODO | TODO / Not executed |
| TC-05 | User profile | Logged in | View/update profile | Profile data persists correctly | TODO | TODO / Not executed |
| TC-06 | Exercise list | Logged in | Browse exercise catalog | List loads from `fitness-service` | TODO | TODO / Not executed |
| TC-07 | Workout plan | Logged in | Create/view a workout plan | Plan persists and displays correctly | TODO | TODO / Not executed |
| TC-08 | Workout log | Logged in | Log a completed workout | Log entry persists and displays in history | TODO | TODO / Not executed |
| TC-09 | RDS persistence | Data created in TC-02–TC-08 | Restart the application containers | Data is still present after restart (proves it lives in RDS, not container memory) | TODO | TODO / Not executed |
| TC-10 | Redis/cache | `ai-service`/`fitness-service` running | Trigger a queued job (e.g. knowledge ingestion or a rate-limited request) | Redis-backed queue/rate-limit behaves as expected | TODO | TODO / Not executed |
| TC-11 | S3 upload | Only applicable if S3 is actually implemented | N/A | N/A | N/A | **N/A — S3 is Planned, not Implemented (see [5.10](../5.10-S3-Storage/))** |
| TC-12 | Unauthorized request | None | Call a protected endpoint without a token | 401 Unauthorized | TODO | TODO / Not executed |
| TC-13 | Invalid token | None | Call a protected endpoint with a malformed/expired JWT | 401/403 rejected | TODO | TODO / Not executed |
| TC-14 | Database failure | RDS temporarily unreachable (e.g. Security Group rule removed in a controlled test) | Call an endpoint that requires the database | A clean error response, not a crash/hang | TODO | TODO / Not executed |
| TC-15 | Container restart | Stack running | `docker compose restart <service>` | Service recovers and rejoins the stack | TODO | TODO / Not executed |
| TC-16 | CloudWatch log | CloudWatch Agent configured | Trigger application activity | Corresponding log entries appear in CloudWatch Logs | TODO | TODO / Not executed |
| TC-17 | CloudWatch alarm | Alarm configured | Force the alarm condition (or use `set-alarm-state`) | Alarm transitions to `ALARM` | TODO | TODO / Not executed |
| TC-18 | SNS email | SNS subscription confirmed | Trigger TC-17 | Email received at the subscribed address | TODO | TODO / Not executed |

### How to Update This Table

For each test actually executed: change the Status column to `PASS` or `FAIL`, and add a link/path to the evidence (screenshot, log excerpt, or command output saved under `static/images/workshop/testing/`). Never change a Status to `PASS` without a corresponding Evidence entry.
