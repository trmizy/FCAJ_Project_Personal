---
title: "5.9 EC2 Deployment"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 5.9. </b> "
---

{{% notice warning %}}
Do not assume a Free Tier `t3.micro` (1 vCPU, 1 GiB RAM) is sufficient for this workload. The AI service depends on Ollama (self-hosted LLM) and Qdrant, both of which have real CPU/RAM requirements. Size the instance based on what is actually being run, and record actual measured usage here once available.
{{% /notice %}}

### Choosing an AMI and Instance Type

- **AMI:** Ubuntu Server LTS (recommended for Docker Engine compatibility and long-term support).
- **Instance type:** TODO — must be chosen based on which containers actually run on this host. If `ai-service` + Ollama + Qdrant run alongside the rest of the MVP stack, a minimum of 4 vCPU / 8 GiB RAM is a more realistic starting point than a Free Tier instance; this must be verified against real measured usage, not assumed.
- If budget constraints require a smaller instance, consider running the AI stack (Ollama + Qdrant) separately, or deferring `ai-service` from the initial deployment and noting it as a follow-up.

### EBS Volume

TODO: record the actual root volume size chosen (default Ubuntu AMI volumes are often too small once several Docker images are pulled — Ollama model weights alone can be several GB).

### IAM Role

Attach the IAM Role created in [5.11 IAM and Secrets](../5.11-IAM-Secrets/), granting least-privilege access to ECR, CloudWatch, and Secrets Manager. Do not place long-lived AWS access keys on the instance.

### Security Group

Attach the EC2 Security Group from [5.6 Network Infrastructure](../5.6-Network-Infrastructure/) (80/443 open, SSH restricted to a specific IP).

### User Data (Optional)

An EC2 user data script can automate Docker installation on first boot. TODO: record the actual user data script used, if any, or mark this step as done manually.

### Connecting to the Instance

Prefer **AWS Systems Manager Session Manager** over direct SSH where possible, since it avoids opening port 22 to the internet entirely. If SSH is used, it must be restricted to a specific IP per the Security Group design.

### Install Docker

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

### Login to ECR and Pull Images

```bash
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fitness-assistant/auth-service:${IMAGE_TAG}
# repeat per MVP service
```

### Create the Environment File Securely

Do not write secrets directly into a plaintext `.env` file checked into any repository. Retrieve them from AWS Secrets Manager at deploy time (see [5.11 IAM and Secrets](../5.11-IAM-Secrets/)) and write them to a `.env` file that is `chmod 600` and excluded from any Git repository on the host.

### Run Docker Compose (Production Topology)

See [`/files/docker/docker-compose.aws.example.yml`](/files/docker/docker-compose.aws.example.yml) for a reference topology describing how the MVP services connect on EC2, with `DATABASE_URL` pointing at the Amazon RDS endpoint from [5.7 RDS PostgreSQL](../5.7-RDS-PostgreSQL/) instead of a local Postgres container.

```bash
docker compose -f docker-compose.aws.example.yml up -d
```

### Reverse Proxy

Install Nginx on the host as a reverse proxy in front of the frontend and application gateway containers. TODO: attach the actual Nginx site configuration used once finalized.

### Health Check

```bash
curl -I http://localhost/
curl http://localhost:3000/health
```

### Verify Containers

```bash
docker compose -f docker-compose.aws.example.yml ps
docker stats --no-stream
```

TODO: record actual CPU/RAM usage under load, to validate or correct the instance-sizing decision above.

### Verify Frontend / API

Open `http://<EC2_PUBLIC_IP_OR_DNS>/` in a browser and confirm the frontend loads and can reach the API through the gateway.

### Reboot Persistence

Ensure the Docker daemon and the Compose stack restart automatically after an instance reboot (`docker` service enabled via systemd, and `restart: unless-stopped` policies in the Compose file).

### Troubleshooting

See [5.15 Troubleshooting](../5.15-Troubleshooting/) for `502 Bad Gateway`, "container exited", "port already in use", and related EC2/Docker issues.
