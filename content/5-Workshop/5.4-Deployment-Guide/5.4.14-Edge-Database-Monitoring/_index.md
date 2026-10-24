---
title: "5.4.14 CloudFront, Aurora reader and CloudWatch alarm"
date: 2026-10-23
weight: 14
chapter: false
pre: " <b> 5.4.14. </b> "
---

This step covers three parts of the architecture that the earlier steps only mention: the **CloudFront** distribution in front of the frontend and the chat, the **Aurora reader** in the second Availability Zone, and a **CloudWatch alarm** that notifies an SNS topic. For each part you see the finished result from the console and the form used to create it. In the screenshots, a **red box with a number** marks what to fill in or click, in order.

{{% notice note %}}
The screenshots of the creation forms were captured by opening each form and leaving it with **Cancel**: nothing was created while taking them, and the real resources were checked afterwards (still 12 alarms, 2 Aurora instances, 1 extra CloudFront behavior). The real resources are created by the CloudFormation stacks of the project, so the same result is reproducible without clicking.
{{% /notice %}}

#### Part A — CloudFront distribution

The distribution serves the web app over HTTPS and forwards the chat traffic to the load balancer.

**A.1 — Check the two origins.** Open **CloudFront → Distributions → `E2MHD79JFC1700` → Origins**. There must be two:

| Origin name | Type | Access |
|---|---|---|
| `frontend-s3-origin` | S3 | Origin Access Control, so the bucket is read only through CloudFront |
| `chat-alb-origin` | Elastic Load Balancing | HTTP only towards the origin (the load balancer has no HTTPS listener) |

![CloudFront Origins tab with the S3 origin and the chat load balancer origin](/images/workshop/console/cf-origins.jpg)
*The Origins tab: the S3 origin uses Origin Access Control and the second origin is the chat load balancer.*

**A.2 — Check the two behaviors.** Open the **Behaviors** tab. The `/socket.io/*` rule must come first, so the chat is matched before the default rule.

