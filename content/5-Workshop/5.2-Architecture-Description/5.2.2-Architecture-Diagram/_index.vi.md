---
title: "5.2.2 Sơ đồ kiến trúc"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

Các sơ đồ dưới đây được render trực tiếp từ source của báo cáo (Mermaid), nên luôn đồng bộ với nội dung text thay vì bị lệch so với một ảnh export riêng.

### Sơ đồ thành phần

{{% mermaid %}}
flowchart LR
    subgraph Internet
        User[Browser]
    end

    subgraph S3["Amazon S3 — frontend tĩnh"]
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

### Tổng quan luồng request

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
Mọi thành phần trong cả hai sơ đồ đều chạy trong `fitness-assistant-dev-vpc` tại `ap-southeast-1` — luồng Chat và luồng Core API dùng chung VPC và cluster Aurora, nhưng đi qua compute khác nhau (ECS Fargate vs. Lambda) và một load balancer khác ở phía trước. Xem [5.2.3 Main Request Flows](../5.2.3-Main-Request-Flows/) để biết chi tiết từng bước phía sau mỗi mũi tên ở trên.
{{% /notice %}}

Phiên bản vẽ tay của sơ đồ này (source draw.io, cho ai muốn chỉnh sửa trực quan thay vì generate lại từ Mermaid) vẫn còn TODO — theo dõi như việc cần làm tiếp theo, không chặn báo cáo này.
