---
title: "5.2.2 Sơ đồ kiến trúc"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

Các sơ đồ dưới đây được render trực tiếp từ source của báo cáo (Mermaid), nên luôn đồng bộ với nội dung thay vì bị lệch so với một ảnh export riêng. Chúng thể hiện kiến trúc được thiết kế, mục tiêu của dự án: một backend hoàn toàn serverless phía sau REST API, với CI/CD và một bộ monitoring đầy đủ nằm trong thiết kế chuẩn thay vì được bổ sung sau. [5.4 Hướng dẫn triển khai](../../5.4-Deployment-Guide/) và [5.5.5 Trạng thái kiểm thử và việc còn mở](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) cho biết chính xác phần nào trong số này đã chạy thật trong môi trường DEV hiện nay, còn [5.2.1](../5.2.1-Architecture-Overview/) nói về cách quá trình triển khai đi đến trạng thái hiện tại.

### Sơ đồ thành phần

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

### DevOps và monitoring

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
Mọi thành phần trong sơ đồ thành phần, ngoại trừ nhóm Edge và DevOps, đều chạy trong một VPC trải trên nhiều Availability Zone, không có EC2 instance hay container nào trong thiết kế này. Các phần DevOps và monitoring (GitHub Actions, Terraform, CloudWatch Alarms, SNS, Dashboards, X-Ray, Budgets) mô tả mô hình vận hành dự kiến; xem [5.5.5](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) để biết phần nào thực sự đã được xây dựng và xác nhận cho đến nay.
{{% /notice %}}
