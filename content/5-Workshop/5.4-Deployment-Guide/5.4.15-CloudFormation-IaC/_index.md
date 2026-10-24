---
title: "5.4.15 Infrastructure as code with CloudFormation"
date: 2026-10-23
weight: 15
chapter: false
pre: " <b> 5.4.15. </b> "
---

Most of the resources in the earlier steps were first created by hand in the console so that every setting could be explained. The parts that are cheap to describe and risky to click again are also kept as **CloudFormation templates**, so they can be recreated, reviewed and changed through a change set. This step lists the stacks, the files to download, and how to deploy one.

#### 1. Stacks and attached files

| Stack in the account | Template (download) | What it creates |
|---|---|---|
| `fitness-assistant-dev-app-monitoring` | [app-monitoring.yaml](../../../files/cloudformation/app-monitoring.yaml) | 9 CloudWatch alarms and the SNS topic `fitness-assistant-dev-app-alerts` ([5.5.5](../../5.5-Test-Validation/5.5.6-Monitoring-Alerting/)) |
| `fitness-assistant-dev-frontend-cdn` | [frontend-cdn.yaml](../../../files/cloudformation/frontend-cdn.yaml) | The CloudFront distribution and its Origin Access Control for the frontend bucket |
| `gymini-dev-on-demand` | [dev-on-demand.yaml](../../../files/cloudformation/dev-on-demand.yaml) | The hourly-billed parts that are switched on and off per session: NAT Gateway, Chat load balancer, listener, target group and VPC endpoints |
| `fitness-assistant-dev-cicd-iam` | [ci-cd-oidc.yaml](../../../files/cloudformation/ci-cd-oidc.yaml) | The five least-privilege IAM roles that GitHub Actions assumes through OIDC |
| `fitness-assistant-dev-api-gateway` | managed by the infrastructure workflows | The HTTP API with 254 resources (routes, integrations, stage); too large to attach, changed only through reviewed change sets ([5.4.16](../5.4.16-GitHub-Actions-Workflows/)) |

{{% notice note %}}
The attached copies replace the AWS account ID and the subnet IDs with placeholders (`123456789012`, `subnet-0123456789abcdef0`). Replace them with your own values before deploying. No password, key or e-mail address is stored in any template.
{{% /notice %}}

#### 2. What the templates do and do not contain

- **Parameters instead of hard-coded values.** The templates reference existing resources (VPC, subnets, Aurora cluster, API ID, bucket name) through parameters, so the same template works in another account after the values are changed.
- **No credentials.** The monitoring template creates the SNS topic but no subscription. The e-mail is subscribed afterwards with the command shown in the stack output, so no address is committed anywhere.
- **Least privilege by design.** In the OIDC template each role trusts exactly one GitHub environment (`dev`, `dev-infra`, `dev-infra-plan`) and the plan role has an explicit deny on executing change sets. There is no static access key and no administrator access.
- **Separation of lifetimes.** The on-demand stack holds only what costs money while idle. The VPC, subnets, Aurora, Lambda functions and secrets live outside it, so switching the environment off never touches them.

#### 3. Deploy one stack

Example with the monitoring template. Replace the placeholders, then deploy through a change set so the result can be reviewed before it is applied:

```text
aws cloudformation deploy \
  --region ap-southeast-1 \
  --stack-name fitness-assistant-dev-app-monitoring \
  --template-file app-monitoring.yaml \
  --parameter-overrides ApiId=<your-api-id> AuroraClusterIdentifier=<your-aurora-cluster> \
  --no-execute-changeset
```

Review the change set in the console (**CloudFormation → Stacks → the stack → Change sets**), then execute it. After the stack is created, subscribe your own e-mail address to the topic with the command in the **Outputs** tab (`SubscribeCommand`) and confirm the message you receive.

The OIDC template creates IAM roles with fixed names, so deploying it needs the capability flag:

```text
aws cloudformation deploy --template-file ci-cd-oidc.yaml --stack-name fitness-assistant-dev-cicd-iam --capabilities CAPABILITY_NAMED_IAM --no-execute-changeset
```

#### 4. Check the result

Open **CloudFormation → Stacks**. Each stack must be `CREATE_COMPLETE` or `UPDATE_COMPLETE`. Open a stack and check three tabs: **Resources** (every resource in `CREATE_COMPLETE`), **Outputs** (the IDs and ARNs the other steps use) and **Events** (a clean history with no rollback).

To compare the live stack with the template, use **Stack actions → Detect drift**. A stack whose status is `IN_SYNC` has no change made outside CloudFormation. The API Gateway stack is checked this way before every infrastructure change ([5.4.13](../5.4.13-CD-Pipeline-Activation/)).

#### Screens of the console

The screens below were captured in the account. The Create stack wizard was walked through up to the final review and then cancelled, so no stack was created.

1. Open **CloudFormation → Stacks** and click the stack name (1).

![CloudFormation stack list with the monitoring stack marked](/images/workshop/console/cfn-1-stack-list.jpg)
*The account has 5 project stacks, all in CREATE_COMPLETE or UPDATE_COMPLETE.*

2. Open the **Resources** tab (1). Every resource must show **CREATE_COMPLETE** (2).

![Resources tab of the monitoring stack](/images/workshop/console/cfn-2-resources.jpg)
*The 10 resources of the monitoring stack: 9 alarms and the SNS topic.*

3. Open the **Outputs** tab (1) to read the values the other steps use, including the subscribe command.

![Outputs tab of the monitoring stack](/images/workshop/console/cfn-3-outputs.jpg)
*Outputs of the monitoring stack (account ID hidden).*

4. To create a stack from a template file, click **Create stack** and choose **With new resources (standard)** (1).

![Create stack menu with the standard option marked](/images/workshop/console/cfn-4-create-menu.jpg)
*The Create stack menu.*

5. In step 1 choose **Upload a template file** (1) and pick the YAML file downloaded above (2). The console uploads it and shows its address. Click **Next** (3).

![Step 1 of the wizard with the template file uploaded](/images/workshop/console/cfn-6-upload.jpg)
*Step 1: the template file is uploaded.*

6. In step 2 type the **Stack name** (1). The template parameters appear with their default values (2); keep them or change them. Click **Next** (3).

![Step 2 of the wizard with the stack name and the two parameters](/images/workshop/console/cfn-7-details.jpg)
*Step 2: stack name and parameters.*

7. Step 3 holds the optional settings (tags, service role, rollback behavior, notifications). Keep **Roll back all resources** (1) and click **Next** at the bottom of the page.

![Step 3 of the wizard with the stack options](/images/workshop/console/cfn-8-options.jpg)
*Step 3: stack options.*

8. Step 4 shows a summary: the template (1) and the stack name and parameters (2). Read it before submitting.

![Review step with the template and the stack name](/images/workshop/console/cfn-9-review.jpg)
*Step 4: review.*

9. At the bottom, **Submit** creates the stack and **Cancel** leaves without creating anything. The screenshots here end with **Cancel** (1) because the monitoring stack already exists in the account; to create it for real, click **Submit** (2) and watch the **Events** tab until the status is **CREATE_COMPLETE**.

![End of the review step with the Cancel and Submit buttons](/images/workshop/console/cfn-10-submit.jpg)
*The Submit and Cancel buttons.*

#### 5. Clean-up

Delete a stack with **Delete**, or run `aws cloudformation delete-stack --stack-name <name>`. Delete the on-demand stack first when shutting everything down, because the other stacks do not depend on it. The order for the whole environment is in [5.7](../../5.7-Cleanup/).
