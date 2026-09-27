#!/usr/bin/env bash
# Reference example only — run ON the EC2 host after images have been
# pushed to ECR (see 5.8-ECR) and the .env file has been populated from
# AWS Secrets Manager (see 5.11-IAM-Secrets). Do not run unmodified.
set -euo pipefail

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID before running this script}"
: "${AWS_REGION:?Set AWS_REGION before running this script}"
: "${IMAGE_TAG:?Set IMAGE_TAG before running this script}"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker compose -f docker-compose.aws.example.yml pull
docker compose -f docker-compose.aws.example.yml up -d

echo "Deployment triggered. Verify with: docker compose -f docker-compose.aws.example.yml ps"
