---
title: "Blog 1: From Local Docker to Amazon ECR"
date: 2026-08-22
weight: 1
chapter: false
pre: " <b> 3.1. </b> "
---

## FROM LOCAL DOCKER TO AMAZON ECR – PREPARATION BEFORE DEPLOYING SYSTEM TO ECS

**Published:** August 22, 2026

**Blog URL:** https://www.facebook.com/share/p/1F8v6Qye3F/

**Hashtags:** #FCAJ #AWS #Docker #AmazonECR #AmazonECS #CloudComputing #FitnessAssistant

---

### Introduction

While researching deployment approaches for the Fitness Assistant project to the cloud, I came across an AWS article titled **"Automated software delivery using Docker Compose and Amazon ECS"**.

Initially, I was looking for this article to understand how a system running with Docker locally would be deployed on AWS, especially when using Amazon ECS.

At first, I thought the flow would be quite simple: if you have Docker, just move the containers to ECS and run them. But after reading more carefully, I realized that before moving to ECS, there's a quite important step that I hadn't really paid much attention to before: **Docker image management**.

### Real-world Problem

Fitness Assistant currently isn't just a single application. The project is split into multiple components:
- frontend
- gateway
- auth-service
- user-service
- fitness-service
- ai-service
- payment-service
- gym-service

In the local environment, I can run and test these services relatively easily. But when thinking about moving the system to AWS, I started facing a question:

**If the services are on my laptop, where will ECS get the application to run?**

A simple approach is to create EC2, SSH into the machine, clone the source code, install Docker, then build and run all containers directly on it. This approach is completely feasible.

But I realized that if done this way, the production server would have to handle quite many tasks. The server both contains source code, has to build the application, stores Docker images, and runs containers.

### Experiment Objectives

At this stage, my goal isn't to deploy the entire Fitness Assistant to Amazon ECS yet. I want to solve a smaller step first:

**How can each service of the project be packaged into a complete Docker image and stored on AWS?**

The flow I'm experimenting with is:

```
Source code → Dockerfile → docker build → Local Docker Image 
→ docker tag → docker push → Amazon ECR
```

Through this part, I want to check several issues:
- Can each service's Dockerfile build successfully?
- Does the image actually exist locally after building?
- What is the size of each image?
- How should images be versioned?
- How to move images from local machine to Amazon ECR?
- After pushing, how to verify the image on ECR is the one just built?

### Architecture Overview

After breaking down the problem, I started seeing more clearly the role of each component:

```
Developer
    ↓
Source Code
    ↓
Dockerfile
    ↓
Docker Build
    ↓
Docker Image
    ↓
Amazon ECR
    ↓
Amazon ECS
    ↓
Running Container
```

**Amazon ECR is not where applications run.** ECR is like a repository storing versions of container images.

For example, Fitness Assistant might have:
- `fitness-assistant/frontend:v1.0.0`
- `fitness-assistant/auth-service:v1.0.0`
- `fitness-assistant/user-service:v1.0.0`

This way, building applications and running applications are separated into two clear parts.

### Docker and Amazon ECR Experiment Flow

First, I prepared production Dockerfiles for each service. Then ran:

```bash
docker build
```

to create images on the local machine. After building, I used:

```bash
docker images
```

to check if images were actually created and what the size of each image is.

This is when I realized something quite simple but I hadn't paid much attention to before: **"Build successful" message doesn't mean the image is ready for production.**

For example, with the frontend, some Vite environment variables are included during the build process. If the API URL during build is still `localhost`, Docker can still build the image successfully. But that image clearly isn't suitable to run in AWS environment yet.

After checking local images, I created corresponding Private Repositories on Amazon ECR. Next:

```bash
docker login
```

to give Docker access to ECR. Then I used:

```bash
docker tag
```

to attach ECR Repository URI to the image. Finally:

```bash
docker push
```

to upload the image to ECR.

After pushing, I didn't just stop at seeing the terminal report success but continued to check directly on AWS Console. There I could see:
- Image tag
- Image digest
- Image size
- Time image was pushed

### Why Not Deploy Source Code Directly to EC2?

This was also a question I asked during the research process. If EC2 is also a server, why not simply create an EC2 instance, install Docker, and run Fitness Assistant directly on it?

From my understanding, this approach isn't wrong. For a small project, one server, and not many users yet, it's completely possible:

```
Source code → EC2 → Docker → Application
```

But with Fitness Assistant currently having many services, I want to separate responsibilities more clearly. If building directly on EC2, then EC2 is both where source code is received, images are built, and containers are run.

With the approach I'm researching:

```
Source code → Docker image → Amazon ECR → Amazon ECS
```

each part has its own responsibility:
- Docker packages the application
- ECR stores images
- ECS manages containers

### What I Found Most Interesting

What I found most interesting isn't the `docker push` command. But rather how I started viewing Docker images differently.

Previously, I mainly used Docker to:
- build images
- run containers
- test applications locally

But when introducing ECR into the flow, **Docker images started looking more like packaged versions of the application**.

For example:
- `auth-service:v1.0.0`
- `auth-service:v1.0.1`

These two versions can coexist on ECR. This helps me clearly know what versions the system has instead of overwriting the old image with each update.

### Some Notes I Learned from Testing

1. **Don't consider a Docker image complete just because `docker build` doesn't error.** Need to recheck the configuration inside the image.

2. **Don't include sensitive files in images.** Files like `.env`, credentials, API Keys shouldn't appear inside Docker images. Therefore `.dockerignore` needs to be checked.

3. **Image versioning.** If all images use `latest`, after a while it will be quite difficult to know which image corresponds to which version of source code.

4. **Must verify images after pushing.** Shouldn't just see `docker push` succeed and conclude the entire test has PASSED.

### Personal Perspective

Before reading the AWS article, I thought quite simply that if the application was containerized, the next step was just finding a place on AWS to run containers.

But after analyzing the article's flow, I realized **between source code and a container running on cloud, there's a quite important step which is container image management**.

This is also why I didn't want to go straight to ECS. If deploying frontend, gateway and many backend services to ECS immediately while Dockerfiles still have issues, then I would have to debug Docker, ECR, ECS, networking, load balancer and many other components at the same time.

Instead, I chose to do it step by step:
1. First ensure: `Source code → Docker image` works correctly
2. Then: `Docker image → Amazon ECR` works correctly
3. When these two parts are stable, continue to: `Amazon ECR → Amazon ECS`

### Conclusion

After this experiment, what I understand more clearly isn't just how to use Amazon ECR. More importantly, I started seeing clearly the role of Docker images in the process of moving applications from local to cloud.

- **Docker** helps me package applications
- **Amazon ECR** helps me store and manage those images
- **Amazon ECS** will be the next step to use these images and operate containers on AWS

What I learned most from this process is **don't try to deploy the entire architecture from the start**. Breaking down each problem, testing each step and understanding clearly the role of each service helps me identify errors more easily and also understand AWS architecture better.

Currently, I'm continuing to refine Docker images of services in Fitness Assistant and test them on Amazon ECR. After this part is stable, my next step will be researching how images in ECR are used to deploy services to Amazon ECS.

### Reference Links

- **AWS Containers Blog** – Automated software delivery using Docker Compose and Amazon ECS: https://aws.amazon.com/blogs/containers/automated-software-delivery-using-docker-compose-and-amazon-ecs
- **Amazon ECR Documentation**: https://docs.aws.amazon.com/ecr/
- **Amazon ECS Documentation**: https://docs.aws.amazon.com/ecs/

---

**Shared on Facebook:** https://www.facebook.com/share/p/1F8v6Qye3F/
