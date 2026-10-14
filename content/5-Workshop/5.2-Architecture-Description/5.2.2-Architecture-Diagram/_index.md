---
title: "5.2.2 Architecture Diagram"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

The diagrams below are rendered directly from this report's source (Mermaid), so they stay in sync with the text rather than drifting from a separately exported image.

### Component diagram

{{< mermaid >}}
graph LR
    User[Browser]

    subgraph Edge ["Public AWS endpoints"]
        FE["Amazon S3<br/>static website"]
        GW["API Gateway<br/>HTTP API"]
    end

    subgraph VPC ["VPC fitness-assistant-dev-vpc, ap-southeast-1"]
        subgraph Public ["Public subnets"]
            ALB["Chat ALB<br/>HTTP 80"]
            NAT["NAT Gateway"]
        end
        subgraph Private ["Private app subnets"]
            L["Lambda HTTP functions<br/>Auth, User, Fitness, Gym, Payment, AI"]
            J["Lambda jobs functions"]
            W["Lambda AI Worker"]
            C["ECS Fargate<br/>Chat Service, port 3005"]
            VPCE["Interface VPC endpoints<br/>Secrets Manager, OpenSearch"]
        end
        subgraph DB ["Private DB subnets"]
            A[("Aurora PostgreSQL Serverless v2<br/>7 logical databases")]
        end
    end

    SQS[["Amazon SQS<br/>ai-tasks + DLQ"]]
    EB[["EventBridge Scheduler<br/>13 schedules"]]
    BR[["Amazon Bedrock<br/>Nova Pro, Cohere Embed"]]
    OS[("OpenSearch Serverless<br/>vector collection")]

    User --> FE
    User -->|REST with JWT| GW
    User -->|Socket.IO| ALB
    GW --> L
    GW -->|chat REST routes| ALB
    ALB --> C
    L --> A
    J --> A
    W --> A
    C --> A
    L -->|SendMessage| SQS
    SQS --> W
    EB --> J
    L --> NAT
    W --> NAT
    J --> NAT
    NAT --> BR
    L --> VPCE
    W --> VPCE
    J --> VPCE
    VPCE --> OS
{{< /mermaid >}}

### The three request paths

{{< mermaid >}}
graph LR
    subgraph P1 ["Core API path"]
        A1[Browser] --> B1[API Gateway]
        B1 --> C1["Service Lambda<br/>verifies the JWT"]
        C1 --> D1[(Aurora)]
        C1 -. direct invoke .-> E1[Other service Lambdas]
    end
    subgraph P2 ["Chat path"]
        A2[Browser] -->|Socket.IO| B2[Chat ALB]
        A2 -->|chat REST routes| G2[API Gateway]
        G2 --> B2
        B2 --> C2[ECS Fargate task]
        C2 --> D2[(Aurora chat DB)]
    end
    subgraph P3 ["Background path"]
        A3[EventBridge Scheduler] --> B3[Jobs Lambdas]
        B3 --> D3[(Aurora)]
        A4[AI HTTP Lambda] --> Q4[[SQS]]
        Q4 --> B4[AI Worker]
        B4 --> M4[[Bedrock]]
    end
{{< /mermaid >}}

{{% notice note %}}
Everything except the S3 website, API Gateway, SQS, EventBridge, Bedrock and the OpenSearch collection runs inside `fitness-assistant-dev-vpc`. Lambda functions and the Chat task sit in the private app subnets; only the NAT Gateway and the Chat ALB are in public subnets; Aurora sits in DB subnets with no internet route. See [5.2.3 Main Request Flows](../5.2.3-Main-Request-Flows/) for the step-by-step walk-through behind each arrow.
{{% /notice %}}
