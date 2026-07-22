---
title: "Week 9"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 1.9. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Configure a reverse proxy on EC2 in front of the frontend and application gateway container.
- Confirm that the frontend, application gateway and backend microservices are correctly wired end to end on AWS.
- Assess the file/image upload path (`multer`, local disk) and document the storage decision for the MVP.

### Tasks Performed

- Installed and configured Nginx on the EC2 host as a reverse proxy in front of the frontend container (built with its own internal Nginx per the project's `frontend/web/Dockerfile`) and the application gateway container (`backend/gateway`, port 3000).
- Verified that `VITE_API_URL` (and related build-time variables `VITE_SOCKET_URL`, `VITE_CHAT_WS_URL`) were set correctly at image build time, since the frontend bakes its backend URL in at build time rather than reading it at runtime.
- Confirmed request flow: browser → EC2 reverse proxy → application gateway container → downstream services (auth/user/fitness/ai) → RDS.
- Reviewed the application's existing upload code (`multer`, saving to a local `uploads/` directory) and confirmed that **no Amazon S3 integration exists in the source code today**. Documented Amazon S3 as a **Planned** MVP-adjacent item rather than an implemented one, since wiring S3 in would require an actual code change to `user-service` that is out of scope unless implemented and tested.

### Results Achieved

- End-to-end request flow verified from the browser to the database through the deployed containers.
- A clear, evidence-based decision recorded for file storage: local disk on the EC2 host for now, Amazon S3 documented as future work.

### Difficulties

- Because `VITE_API_URL` is baked into the frontend image at build time, changing the backend URL later requires rebuilding and re-pushing the frontend image rather than just changing an environment variable at runtime.

### How It Was Resolved

- Documented this build-time coupling explicitly so future redeployments to a different domain/IP are not mistaken for a simple config change.

### AWS Skills / Services Learned

- Reverse proxy configuration on EC2.
- The importance of validating "is this actually implemented" before writing infrastructure for a feature (Amazon S3, in this case) that the application does not yet call.

### Evidence Still Required

- TODO: Screenshot of the Nginx reverse proxy configuration.
- TODO: Screenshot/video of the frontend successfully calling the backend through the deployed stack.
- TODO: Confirmation note on the final storage decision for user uploads.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Install and configure Nginx reverse proxy | [TODO_DATE] | [TODO_DATE] | [Workshop 5.9](../../5-Workshop/5.9-EC2-Deployment/) |
| 2 | Verify frontend build-time API URL wiring | [TODO_DATE] | [TODO_DATE] | `frontend/web/Dockerfile` |
| 3 | Verify end-to-end request flow | [TODO_DATE] | [TODO_DATE] | — |
| 4 | Document file storage decision (local disk vs. S3) | [TODO_DATE] | [TODO_DATE] | [Workshop 5.10](../../5-Workshop/5.10-S3-Storage/) |

### Completion Checklist

- [ ] Reverse proxy configured on EC2
- [ ] Frontend correctly reaches the application gateway and downstream services
- [ ] File storage decision documented (S3 marked Planned, not Implemented)

### Related Workshop Section

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/)
- [5.10 S3 Storage](../../5-Workshop/5.10-S3-Storage/)
