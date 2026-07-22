---
title: "5.15 Troubleshooting"
date: 2026-07-15
weight: 15
chapter: false
pre: " <b> 5.15. </b> "
---

| Error | Likely Cause | Check Command | How to Fix |
|---|---|---|---|
| `no basic auth credentials` (ECR) | Docker login to ECR expired or was never run | `docker info` / retry login | Re-run `aws ecr get-login-password ...` piped into `docker login` |
| `Error response from daemon: pull access denied` / image not found | Wrong ECR repository URI, wrong tag, or image never pushed | `aws ecr list-images --repository-name <repo>` | Verify the exact repository name/tag from [5.8 ECR](../5.8-ECR/) |
| Container exited immediately | Startup crash — often a missing/incorrect environment variable | `docker compose logs <service>` | Compare the service's required env vars (see `.env.example` in source) against what was actually injected |
| Port already in use | Another process or container already bound to the port | `sudo lsof -i :<port>` or `docker ps` | Stop the conflicting process/container, or change the published port |
| Frontend cannot reach the backend | `VITE_API_URL` baked in at build time does not match the deployed backend URL | Inspect the built frontend bundle / check the build ARGs used | Rebuild the frontend image with the correct `VITE_API_URL`/`VITE_SOCKET_URL`/`VITE_CHAT_WS_URL` build ARGs |
| CORS error in the browser console | `CORS_ORIGIN` on the gateway/services does not match the frontend's actual origin | Check the `CORS_ORIGIN` env var | Set `CORS_ORIGIN` to the exact scheme+host+port serving the frontend |
| RDS connection timeout | Security Group does not allow the EC2 Security Group on port 5432, or wrong subnet routing | `telnet <rds-endpoint> 5432` from the EC2 host | Fix the RDS Security Group inbound rule per [5.6 Network Infrastructure](../5.6-Network-Infrastructure/) |
| `password authentication failed` (Postgres) | Wrong credentials, or `DATABASE_URL` points at the wrong database name | Re-check the value pulled from Secrets Manager | Correct the credential/secret; never hard-code a fallback password |
| Prisma migration error | Migration already partially applied, or schema drift between environments | `pnpm exec prisma migrate status` | Resolve drift per Prisma's guidance; do not hand-edit the database schema outside of migrations |
| Wrong Security Group | Rule references a CIDR instead of a Security Group ID, or the wrong Security Group is attached | Review the actual attached Security Group in the console | Re-attach the correct Security Group per [5.6 Network Infrastructure](../5.6-Network-Infrastructure/) |
| EC2 out of memory | Ollama/Qdrant + the rest of the MVP stack exceed the instance's RAM | `docker stats`, `free -h` | Resize the instance per the sizing warning in [5.9 EC2 Deployment](../5.9-EC2-Deployment/) |
| Disk full | Docker images/volumes accumulated without cleanup, or Ollama model weights consumed the root volume | `df -h`, `docker system df` | `docker system prune` (carefully), or increase the EBS volume size |
| No logs appearing in CloudWatch | CloudWatch Agent not installed/configured, or IAM role missing `logs:*` permissions | `sudo systemctl status amazon-cloudwatch-agent` | Reinstall/reconfigure the Agent; verify the IAM policy from [5.11 IAM and Secrets](../5.11-IAM-Secrets/) |
| SNS email not received | Subscription not confirmed, or the alarm never actually entered `ALARM` state | `aws sns list-subscriptions-by-topic` | Confirm the subscription; manually test with `aws cloudwatch set-alarm-state` |
| Health check failed | The container's health check command fails even though the process is running (e.g. missing `wget`/`curl` in a minimal image) | `docker inspect --format='{{json .State.Health}}' <container>` | Fix the health check command to match what is actually installed in the image |
| `502 Bad Gateway` | Reverse proxy (Nginx) cannot reach the upstream application gateway container | `docker compose ps`, Nginx error log | Confirm the upstream container is running and the proxy `upstream`/`proxy_pass` address is correct |
