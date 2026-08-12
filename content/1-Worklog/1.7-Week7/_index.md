---
title: "Week 7"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 1.7. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Create Amazon ECR repositories for each service included in the MVP.
- Build, tag and push production Docker images.
- Create the IAM Role that EC2 will use to pull from ECR.

### Tasks Performed

- Created one ECR repository per MVP service (frontend, gateway, auth-service, user-service, fitness-service, ai-service, payment-service, gym-service), matching the actual `Dockerfile`/`Dockerfile.production.example` built in Week 3.
- Authenticated Docker to ECR (`aws ecr get-login-password`), built each image locally, tagged it with the ECR repository URI, and pushed it.
- Verified each image appeared in its ECR repository with the expected tag.
- Drafted an IAM policy granting only the ECR pull permissions EC2 needs (`ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`), and created an IAM Role for EC2 with that policy attached.
- **Correction from an earlier pass:** this week's plan originally excluded `gym-service`/`payment-service` because they had no production Dockerfile at the time (see the struck-through Risk row in [Proposal §22](../../2-Proposal/#22-risks)). Both gained one since, so this week's scope was updated to build/push all eight MVP images, not six.

### Results Achieved

- ECR repositories created and populated for MVP services.
- IAM Role for EC2 defined with least-privilege ECR pull permissions.
- TODO: Record final image tags used for the first deployment.

### Difficulties

- Authentication errors on first `docker login` attempt to ECR (expired token / wrong region).

### How It Was Resolved

- Re-ran `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com` and confirmed the AWS CLI profile/region matched the ECR repository's region.

### AWS Skills / Services Learned

- Amazon ECR repository creation, image lifecycle, and IAM least-privilege policy design for ECR pull access.

### Evidence Still Required

- TODO: Screenshot of ECR repositories with pushed images.
- TODO: Terminal output of `docker push` for each service.
- TODO: IAM Role/policy screenshot (with account ID redacted).

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Create ECR repositories | [TODO_DATE] | [TODO_DATE] | [Workshop 5.8](../../5-Workshop/5.8-ECR/) |
| 2 | Build, tag and push images | [TODO_DATE] | [TODO_DATE] | [Workshop 5.8](../../5-Workshop/5.8-ECR/) |
| 3 | Draft and attach IAM Role for EC2 | [TODO_DATE] | [TODO_DATE] | [Workshop 5.11](../../5-Workshop/5.11-IAM-Secrets/) |
| 4 | Verify images and permissions | [TODO_DATE] | [TODO_DATE] | — |

### Completion Checklist

- [ ] ECR repositories created for MVP services
- [ ] Images built, tagged and pushed
- [ ] IAM Role created with least-privilege ECR pull policy
- [ ] `gym-service`/`payment-service` images built and pushed alongside the rest of the MVP (scope correction documented, not silently changed)

### Related Workshop Section

- [5.8 ECR](../../5-Workshop/5.8-ECR/)
