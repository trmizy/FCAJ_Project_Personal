---
title: "5.2.2 Architecture Diagram"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

The diagrams below are rendered directly from this report's source (Mermaid), so they stay in sync with the text rather than drifting from a separately exported image. They show the designed, target architecture for this project: a fully serverless backend behind a REST API, with CI/CD and a full monitoring stack as part of the standard design rather than an afterthought. [5.4 Deployment Guide](../../5.4-Deployment-Guide/) and [5.5.5 Validation status and open items](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) say exactly which of these pieces are confirmed running in the DEV environment today, and [5.2.1](../5.2.1-Architecture-Overview/) covers how the deployment arrived at its current state.

### Component diagram

{{< mermaid >}}
graph LR
    U1[Mobile App]
    U2[Web Browser]
    U3["Admin Portal"]

    subgraph Edge ["Edge and global"]
        R53["Route 53<br/>DNS"]
        WAF["AWS WAF<br/>optional"]
        CF["Amazon CloudFront<br/>CDN"]
        FE["Amazon S3<br/>frontend bucket"]
    end

    GW["Amazon API Gateway<br/>REST API"]

    subgraph Backend ["Serverless backend, AWS Lambda"]
        AU["Auth"]
        US["User"]
        FI["Fitness"]
        PA["Payment"]
        GY["Gym"]
        AIS["AI"]
    end

    subgraph VPC ["VPC 10.0.0.0/16, ap-southeast-1, multi-AZ"]
        ENI["Private app subnets<br/>Lambda ENI attachment"]
        PROXY["Amazon RDS Proxy<br/>optional"]
        DBA[("Aurora Serverless v2<br/>Primary")]
        DBB[("Aurora Serverless v2<br/>Replica")]
    end

    subgraph Shared ["Shared serverless services"]
        UP["Amazon S3<br/>uploads bucket"]
        SEC["AWS Secrets Manager"]
        CW["Amazon CloudWatch"]
    end

    EB["Amazon EventBridge<br/>schedules and events"]

    subgraph Async ["Async and AI processing"]
        SQS1[["Amazon SQS<br/>job queue"]]
        WRK["Lambda Worker"]
        BR[["Amazon Bedrock<br/>LLM provider"]]
        VEC[("OpenSearch Serverless<br/>vector store")]
    end

    U1 --> CF
    U2 --> CF
    U3 --> CF
    R53 -.-> CF
    R53 -.-> GW
    CF --> WAF
    WAF --> FE
    U1 --> GW
    U2 --> GW
    U3 --> GW

    GW --> AU
    GW --> US
    GW --> FI
    GW --> PA
    GW --> GY
    GW --> AIS

    AU --> ENI
    US --> ENI
    FI --> ENI
    PA --> ENI
    GY --> ENI
    AIS --> ENI
    ENI --> PROXY
    PROXY --> DBA
    DBA -. replication .-> DBB

    AU --> SEC
    US --> UP
    AIS -->|enqueue| SQS1
    SQS1 --> WRK
    WRK --> BR
    WRK --> VEC
    EB -.-> WRK
    ENI --> CW
{{< /mermaid >}}

### DevOps and monitoring

{{< mermaid >}}
graph LR
    subgraph DevOps ["DevOps and infrastructure as code"]
        GH["GitHub<br/>source code"]
        GA["GitHub Actions<br/>CI/CD pipeline"]
        OIDC["OIDC<br/>authentication"]
        TF["Terraform<br/>infrastructure as code"]
    end
    AWSR["AWS resources<br/>provisioned"]

    GH --> GA
    GA --> OIDC
    OIDC --> TF
    TF --> AWSR

    subgraph Monitoring ["Monitoring, alerting and observability"]
        CW2["Amazon CloudWatch<br/>logs and metrics"]
        AL["CloudWatch Alarms<br/>notifications"]
        SNS1["Amazon SNS<br/>email alerts"]
        DASH["CloudWatch Dashboards"]
        XR["AWS X-Ray<br/>tracing, optional"]
        BUD["AWS Budgets<br/>cost alerts"]
        CE["AWS Cost Explorer<br/>cost analysis"]
    end

    AWSR --> CW2
    CW2 --> AL
    AL --> SNS1
    CW2 --> DASH
    AWSR -. optional .-> XR
    AWSR --> BUD
    AWSR --> CE
{{< /mermaid >}}

{{% notice note %}}
Everything in the component diagram outside the Edge and DevOps groups runs inside a VPC spread across multiple Availability Zones, with no EC2 instances or containers in this design. The DevOps and monitoring pieces (GitHub Actions, Terraform, CloudWatch Alarms, SNS, Dashboards, X-Ray, Budgets) describe the intended operating model; [5.5.5](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) is the page to check for what has actually been built and confirmed so far.
{{% /notice %}}
