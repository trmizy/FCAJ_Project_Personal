---
title: "5.2.2 Architecture Diagram"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

The diagrams below are rendered directly from this report's source (Mermaid), so they stay in sync with the text rather than drifting from a separately-exported image.

### Component Diagram

{{% mermaid %}}
flowchart LR
    subgraph Internet
        User[Browser]
    end

    subgraph S3["Amazon S3 — static frontend"]
        FE[Frontend build]
    end

    subgraph APIGW["Amazon API Gateway"]
        GW[HTTP API]
    end

    subgraph VPC["VPC — fitness-assistant-dev-vpc"]
        subgraph Private["Private app subnets"]
            Auth[Auth Lambda]
            Usr[User Lambda]
            Fit[Fitness Lambda]
            Gym[Gym Lambda]
            Pay[Payment Lambda]
            AI[AI HTTP Lambda]
            AIW[AI Worker Lambda]
        end
        subgraph DBSub["Private DB subnets"]
            Aurora[("Aurora PostgreSQL Serverless\n7 logical databases")]
        end
        NAT[NAT Gateway]
    end

    subgraph ECS["ECS Fargate"]
        ALB[Application Load Balancer]
        Chat[Chat Service\nREST + Socket.IO]
    end

    Bedrock[[Amazon Bedrock\nNova Pro + Cohere embeddings]]
    EventBridge[[EventBridge / SQS]]

    User --> FE
    User --> GW
    User <-->|Socket.IO| ALB
    GW --> Auth & Usr & Fit & Gym & Pay & AI
    ALB --> Chat
    Auth & Usr & Fit & Gym & Pay & AI & AIW --> Aurora
    Chat --> Aurora
    Private --> NAT --> Internet
    AI --> Bedrock
    EventBridge --> AIW
{{% /mermaid %}}

### Request Path Overview

{{% mermaid %}}
flowchart LR
    A[Internet] --> B["S3 Frontend\nfitness-assistant-frontend-dev"]
    B --> C["API Gateway\nfitness-assistant-dev-api"]
    C --> D["Auth / User / Fitness /\nGym / Payment / AI Lambda"]
    D --> E["Aurora PostgreSQL\nfitness-assistant-dev-aurora"]

    A --> F["Chat ALB"]
    F --> G["ECS Fargate\nfitness-assistant-dev-chat-service"]
    G --> H["Aurora — Chat DB"]

    I["EventBridge / SQS"] --> J["AI Worker / Jobs Lambda"]
    J --> E
{{% /mermaid %}}

{{% notice note %}}
All components in both diagrams run inside `fitness-assistant-dev-vpc` in `ap-southeast-1` — the Chat path and the Core API path share the same VPC and Aurora cluster, but reach it through different compute (ECS Fargate vs. Lambda) and a different load balancer in front. See [5.2.3 Main Request Flows](../5.2.3-Main-Request-Flows/) for the step-by-step walk-through behind each arrow above.
{{% /notice %}}

A hand-drawn version of this diagram (draw.io source, for anyone who wants to edit it visually rather than regenerate it from Mermaid) is still TODO — tracked as a follow-up, not blocking this report.
