---
title: "Blog 1: Containerizing Microservices and ECR"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 3.1. </b> "
---

## Containerizing Microservices and Storing Images in Amazon ECR

**Status:** Draft

**Publish date:** [TODO_DATE]

**Post URL:** [TODO_BLOG_URL]

**Cover image:** TODO screenshot — not yet captured.

### Objective

Explain how the Fitness Assistant microservices — which already ship with multi-stage Dockerfiles for most services (`frontend/web`, `backend/gateway`, `auth-service`, `user-service`, `fitness-service`, `chat-service`) — were adapted for AWS deployment, and how the resulting images were pushed to Amazon ECR.

### Summary

Most services in the `fitness-assistant` monorepo already have a production-oriented multi-stage Dockerfile (`base` → `deps` → `builder` → `runner`, using `node:20-alpine` and pnpm workspaces). This post walks through validating those existing Dockerfiles, writing a production Dockerfile for the two services that only ship a `Dockerfile.dev` (`gym-service`, `payment-service`) where needed for the deployment scope, and pushing the resulting images to per-service Amazon ECR repositories.

### Main Content

- Reviewing the existing multi-stage Dockerfile pattern used across the monorepo and confirming which services already have a production build.
- Building each image locally with `docker build` and checking the final image size.
- Creating one Amazon ECR repository per service, matching the naming convention used in [Workshop 5.8](../../5-Workshop/5.8-ECR/).
- Authenticating Docker to ECR and pushing each image with an explicit tag (not just `latest`).
- TODO: Insert real command output, image size numbers, and screenshots once the build is executed and verified.

### What I Learned

- The difference between a development Dockerfile (bind-mounted source, hot reload) and a production Dockerfile (built artifacts only, smaller final image, no source code needed at runtime).
- Why relying on `latest` as the only tag makes rollbacks harder, and how to design a simple tagging strategy instead.

{{% notice warning %}}
This post must not claim a specific image size, build time, or ECR repository URL until those numbers are captured from a real build. Replace all TODOs before publishing.
{{% /notice %}}
