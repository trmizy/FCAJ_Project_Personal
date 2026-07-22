---
title: "5.12 Monitoring and Alerting"
date: 2026-07-15
weight: 12
chapter: false
pre: " <b> 5.12. </b> "
---

### The Chain

```
Metric  -->  Alarm  -->  SNS  -->  Email
```

Every alert configured in this section must be traceable through all four stages, with evidence for each.

### CloudWatch Agent

Default EC2 monitoring does not report memory or disk usage. Install and configure the CloudWatch Agent to collect these, plus forward container/application logs.

See [`/files/docker/cloudwatch-agent-config.example.json`](/files/docker/cloudwatch-agent-config.example.json) for a reference configuration collecting memory, disk, and log file inputs.

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json
```

### Container / Application Logs

Docker's `awslogs` logging driver, or the CloudWatch Agent's log file collection pointed at `docker compose logs` output, ships container logs to CloudWatch Logs. TODO: record which approach was actually used.

### Log Groups

Create explicit Log Groups per service rather than a single catch-all group, to make searching and retention easier to reason about, e.g. `/fitness-assistant/gateway`, `/fitness-assistant/auth-service`.

### Retention Period

Set an explicit retention period (e.g. 14 or 30 days) on every Log Group — never leave it at "Never expire" by omission, to control storage cost.

```bash
aws logs put-retention-policy --log-group-name /fitness-assistant/gateway --retention-in-days 14
```

### Dashboard

A CloudWatch Dashboard summarizing: EC2 CPU utilization, EC2 memory/disk (via the Agent), RDS CPU utilization, RDS database connections, RDS free storage space. TODO: attach a screenshot once created.

### EC2 CPU Alarm

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name fitness-assistant-ec2-high-cpu \
  --metric-name CPUUtilization --namespace AWS/EC2 \
  --statistic Average --period 300 --threshold 80 \
  --comparison-operator GreaterThanThreshold --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=<TODO_INSTANCE_ID> \
  --alarm-actions <TODO_SNS_TOPIC_ARN>
```

### EC2 Status Check Alarm

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name fitness-assistant-ec2-status-check-failed \
  --metric-name StatusCheckFailed --namespace AWS/EC2 \
  --statistic Maximum --period 60 --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=<TODO_INSTANCE_ID> \
  --alarm-actions <TODO_SNS_TOPIC_ARN>
```

### RDS CPU / Connections / Storage

Similar `put-metric-alarm` calls against namespace `AWS/RDS`, metrics `CPUUtilization`, `DatabaseConnections`, and `FreeStorageSpace`, dimensioned by `DBInstanceIdentifier`. TODO: record the actual thresholds chosen and why.

### API Error Logs

TODO: decide whether application-level error logs (e.g. 5xx responses from the gateway) are surfaced as a CloudWatch metric filter and alarm, or only reviewed manually in CloudWatch Logs Insights. Not yet implemented.

### SNS Topic and Email Subscription

```bash
aws sns create-topic --name fitness-assistant-alerts
aws sns subscribe \
  --topic-arn <TODO_SNS_TOPIC_ARN> \
  --protocol email \
  --notification-endpoint <TODO_ALERT_EMAIL>
```

Confirm the subscription via the confirmation email before relying on it.

### Test Alarm

Manually set an alarm to `ALARM` state to confirm the full chain works end to end:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name fitness-assistant-ec2-high-cpu \
  --state-value ALARM \
  --state-reason "Manual test of the alert pipeline"
```

### Expected Result

- The test alarm transitions to `ALARM`.
- An email is received at the subscribed address within a few minutes.
- TODO: attach a screenshot of the received email and the alarm history as evidence once this has actually been executed.
