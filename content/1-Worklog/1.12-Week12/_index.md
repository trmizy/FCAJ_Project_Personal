---
title: "Week 12"
date: 2026-07-15
weight: 12
chapter: false
pre: " <b> 1.12. </b> "
---

{{% notice note %}}
Dates in this page are placeholders (`[TODO_DATE]`) until the confirmed internship schedule is available.
{{% /notice %}}

### Week Objectives

- Clean up all AWS resources created for testing to avoid ongoing cost.
- Gather and organize all screenshots/evidence collected during the internship.
- Finalize the bilingual report and write the self-evaluation and reflection.

### Tasks Performed

- Followed the clean-up sequence in [Workshop 5.16](../../5-Workshop/5.16-Cleanup/) in dependency order (containers → alarms/SNS → S3 objects if any → ECR images → RDS → EC2/EIP → networking → IAM/Secrets).
- Collected and organized all screenshots into the `static/images/` folder structure, matching each image to the workshop step it documents.
- Reviewed every page of the report for `TODO` markers and confirmed which ones are still outstanding versus resolved.
- Completed the [Self-evaluation](../../6-Self-evaluation/) and [Sharing and Feedback](../../7-Feedback/) sections.
- Reviewed the final architecture against what was actually implemented, and wrote the [Conclusion](../../5-Workshop/5.17-Conclusion/) comparing the plan to the outcome honestly (including what was not completed).

### Results Achieved

- AWS resources cleaned up (or a documented reason why a resource was intentionally kept, e.g. for grading/demo purposes).
- A complete bilingual report with all sections present.
- TODO: Final read-through by a second reviewer (mentor or peer) before submission.

### Difficulties

- Some resources have dependencies that block deletion in the wrong order (e.g. a Security Group still referenced by an ENI, or an IAM Role still attached to an instance profile in use).

### How It Was Resolved

- Followed the explicit dependency-ordered clean-up checklist in [Workshop 5.16](../../5-Workshop/5.16-Cleanup/) rather than deleting resources ad hoc, and re-checked the Billing/Cost Explorer console afterward to confirm no unexpected resources were left running.

### AWS Skills / Services Learned

- Safe, dependency-aware resource teardown.
- Using AWS Billing and Resource Explorer to verify a clean account state after teardown.

### Evidence Still Required

- TODO: Screenshot of the Billing dashboard showing no unexpected running resources after clean-up.
- TODO: Final list of any resources intentionally retained, with justification.

### Day-by-Day / Task Table

| Day | Task | Start Date | Completion Date | Reference |
| --- | ---- | ---------- | ---------------- | --------- |
| 1 | Clean up AWS resources in dependency order | [TODO_DATE] | [TODO_DATE] | [Workshop 5.16](../../5-Workshop/5.16-Cleanup/) |
| 2 | Organize screenshots and evidence | [TODO_DATE] | [TODO_DATE] | `static/images/` |
| 3 | Complete Self-evaluation and Feedback sections | [TODO_DATE] | [TODO_DATE] | [Self-evaluation](../../6-Self-evaluation/), [Feedback](../../7-Feedback/) |
| 4 | Final review and Conclusion write-up | [TODO_DATE] | [TODO_DATE] | [Workshop 5.17](../../5-Workshop/5.17-Conclusion/) |

### Completion Checklist

- [ ] AWS resources cleaned up in the correct dependency order
- [ ] Billing dashboard checked for leftover resources
- [ ] All screenshots organized and linked into the report
- [ ] Self-evaluation and Feedback sections completed
- [ ] Conclusion written honestly against the original Proposal

### Related Workshop Section

- [5.16 Cleanup](../../5-Workshop/5.16-Cleanup/)
- [5.17 Conclusion](../../5-Workshop/5.17-Conclusion/)