![CloudFront Behaviors tab with the /socket.io/* rule and the default rule](/images/workshop/console/cf-behaviors.jpg)
*The Behaviors tab: `/socket.io/*` goes to the chat origin, everything else goes to S3.*

**A.3 — Create the chat behavior.** Click **Create behavior** and fill in the form (numbers refer to the red boxes):

1. **Path pattern:** type the pattern below.
2. **Origin and origin groups:** choose `chat-alb-origin`.
3. **Viewer protocol policy:** choose **HTTPS only**.

```text
/socket.io/*
```

![Create behavior form, first half, with the path pattern, origin and viewer protocol](/images/workshop/console/cf-create-behavior-1.jpg)
*The first half of the form: path pattern, origin and viewer protocol policy.*

Then scroll down and set the cache and request policies:

1. **Cache policy:** `CachingDisabled`, because a WebSocket or long-polling connection must never be cached.
2. **Origin request policy:** `AllViewer`, so every viewer header, including the upgrade headers, reaches the chat service.

For **Allowed HTTP methods** choose all seven methods (`GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE`), because the Socket.IO polling transport uses `POST`. Click **Create behavior** to finish.

![Create behavior form, second half, with the cache policy and the origin request policy](/images/workshop/console/cf-create-behavior-2.jpg)
*The second half: cache policy and origin request policy.*

**A.4 — Verify.** After the distribution status is **Deployed**, this request must return `200` with an Engine.IO handshake (`sid`, `upgrades: ["websocket"]`) while the chat service is running:

```text
curl "https://<distribution-domain>/socket.io/?EIO=4&transport=polling"
```

If it returns `502`, the load balancer behind `chat-alb-origin` was recreated with a new DNS name: edit the origin and enter the current load balancer DNS name.

#### Part B — Aurora reader in the second Availability Zone

The cluster has one **Writer** and one **Reader**, so a read can continue if one instance or one Availability Zone has a problem.

**B.1 — Check the result.** Open **Aurora and RDS → Databases**. The cluster `fitness-assistant-dev-aurora` has two instances, both **Available**: one with the role *Writer instance* and one with the role *Reader instance*, both Aurora Serverless v2.

![RDS databases list with the cluster, the writer and the reader](/images/workshop/console/rds-writer-reader.jpg)
*The cluster with its Writer and Reader instances.*

**B.2 — Add a reader.** Open the cluster and use the **Actions** menu:

1. Click **Actions** at the top right of the cluster page.

![Cluster page with the Actions button marked](/images/workshop/console/rds-cluster.jpg)
*The cluster page, step 1: the Actions button.*

2. Choose **Add reader**.

![Actions menu with Add reader marked](/images/workshop/console/rds-actions-menu.jpg)
*The Actions menu, step 1: Add reader.*

3. In the **Add reader** form, type a **DB instance identifier** (for example `fitness-assistant-dev-aurora-instance-2`) and keep **DB instance class** on **Aurora serverless**. The capacity range is inherited from the cluster: minimum 0.5 ACU, maximum 2 ACU.

```text
fitness-assistant-dev-aurora-instance-2
```

![Add reader form with the instance identifier and the Aurora serverless class marked](/images/workshop/console/rds-add-reader.jpg)
*The Add reader form: instance identifier and Aurora serverless class.*

Scroll down, keep the defaults for network, security and monitoring, and click **Add reader**. The reader is placed in a different Availability Zone from the writer, and its **Promotion tier** decides which reader becomes the writer first in a failover.

#### Part C — A CloudWatch alarm that sends an e-mail

The project has 12 alarms, created by CloudFormation. This shows how one of them is built by hand: errors of the `auth` function above the threshold send a notification to the SNS topic.

**C.1 — Check the notification target.** Open **SNS → Topics → `fitness-assistant-dev-app-alerts`**. The **Subscriptions** tab must show one e-mail subscription with the status **Confirmed**.

![SNS topic with one confirmed e-mail subscription](/images/workshop/console/sns-subscriptions.jpg)
*The topic and its confirmed e-mail subscription.*

**C.2 — Create the alarm.** Open **CloudWatch → Alarms → Create alarm**.

1. Click **Select metric**.

![Create alarm, step 1, with Select metric marked](/images/workshop/console/cw-create-1-metric.jpg)
*Step 1 of the wizard: Select metric.*

2. Choose **Lambda → By Function Name**, tick the **Errors** row of `fitness-assistant-dev-auth`, then click **Select metric**.

![Metric picker with the Errors metric of the auth function ticked](/images/workshop/console/cw-create-2-pick.jpg)
*The metric picker: the `Errors` metric of `fitness-assistant-dev-auth`.*

3. Set **Statistic** to `Sum` and **Period** to `5 minutes`. In **Whenever Errors is…** choose **Greater/Equal**, type the threshold below, then click **Next**.

```text
5
```

![Condition settings with Greater/Equal, threshold 5 and Next marked](/images/workshop/console/cw-create-3-condition.jpg)
*The condition: greater than or equal to 5 errors in 5 minutes.*

4. In **Configure actions**, keep **In alarm** as the trigger, choose **Select an existing SNS topic**, and pick `fitness-assistant-dev-app-alerts`. Add a second notification for **OK** with the same topic, so you also get a message when the alarm recovers.

![Configure actions step with the SNS topic field marked](/images/workshop/console/cw-create-4-actions.jpg)
*The actions step: choose the SNS topic.*

5. Click **Next**, enter the name `fitness-assistant-dev-auth-lambda-errors`, click **Next**, review and click **Create alarm**.

**C.3 — Verify.** The new alarm shows **OK** (or **Insufficient data** for a few minutes). The full list of the project's alarms:

![CloudWatch alarm list with 12 alarms](/images/workshop/console/cw-alarms-list.jpg)
*The 12 alarms of the project. The three NAT Gateway alarms show Insufficient data while the NAT Gateway is switched off.*

**Test the alert path** without breaking anything by forcing the alarm into the alarm state, then wait for the e-mail and for the alarm to return to OK by itself:

```text
aws cloudwatch set-alarm-state --alarm-name fitness-assistant-dev-auth-lambda-errors --state-value ALARM --state-reason "Alert path test"
```

#### Result

- The CloudFront distribution has an S3 origin with Origin Access Control and a chat origin, with `/socket.io/*` matched first.
- The Aurora cluster has a Writer and a Reader in different Availability Zones.
- A CloudWatch alarm sends ALARM and OK messages to a confirmed e-mail through SNS.
