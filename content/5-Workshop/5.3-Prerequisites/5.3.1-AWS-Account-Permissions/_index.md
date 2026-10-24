---
title: "AWS account and permissions"
date: 2026-07-15
weight: 1
chapter: false
pre: " <b> 5.3.1. </b> "
---

#### AWS account

All resources live in a single AWS account used only for this project's DEV environment. Every resource is named with the `fitness-assistant-dev-` prefix (and tagged `project=fitness-assistant`, `environment=dev` where the console offers tags), which makes the clean-up in [5.7](../../5.7-Cleanup/) a matter of filtering by name.

#### Console identity

The deployment was performed from the AWS Management Console with an IAM user (not the root user). That identity needs permission to create and configure the services used in this workshop:

| Area | Services |
|---|---|
| Compute | AWS Lambda, Amazon ECS (Fargate), Amazon ECR |
| API and networking | Amazon API Gateway (HTTP API), Elastic Load Balancing (ALB), Amazon VPC (subnets, route tables, NAT/Internet Gateway, security groups, VPC endpoints) |
| Data | Amazon Aurora PostgreSQL, Amazon S3, AWS Secrets Manager, Amazon OpenSearch Serverless |
| Messaging and scheduling | Amazon SQS, Amazon EventBridge Scheduler |
| AI | Amazon Bedrock |
| Security and observability | AWS IAM (roles and inline policies), Amazon CloudWatch Logs |

{{% notice note %}}
The application itself never runs with these console permissions. Every Lambda function and ECS task gets its own execution role with an inline policy scoped to the exact secrets, queues and functions it uses — see [5.2.5 Security and IAM](../../5.2-Architecture-Description/5.2.5-Security-IAM/).
{{% /notice %}}

#### Amazon Bedrock model access (one-time)

The AI service uses two Bedrock models:

| Purpose | Model | Model ID used by the code |
|---|---|---|
| Chat and vision | Amazon Nova Pro (APAC cross-region inference profile) | `apac.amazon.nova-pro-v1:0` |
| Embeddings (1024 dimensions) | Cohere Embed Multilingual v3 | `cohere.embed-multilingual-v3` |

Cohere is a third-party model offered through AWS Marketplace, so its subscription/EULA has to be accepted once from the console by an administrator. The Lambda runtime roles are deliberately **not** given `aws-marketplace:*` permissions to do this themselves. No API key is needed for either model — the Lambdas call Bedrock with their IAM role.

#### Payment provider credentials

The Payment service is configured with `PAYMENT_PROVIDER=VNPAY`. Provider credentials (VNPAY terminal code and hash secret, and MoMo / PayOS / ZaloPay keys when they are added) are entered only once a real sandbox credential exists, and they are never copied into chat, documentation or source control.
