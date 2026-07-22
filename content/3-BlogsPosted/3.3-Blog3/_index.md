---
title: "Blog 3: Monitoring with CloudWatch and SNS"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 3.3. </b> "
---

## Monitoring an EC2 Container Application with CloudWatch and SNS

**Status:** Draft

**Publish date:** [TODO_DATE]

**Post URL:** [TODO_BLOG_URL]

**Cover image:** TODO screenshot — not yet captured.

### Objective

Explain how basic observability was added to the Fitness Assistant EC2 deployment: shipping container logs to Amazon CloudWatch Logs, alarming on EC2/RDS metrics, and notifying by email through Amazon SNS.

### Summary

By default, EC2 only reports CPU, network and basic status-check metrics — nothing about memory or disk usage, and no application logs. This post covers installing the CloudWatch Agent to collect additional host metrics and forward container logs, building a small CloudWatch Dashboard, creating alarms for EC2 CPU and status checks plus RDS CPU/connections/storage, and wiring those alarms to an SNS topic with an email subscription.

### Main Content

- Installing and configuring the CloudWatch Agent (`cloudwatch-agent-config.example.json`) on the EC2 host.
- Creating CloudWatch Log Groups with an explicit retention period, to avoid unbounded log storage cost.
- Creating CloudWatch Alarms for EC2 CPU utilization, EC2 status check failures, and RDS CPU/connections/storage.
- Creating an SNS topic, subscribing an email address, and confirming the subscription.
- Testing the full chain: **Metric → Alarm → SNS → Email**.
- TODO: Insert real dashboard screenshot, a triggered alarm screenshot, and the received notification email screenshot.

### What I Learned

- The gap between "EC2 looks fine in the console" and "the application inside the container is actually healthy" — logs and application-level metrics matter as much as infrastructure metrics.
- How to test an alerting pipeline end to end instead of assuming it works once configured.

{{% notice warning %}}
Do not mark this pipeline as "working" in the published post until a real alarm has actually fired and a real email notification has been received and captured as evidence.
{{% /notice %}}
