---
title: "Week 10"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 1.10. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Set up centralized logging with Amazon CloudWatch Logs.
- Configure basic CloudWatch metrics and alarms for EC2 and RDS.
- Set up an Amazon SNS topic with email notification for alarms.

### Tasks Performed

- Installed and configured the CloudWatch Agent on the EC2 instance to ship container/application logs and host-level metrics (memory, disk) that are not available by default from basic EC2 monitoring.
- Created CloudWatch Log Groups with an explicit retention period (not "Never expire", to control cost).
- Created a CloudWatch Dashboard summarizing EC2 CPU, memory (via the Agent), disk usage, and RDS CPU/connections/storage.
- Created a CloudWatch Alarm for high EC2 CPU utilization and one for EC2 status check failures.
- Created an Amazon SNS topic, subscribed an email address to it, and confirmed the subscription.
- Wired the alarms to publish to the SNS topic, and sent a test notification to confirm the full chain: **Metric → Alarm → SNS → Email**.

### Results Achieved

- Working log pipeline from containers to CloudWatch Logs.
- Alarms configured and (pending test) verified to notify by email.
- TODO: Confirm the test alarm actually fired and the email was received; attach evidence.

### Difficulties

- Basic EC2 monitoring does not report memory or disk usage — this required the CloudWatch Agent rather than relying on the default EC2 metrics.

### How It Was Resolved

- Installed and configured the CloudWatch Agent with a JSON configuration file (see `cloudwatch-agent-config.example.json`) to collect memory and disk metrics in addition to the default CPU/network metrics.

### AWS Skills / Services Learned

- Amazon CloudWatch (Logs, Metrics, Alarms, Dashboards), CloudWatch Agent configuration, Amazon SNS topics and email subscriptions.

### Evidence Still Required

- TODO: Screenshot of the CloudWatch Dashboard.
- TODO: Screenshot of a triggered alarm.
- TODO: Screenshot/email showing the SNS notification received.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Install and configure CloudWatch Agent | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |
| 2 | Create Log Groups with retention policy | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |
| 3 | Create CloudWatch Alarms (EC2 CPU, status check, RDS) | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |
| 4 | Create SNS topic, subscribe email, test the alarm chain | [TODO_DATE] | [TODO_DATE] | [Workshop 5.12](../../5-Workshop/5.12-Monitoring-Alerting/) |

### Completion Checklist

- [ ] CloudWatch Agent installed and shipping logs/metrics
- [ ] Log Groups created with a defined retention period
- [ ] Alarms created for EC2 and RDS
- [ ] SNS topic created, email subscribed, test notification confirmed

### Related Workshop Section

- [5.12 Monitoring and Alerting](../../5-Workshop/5.12-Monitoring-Alerting/)
