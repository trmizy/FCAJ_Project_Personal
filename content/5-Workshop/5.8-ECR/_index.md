---
title: "5.8 ECR"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 5.8. </b> "
---

### Shell Variables

Use environment variables instead of hard-coding account details anywhere in scripts or documentation:

```bash
export AWS_ACCOUNT_ID=<YOUR_AWS_ACCOUNT_ID>
export AWS_REGION=<YOUR_AWS_REGION>
export IMAGE_TAG=$(date +%Y-%m-%d)
```

### Repositories to Create (MVP scope)

One Amazon ECR repository per MVP service:

```bash
for ECR_REPOSITORY in frontend gateway auth-service user-service fitness-service ai-service payment-service gym-service; do
  aws ecr create-repository \
    --repository-name "fitness-assistant/${ECR_REPOSITORY}" \
    --region "$AWS_REGION" \
    --image-scanning-configuration scanOnPush=true
done
```

{{% notice note %}}
`chat-service` is intentionally excluded here — it's out of MVP scope (see [Proposal §9](../../2-Proposal/#9-out-of-mvp-scope)). `gym-service` and `payment-service` ARE included: both gained a production Dockerfile since this section was first drafted (see [5.5 Production Containers](../5.5-Production-Containers/)).
{{% /notice %}}

### ECR Login

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
```

### Build, Tag, Push

```bash
docker build -t fitness-assistant/auth-service:${IMAGE_TAG} \
  -f backend/services/auth-service/Dockerfile .

docker tag fitness-assistant/auth-service:${IMAGE_TAG} \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fitness-assistant/auth-service:${IMAGE_TAG}

docker push \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fitness-assistant/auth-service:${IMAGE_TAG}
```

Repeat per MVP service, adjusting the Dockerfile path and build context (see the build-context note in [5.5 Production Containers](../5.5-Production-Containers/)).

### Verify

```bash
aws ecr list-images --repository-name fitness-assistant/auth-service --region "$AWS_REGION"
```

TODO: attach a real screenshot of the ECR console showing pushed images once verified.

### Image Naming Convention

`fitness-assistant/<service-name>:<YYYY-MM-DD>` and an additional `:latest` tag for convenience. Do not rely on `:latest` alone for rollback purposes.

### Lifecycle Policy

Recommended, to control storage cost: expire untagged images after a set number of days, and keep only the most recent N tagged images per repository. TODO: apply and record the actual lifecycle policy JSON used, once decided.

### Troubleshooting

| Error | Likely Cause | Check | Fix |
| --- | --- | --- | --- |
| `no basic auth credentials` | ECR login expired or skipped | `docker info` shows no ECR registry logged in | Re-run `aws ecr get-login-password ... | docker login ...` |
| `repository does not exist` | Repository not created yet, or wrong region/account in the URI | `aws ecr describe-repositories` | Create the repository or correct the URI |
| `denied: requested access to the resource is denied` | IAM identity lacks `ecr:*` permissions, or wrong account ID in the image tag | Compare IAM policy against [5.11 IAM and Secrets](../5.11-IAM-Secrets/) | Fix the IAM policy or the account ID in the tag |
