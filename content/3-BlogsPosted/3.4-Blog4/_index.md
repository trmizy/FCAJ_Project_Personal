---
title: "Blog 4: Limit AWS Management Console Access to Trusted Networks"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 3.4. </b> "
draft: false
---

## Limit AWS Management Console Access to Trusted Networks with Sign-in Policies and RCPs

**Status:** Draft — not yet shared externally.

**Original article:** [Restrict AWS Management Console access to expected networks with sign-in resource-based policies and RCPs](https://aws.amazon.com/blogs/security/restrict-aws-management-console-access-to-expected-networks-with-sign-in-resource-based-policies-and-rcps/) (AWS Security Blog, 24 June 2026)

---

For most teams, the AWS Management Console is the most powerful door into an AWS account: whoever signs in can see and change almost everything their permissions allow. A password and MFA prove who the user is, but not where the request comes from. In June 2026, AWS Sign-In gained resource-based policies and resource control policies (RCPs), so an account, or a whole organization, can refuse console sign-in from networks it does not expect. A post on the AWS Security Blog walks through this new control.

### 1. Why restricting sign-in by network used to be hard

- **IAM and SCP conditions act after sign-in.** A condition such as `aws:SourceIp` in an IAM policy or an SCP can deny API actions from unknown networks, but the user can still sign in and open the console.
- **Identity provider rules cover only federated users.** Network rules in an external identity provider do not apply to IAM users or to the root user.
- **No single place to enforce it.** Each account and each type of identity needed its own workaround.

### 2. The new control: sign-in policies and RCPs

- **Sign-in resource-based policy, for one account.** You describe the expected networks with a few parameters (a source IP range, a source VPC and its Region, and an excluded principal), and AWS Sign-In generates the policy: deny statements that block sign-in unless the request comes from an expected network or from the excluded principal.
- **Resource control policy, for many accounts.** The same rules, attached in AWS Organizations to the organization, an organizational unit or a single account, and applied automatically to every account in scope.
- **A switch to turn it on.** The statements have no effect until console authorization is enabled for the account, so they can be reviewed before they are enforced.

The controls cost nothing extra and are available in all AWS commercial Regions. They do not replace IAM identity-based policies, which still decide what a signed-in user may do.

### 3. How a sign-in request is checked

{{< mermaid >}}
graph LR
  S[Sign-in request] --> N{Expected network or excluded principal}
  N -- no --> D[Denied and logged in CloudTrail]
  N -- yes --> A[Password and MFA]
  A --> T[Console session tokens]
  T -- checked again on refresh --> N
  T --> I[IAM policies decide each action]
{{< /mermaid >}}

1. **Before the credentials are checked**, AWS Sign-In evaluates the `signin:Authenticate` action against the policy. A request from outside the expected IP range or VPC is denied, even with the correct password and MFA, unless it comes from the excluded principal.
2. **Normal authentication** follows: password and MFA, or a federated sign-in.
3. **When the console asks for session tokens** (`signin:CreateOAuth2Token` and `signin:AuthorizeOAuth2Access`), the same network rules are evaluated again, and again every time the session requests new credentials.
4. **Region binding** stops a request that claims the allowed VPC but asks for another Region, because a VPC ID is only unique within one Region.
5. **Every attempt is logged** as a `ConsoleLogin` event in CloudTrail. A blocked attempt shows `AccessDenied` with "Authorization denied because of a resource-based policy", or "...resource control policy" when an RCP blocked it.

### 4. Safe deployment checklist

- **List the expected networks first:** the office and VPN egress IP ranges, and the VPC IDs (with their Regions) that users sign in from.
- **Always keep an excluded principal** for break-glass access, so a wrong range cannot lock everyone out.
- **Create, review, then enable.** Create the statements (write operations go to `us-east-1`), review them with `aws signin get-resource-policy`, and only then run `aws signin put-console-authorization-configuration`.
- **Know the rollback:** `delete-console-authorization-configuration` turns enforcement off, and `delete-resource-permission-statement` removes a statement.
- **Start with a test account**, then move to RCPs at the organization or OU level when many accounts need the same rule.
- **Monitor CloudTrail** for `ConsoleLogin` failures caused by the sign-in policy, to catch attacks as well as legitimate users on a new network.
- **Combine it with Console Private Access** and VPC endpoint policies to build a full network, identity and resource perimeter.

### Personal view

What I like about this control is that it moves the check to the very first step. An attacker who phishes both a password and an MFA code still cannot use them from an unexpected network.

The DEV environment of Fitness Assistant was built mostly through the AWS Management Console (see Workshop [5.4](../../5-Workshop/5.4-Deployment-Guide/)), so console sign-in is the most powerful way into that account. MFA already protects it, but this project has no fixed office network. Before turning on a sign-in policy, I would first need a stable source address, such as a VPN with a fixed egress IP or a VPC reached through Console Private Access, plus an excluded break-glass principal, so that a new home IP address cannot lock me out of my own account.

### Conclusion

Sign-in resource-based policies and RCPs close a gap that IAM policies could not: they decide whether a console session may start at all, based on where the request comes from. They are generated from a few parameters, reviewed before they are enforced, logged in CloudTrail and free of charge. That makes them an easy extra layer for any account managed through the console, as long as an excluded principal keeps a safe way back in.

### References

- AWS Security Blog: [Restrict AWS Management Console access to expected networks with sign-in resource-based policies and RCPs](https://aws.amazon.com/blogs/security/restrict-aws-management-console-access-to-expected-networks-with-sign-in-resource-based-policies-and-rcps/)
- [AWS Sign-In User Guide: console access control](https://docs.aws.amazon.com/signin/latest/userguide/console-access-control.html)
- [AWS Organizations: resource control policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html)
- [Data perimeter policy examples (aws-samples)](https://github.com/aws-samples/data-perimeter-policy-examples)
