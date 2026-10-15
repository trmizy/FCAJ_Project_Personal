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

- Share knowledge with the community by writing technical blog posts
- Learn how to restrict AWS Management Console sign-in to expected networks with sign-in resource-based policies and resource control policies (RCPs)

### Work Completed This Week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Wrote Blog 2, "Limit AWS Management Console Access to Trusted Networks", and published it to the AWS Study Group VN Facebook group | 28-9-2026 | 03-10-2026 | [Original article on the AWS Security Blog](https://aws.amazon.com/blogs/security/restrict-aws-management-console-access-to-expected-networks-with-sign-in-resource-based-policies-and-rcps/) <br>[Post on Facebook](https://www.facebook.com/share/p/19qBt1z5fU/) |

### Week 9 Results:

**Overview:**

This week was dedicated to community contribution and knowledge sharing. I studied an AWS Security Blog article on a new AWS Sign-In feature that limits console sign-in to expected networks, then wrote and published Blog 2 about it for the AWS Study Group VN, relating it to how the Fitness Assistant account is managed.

**Theoretical Knowledge Gained:**

- **Sign-in resource-based policies:** Deny statements attached to AWS Sign-In for one account, generated from a source IP range, a source VPC and an excluded principal. They are checked before the credentials (`signin:Authenticate`) and again whenever the console session asks for tokens, and they only take effect once console authorization is turned on.

- **Resource control policies (RCPs):** The same network rules applied through AWS Organizations to every account in an organization or organizational unit.

- **Technical Writing:** Learned how to effectively communicate technical concepts to a broader audience.

**Hands-on Labs Completed:**

- Wrote and published Blog 2 in the AWS Study Group VN Facebook group

**Application to Fitness Assistant:**

The DEV environment of the Fitness Assistant was built mostly through the AWS Management Console (see Workshop 5.4), so console sign-in is the most powerful way into the account. The blog's controls would add a network condition on top of MFA:
- Allow sign-in only from expected networks, such as a VPN with a fixed egress IP or a VPC reached through Console Private Access
- Keep one excluded break-glass principal, so a changed home IP address cannot lock the account
- Watch CloudTrail `ConsoleLogin` failures caused by the sign-in policy
- Use RCPs instead of per-account policies if the project later grows to several accounts

### Related Workshop Links:

- [3.2 Blog 2](../../3-BlogsPosted/3.2-Blog2/) - Limit AWS Management Console Access to Trusted Networks
- [5.2.5 Security and IAM](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/) - How access to the project is secured today
