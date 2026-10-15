---
title: "Week 9 Worklog"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 1.9. </b> "
draft: false
---

# WORKLOG WEEK 9

### Week 9 Objectives:

- Reflect on the Fitness Assistant AWS deployment so far and write it up as a technical case study
- Look into AWS CloudFormation as a way to close the "no CI/CD yet" gap already tracked in the Workshop

### Work Completed This Week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Wrote Blog 2, "Challenges and Cost Optimization in AWS Deployment: Lessons Learned from Gymini", as a technical case study | 28-9-2026 | 03-10-2026 | [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) <br>[AWS Well-Architected Framework — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html) |

### Week 9 Results:

**Overview:**

This week was dedicated to reviewing the AWS deployment experience so far and writing it up as Blog 2: why a multi-service deployment is not a one-day task, the concrete troubleshooting incidents already documented in the Workshop (the Chat service's secret-value mistake, Lambda's secret caching), and why AWS CloudFormation is worth adopting given that deployment today is entirely manual.

**Theoretical Knowledge Gained:**

- **Free Tier vs. promotional credit vs. pay-as-you-go:** three different things, and having credit does not mean the infrastructure is free — it only postpones real billing.
- **Fixed-cost vs. usage-based resources:** most of this project's services bill by usage, but a few (NAT Gateway, Aurora's capacity floor, the Chat Fargate task, the ALB, VPC endpoints, public IPv4) bill by the hour regardless of traffic, which is exactly the resource profile already estimated in the Proposal's budget.
- **AWS CloudFormation:** stacks, templates, parameters, outputs, Change Sets, drift detection, and — importantly — what it does *not* guarantee (cost reduction, or that deleting a stack removes every resource).
- **Technical Writing:** structuring a case study that separates confirmed facts from reasonable inference, instead of presenting everything as equally certain.

**Hands-on Labs Completed:**

- Wrote Blog 2 as a case study, pulling concrete evidence from the Workshop pages already written (5.2.6, 5.2.7, 5.4.10, 5.5.5) instead of writing generic advice

**Application to Fitness Assistant:**

Writing this case study turned into an honest audit of the project's own operational gaps:
- No CI/CD pipeline yet — every deployment step in [5.4](../../5-Workshop/5.4-Deployment-Guide/) is done by hand through the console
- No CloudWatch alarms and no AWS Budgets alert yet ([5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/), [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/))
- A documented but not yet executed clean-up order ([5.7](../../5-Workshop/5.7-Cleanup/))
- CloudFormation (or the Terraform already named in the proposed target architecture) is the natural next step once the project moves past manual deployment

### Related Workshop Links:

- [3.2 Blog 2](../../3-BlogsPosted/3.2-Blog2/) - Challenges and Cost Optimization in AWS Deployment
- [5.2.7 Cost Optimization and Clean-up](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/) - The real fixed-cost items this case study is grounded in
