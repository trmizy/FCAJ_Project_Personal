#!/usr/bin/env bash
# Reference example only. Requires the AWS CLI to be configured with
# credentials that have ecr:GetAuthorizationToken permission.
set -euo pipefail

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID before running this script}"
: "${AWS_REGION:?Set AWS_REGION before running this script}"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Logged in to ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
