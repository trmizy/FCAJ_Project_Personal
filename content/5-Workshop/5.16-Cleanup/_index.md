---
title: "5.16 Cleanup"
date: 2026-07-15
weight: 16
chapter: false
pre: " <b> 5.16. </b> "
---

{{% notice warning %}}
Follow this order. Deleting resources out of order (e.g. a VPC before its Security Groups, or an IAM role while still attached to a running instance) will fail or leave orphaned resources. Each step below notes its dependency and expected cost impact.
{{% /notice %}}

See also [`/files/scripts/cleanup-checklist.md`](/files/scripts/cleanup-checklist.md) for a copyable checklist version of the steps below.

1. **Stop and remove containers** — `docker compose down` on the EC2 host. *Console:* n/a (SSH/Session Manager). *Expected result:* no running containers. *Cost impact:* stops compute inside the instance, but the instance itself still bills until stopped/terminated.
2. **Delete CloudWatch Alarms** — Console: CloudWatch → Alarms → Delete. CLI: `aws cloudwatch delete-alarms --alarm-names <name>`. *Dependency:* none blocking, but do this before deleting the SNS topic the alarms reference, to avoid dangling actions.
3. **Delete SNS subscription and topic** — Console: SNS → Subscriptions/Topics → Delete. CLI: `aws sns unsubscribe --subscription-arn <arn>` then `aws sns delete-topic --topic-arn <arn>`.
4. **Delete CloudWatch Log Groups** (if not needed for record-keeping) — Console: CloudWatch → Log groups → Delete. CLI: `aws logs delete-log-group --log-group-name <name>`. *Warning:* this permanently deletes log history; keep if evidence is still needed for this report.
5. **Delete S3 objects and bucket** (only if an S3 bucket was created for testing per [5.10 S3 Storage](../5.10-S3-Storage/)) — empty the bucket first, then delete it. CLI: `aws s3 rm s3://<bucket> --recursive` then `aws s3api delete-bucket --bucket <bucket>`.
6. **Delete ECR images and repositories** — Console: ECR → Repositories → Delete. CLI: `aws ecr delete-repository --repository-name <name> --force`. *Cost impact:* stops ECR storage charges for these images.
7. **Delete RDS instance** — Console: RDS → Databases → Delete. CLI: `aws rds delete-db-instance --db-instance-identifier fitness-assistant-db --skip-final-snapshot` (or omit `--skip-final-snapshot` if a final snapshot is wanted). *Cost warning:* RDS billing stops only once the instance is fully deleted, not when it is merely stopped.
8. **Decide: final snapshot or not** — if this deployment may be resumed later, take a final snapshot before deleting the instance; otherwise skip it to avoid ongoing snapshot storage cost.
9. **Delete EC2 instance** — Console: EC2 → Instances → Terminate. CLI: `aws ec2 terminate-instances --instance-ids <id>`. *Dependency:* must happen before deleting its Security Group or IAM instance profile association.
10. **Release Elastic IP** (if one was allocated) — Console: EC2 → Elastic IPs → Release. CLI: `aws ec2 release-address --allocation-id <id>`. *Cost warning:* an unattached Elastic IP continues to incur charges until released.
11. **Delete Load Balancer and Target Group** (only if one was created for future/optional work) — not part of the MVP; delete if it exists.
12. **Delete NAT Gateway** (only if one was created) — not used in this MVP design by default; delete if present, and release its associated Elastic IP.
13. **Delete custom route tables** — Console: VPC → Route Tables → Delete. *Dependency:* subnets must no longer reference the route table.
14. **Delete subnets** — Console: VPC → Subnets → Delete. *Dependency:* no running resources (EC2, RDS) may still reference the subnet.
15. **Delete Internet Gateway** — detach from the VPC first, then delete.
16. **Delete custom Security Groups** — Console: VPC → Security Groups → Delete. *Dependency:* no ENI (e.g. a still-running EC2/RDS instance) may reference the Security Group.
17. **Delete the VPC** — Console: VPC → Your VPCs → Delete. *Dependency:* all of the above (subnets, IGW, route tables, Security Groups) must be removed first.
18. **Delete the Secrets Manager secret(s)** — Console: Secrets Manager → Delete. CLI: `aws secretsmanager delete-secret --secret-id <id> --recovery-window-in-days 7` (use a recovery window rather than force-deleting immediately, in case of mistake).
19. **Delete self-created IAM policies/roles** — Console: IAM → Roles/Policies → Delete. *Dependency:* the role must no longer be attached to any instance profile/resource.
20. **Check Billing and Resource Explorer** — Console: Billing Dashboard and AWS Resource Explorer, to confirm no unexpected resources remain running in this account/Region after clean-up.

{{% notice warning %}}
Never run a deletion command with a wildcard across an entire AWS account. Every command above targets a specific, named resource. Double-check the resource ID/ARN before running any `delete-*` or `terminate-*` command.
{{% /notice %}}
