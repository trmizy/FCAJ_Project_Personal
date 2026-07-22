---
title: "Week 11"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 1.11. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Run end-to-end and failure-path testing against the deployed MVP.
- Review IAM policies and Security Group rules for over-permissive access.
- Review cost and identify optimization opportunities before the internship wraps up.

### Tasks Performed

- Executed the test cases defined in [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/) covering registration, login, protected endpoints, RDS persistence, container restart recovery, and monitoring/alerting.
- Tested negative paths: unauthorized requests without a token, requests with an invalid/expired JWT, and behavior when the database is briefly unreachable.
- Reviewed the IAM Role attached to EC2 against the actual permissions used, removing anything broader than necessary (no wildcard `*` resources where a specific ARN could be used).
- Reviewed Security Group rules to confirm SSH (port 22) is not open to `0.0.0.0/0` and that RDS port 5432 only accepts traffic from the application Security Group.
- Reviewed running resources against the estimates in the [Proposal](../../2-Proposal/) cost section and noted any instance types, storage or idle resources that should be right-sized or stopped when not in use.

### Results Achieved

- A documented test run with pass/fail status per test case (see [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/); tests not yet executed are marked `Not executed`, not `PASS`).
- A shortlist of IAM/Security Group tightening actions.
- TODO: Record actual AWS Cost Explorer figures once at least one full billing cycle is available.

### Difficulties

- Simulating realistic failure scenarios (e.g., database temporarily unreachable) without causing unwanted downtime for other testing in progress.

### How It Was Resolved

- Scheduled failure-path tests in a dedicated maintenance window rather than interleaving them with other testing, and documented expected vs. actual behavior for each.

### AWS Skills / Services Learned

- Practical IAM least-privilege review technique (compare granted permissions against actually-used API calls).
- Reading AWS Cost Explorer / Billing dashboard to sanity-check running resources against the cost estimate.

### Evidence Still Required

- TODO: Completed test case table with evidence links.
- TODO: Screenshot of IAM policy review notes/diff.
- TODO: Screenshot of AWS Cost Explorer for the billing period covering this project.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Execute functional end-to-end test cases | [TODO_DATE] | [TODO_DATE] | [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/) |
| 2 | Execute failure-path test cases | [TODO_DATE] | [TODO_DATE] | [Workshop 5.13](../../5-Workshop/5.13-Testing-Validation/) |
| 3 | Review IAM policies and Security Groups | [TODO_DATE] | [TODO_DATE] | [Workshop 5.14](../../5-Workshop/5.14-Security-Cost/) |
| 4 | Review cost against estimate | [TODO_DATE] | [TODO_DATE] | [Workshop 5.14](../../5-Workshop/5.14-Security-Cost/) |

### Completion Checklist

- [ ] Functional test cases executed and recorded
- [ ] Failure-path test cases executed and recorded
- [ ] IAM/Security Group review completed
- [ ] Cost review completed against Proposal estimate

### Related Workshop Section

- [5.13 Testing and Validation](../../5-Workshop/5.13-Testing-Validation/)
- [5.14 Security and Cost Optimization](../../5-Workshop/5.14-Security-Cost/)
