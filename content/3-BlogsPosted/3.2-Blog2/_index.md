---
title: "Blog 2: Challenges and Cost Optimization in AWS Deployment"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 3.2. </b> "
draft: false
---

## Challenges and Cost Optimization in AWS Deployment: Lessons Learned from Gymini

**Status:** Technical case study written from the experience of deploying Gymini for this internship.

**Shared on Facebook:** https://www.facebook.com/share/p/19qBt1z5fU/

{{% notice note %}}
This post follows what is already confirmed elsewhere in this report (linked at each point). The parts about AWS credit running out faster than expected and about adopting CloudFormation are presented as an **illustrative case study**, reasoned from the real cost profile of the deployed architecture — not a confirmed billing history — and CloudFormation is **not** currently used for this project (every resource so far was created by hand through the AWS Console, see [5.4](../../5-Workshop/5.4-Deployment-Guide/)). The closing "Evidence and limitations" section lists exactly what is confirmed, what is a reasonable inference, and what is only a proposal.
{{% /notice %}}

### 1. Why deploying a multi-component application is not a one-day job

Gymini is not a simple CRUD project. It is a pnpm monorepo with seven Node.js/TypeScript services (Auth, User, Fitness, Gym, Payment, AI, Chat) plus a React frontend, which until recently only ran with Docker Compose on one machine — no public endpoint, no backups, no isolation between components (see [Proposal §2](../../2-Proposal/#problem)).

The gap between "it runs on my machine" and "it operates on the cloud" is exactly the work `docker compose up` never has to do: provisioning a VPC and subnets, writing an IAM role per service, replacing `.env` files with managed secrets, reconnecting services that no longer share a hostname, adding health checks, centralizing logs, and re-validating each piece after it moves. The number of containers in an application does not predict deployment time, because most of the time goes into wiring managed services together correctly and checking each step, not into building images.

### 2. Initial expectations versus deployment reality

The initial expectation was simple: finish the code, build the Docker images, deploy to AWS, done — possibly in a day. The real deployment of Gymini followed a different loop entirely: provision infrastructure → configure → deploy → validate → troubleshoot → redeploy → confirm, repeated service by service, spread across 26 August to 23 September 2026 ([Worklog, Weeks 4–8](../../1-Worklog/)) — about four weeks, not one day.

| Aspect | Initial expectation | Practical reality |
|---|---|---|
| Deployment duration | About one day | Multiple configuration, testing and troubleshooting cycles over roughly four weeks |
| Infrastructure | Basic provisioning | Several interdependent components (VPC, IAM, Secrets Manager, Aurora, SQS, EventBridge...) |
| Configuration | One-time | Adjusted repeatedly, with revisions that had to be redone |
| Testing | After deployment | Continuous, service by service ([5.5](../../5-Workshop/5.5-Test-Validation/)) |
| Cost | Covered by credits, not a concern | Some resources bill hourly whether or not they are used |

"One day" here is the author's personal expectation going in, not a general benchmark for every project.

### 3. Technical challenges actually encountered

**Networking and security.** Every added service meant getting the security groups right: `lambda-sg` and `chat-sg` are allowed into `aurora-sg` on port 5432, `vpce-sg` allows `lambda-sg` on port 443 to reach Secrets Manager and OpenSearch through VPC endpoints, and the DB subnets have no route to the internet at all ([5.2.5](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/)). A security group pointed the wrong way means a Lambda function can't reach the database, with nothing in the logs saying why.

**Container deployment.** The Chat service produced the most concrete incident: in revision 1 of its task definition, two secrets (`CHAT_DATABASE_URL`, `INTERNAL_API_SECRET`) were entered as **Value** instead of **ValueFrom**, so the container received the secret's *name* instead of its *connection string*, and Prisma failed with `URL must start with postgresql://`. The fix was a new revision using ValueFrom with the full ARN and the JSON key suffix (`...:CHAT_DATABASE_URL::`), followed by *Force new deployment* ([5.4.10](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)).

**Database integration.** Seven services share one Aurora cluster but each keeps its own logical database and its own secret. Lambda caches the database secret for as long as its execution environment stays warm, so after rotating the Aurora password, the fix was not to wait — it was editing a harmless environment variable (`DEPLOY_REVISION`) purely to force AWS to create a new execution environment ([5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/)).

**Environment configuration.** Each service has its own environment variables and secrets, migration Lambdas were created, run once and deleted, and every configuration fix meant a new task definition revision or a function environment-variable update.

**Troubleshooting and redeployment.** The most repeated pattern was: read the *Stopped reason* and the service *Events* instead of recreating the service, update the task definition, then *Force new deployment* — and confirm *Running 1/1*, *Healthy* before calling it done ([5.4.10, step 23](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)).

### 4. Unexpected AWS credit consumption

AWS Free Tier, promotional credits and pay-as-you-go are three different things: the Free Tier is a fixed, per-service free allowance; promotional credit is a balance that gets drawn down against the bill and expires; pay-as-you-go is the default pricing for everything beyond those two. Having credit does not mean the infrastructure is free — it only postpones the point at which real money is charged, and once it runs out, billing reverts to list price.

What is easy to overlook while still configuring and debugging: most resources in this architecture bill by usage (Lambda, API Gateway, SQS, Bedrock per token), but a few bill by the **hour**, regardless of whether a single request arrives. Per the architecture-level estimate in [Proposal §8](../../2-Proposal/#budget), those fixed items are: the NAT Gateway (~43 USD/month), Aurora at its minimum capacity (~45–60 USD/month), the Chat Fargate task (~22 USD/month), the Application Load Balancer (~20 USD/month), two interface VPC endpoints (~30–40 USD/month) and public IPv4 addresses (~11 USD/month) — roughly **190–230 USD/month running 24/7**, or **60–90 USD/month with a "sleep mode"** applied (see also [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)). This is a published architectural estimate, not a confirmed billing line item.

From that figure, a technically plausible mechanism follows: if these fixed-cost resources are left running continuously for several weeks while each service is still being deployed, debugged and redeployed — matching the real deployment cadence in section 2 — the "idle" portion of the bill alone can add up faster than intuition suggests, especially with no spending alert configured yet. This is a **possible contributing factor**, not an incident confirmed against actual billing data for this project.

### 5. Root cause analysis

| Problem | Possible cause | Impact | Evidence | Proposed improvement |
|---|---|---|---|---|
| Fully manual deployment through the Console | No CI/CD built yet | Every change takes manual steps and is hard to repeat identically | [5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/) lists "No CI/CD yet" | Infrastructure as Code (CloudFormation or Terraform) plus a CI/CD pipeline |
| Fixed-cost infrastructure running 24/7 | No automated schedule to pause it outside test sessions | Cost accrues even when nobody is using the system | [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/) lists the "DEV sleep strategy" as "Planned, not yet automated" | Automatically scale Aurora to 0 ACU, Chat to 0 tasks, and delete the NAT Gateway between test sessions |
| No spending alerts | AWS Budgets not configured | Unusual spending is noticed late | [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/) lists an "AWS Budgets alert" as planned | Turn on AWS Budgets with email/SNS notifications |
| No CloudWatch alarms | Not configured | Errors, throttling and a full DLQ are not actively reported | [5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/) lists "No CloudWatch alarms yet" | Alarms for Lambda errors/throttles, DLQ depth, Aurora capacity, Chat target health |
| Secret entered with the wrong value type in a task definition | Manual console entry with no review step before applying | Runtime failure in the container, requiring a new revision to fix | [5.4.10 — Lesson learned](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/) | Review infrastructure changes through a Change Set (CloudFormation) or a pull request (Terraform) before applying |

The table deliberately separates operational causes (not yet automated, no alerting) from the normal cost of running AWS services — not every deployment mistake translates into extra billing, and not every fixed cost is itself a "mistake."

### 6. AWS CloudFormation as a proposed solution

Infrastructure as Code (IaC) addresses exactly this class of problem: instead of remembering and repeating dozens of console steps, the infrastructure is described in files that can be reviewed before they are applied and reproduced identically in another environment.

[AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) manages infrastructure as **stacks**: a template (YAML or JSON) describes the resources to create, accepts **parameters** so it can be reused across environments, returns **outputs** that other stacks can reference, and supports **Change Sets** — a preview of exactly what will be created, changed or deleted before anything is actually applied ([Change Sets documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)). CloudFormation also supports drift detection, to notice when someone has edited a resource directly outside the stack.

**Technical clarification:** CloudFormation does **not** automatically reduce cost — it manages infrastructure as code and makes cleanup of stack-managed resources easier and more consistent. Deleting a stack ([deletion documentation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-delete-stack.html)) also does **not guarantee** every related resource disappears — retention policies, snapshots, resources created outside the stack, or a failed deletion can all leave something that needs manual cleanup.

An illustrative directory layout for this direction:

```text
infrastructure/
├── cloudformation/
│   ├── network.yaml
│   ├── security.yaml
│   ├── database.yaml
│   ├── application.yaml
│   └── monitoring.yaml
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── README.md
```

This layout is illustrative only — the repository has no `infrastructure/` directory today, because everything so far was created by hand through the console, as described in [5.4](../../5-Workshop/5.4-Deployment-Guide/). The project's most recent target-architecture diagram ([Proposal §3](../../2-Proposal/#architecture)) actually names Terraform as its IaC choice; CloudFormation is an equivalent option, tied directly to AWS without an external tool.

{{< mermaid >}}
graph LR
    GIT["Git repository"] --> TPL["CloudFormation templates"]
    TPL --> CS["Change sets<br/>review before apply"]
    CS --> CF["AWS CloudFormation"]
    CF --> DEV["Stack: Development"]
    CF --> STG["Stack: Staging"]
    CF --> PRD["Stack: Production"]
{{< /mermaid >}}

*Figure 3 — Infrastructure management lifecycle with CloudFormation: changes are reviewed through a Change Set before being applied, and each environment is its own stack.*

### 7. Separating Dev, Staging and Production

Today the project has only **one** DEV environment, so this section is a proposal, not the current state.

- **Development** — minimal infrastructure where technically feasible, cost-conscious configuration, temporary resources with controlled cleanup.
- **Staging** — integration testing, deployment validation, production-like configuration where it matters, kept controlled enough to avoid unnecessary spend.
- **Production** — reliability, security, scalability, monitoring and data protection come first.

Identical configuration across all three environments is unnecessarily expensive, but cutting configuration down to the point where it compromises functionality, security or test fidelity is not optimization either — the trade-off has to be deliberate, not arbitrary.

### 8. Cost optimization strategy

- **Cost visibility** — AWS Cost Explorer, AWS Budgets with alerts, cost allocation tags per service (both currently open items, see section 5).
- **Infrastructure lifecycle** — the existing consistent naming convention (`fitness-assistant-dev-<service>-...`) already makes resources filterable by owner; what is missing is a stack-based deletion workflow and a cleanup-confirmation step, matching the full teardown order already documented in [5.7](../../5-Workshop/5.7-Cleanup/).
- **Right-sizing** — choices already applied: Aurora Serverless v2 with a 0.5 ACU floor, Lambda at 1024 MB, OpenSearch Serverless at 0–2 OCU, Fargate at 0.5 vCPU / 1 GB for Chat ([5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)).
- **Automation** — integrating IaC into CI/CD (not yet built), scheduled shutdown of DEV resources outside test hours where technically supported, and a cleanup procedure for failed deployments.
- **Governance** — documented cost ownership, a pre-deployment checklist, environment naming conventions, budget thresholds, and a regular billing review.

A budget alert is not instantaneous — it should be treated as an early signal to investigate, not a hard spending cap that can never be exceeded.

### 9. Current state versus proposed target state

| Criterion | Current state (confirmed) | Proposed target |
|---|---|---|
| Infrastructure provisioning | Manual, through the AWS Console ([5.4](../../5-Workshop/5.4-Deployment-Guide/)) | Infrastructure as Code |
| Environment configuration | Documented step by step, not parameterized | Parameterized, reusable across environments |
| Resource tracking | Manual inspection by naming convention | Stack-based visibility plus resource tags |
| Redeployment | Force new deployment, repeated troubleshooting ([5.4.10](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)) | Controlled updates through Change Sets |
| Cost monitoring | No Budgets or Alarms yet ([5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/), [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)) | Proactive alerts and periodic review |
| Cleanup | A documented checklist exists, not yet run ([5.7](../../5-Workshop/5.7-Cleanup/)) | Stack-based cleanup with a confirmation step |
| Reproducibility | Limited, depends on the operator | Infrastructure under version control |

This compares the **confirmed current state** against a **proposed target**, not the measured result of a completed migration.

### 10. Lessons learned

1. Cloud deployment is an engineering process, not the final step after the code is done.
2. Infrastructure cost should be estimated before provisioning, not discovered after the bill arrives — the budget table in Proposal §8 belongs at the start, not written after the fact.
3. A development environment should be designed around what it actually needs operationally, not copied from production.
4. Automated infrastructure management reduces configuration drift — the Chat service's Value-versus-ValueFrom secret error is a concrete example of where manual steps go wrong.
5. Resource lifecycle management matters as much as initial provisioning — a resource with no cleanup plan eventually costs more than expected.
6. Free credit should be budgeted like a limited resource, not treated as unlimited.
7. Deployment readiness includes operational and cost visibility, not just an application that starts.
8. Infrastructure as Code contributes to long-term maintainability and reproducibility.

### 11. Future improvement roadmap

**Phase 1 — Infrastructure audit** *(partially in place)*: inventory resources by the existing naming convention, use the published estimate in Proposal §8, review the security gaps already recorded in [5.2.5](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/) — still missing: a review of actual billing over time.

**Phase 2 — CloudFormation adoption** *(not started)*: write templates per resource group (network, security, database, application, monitoring), parameterize by environment, test both deployment and stack deletion.

**Phase 3 — Cost governance** *(not started, has a foundation)*: turn on AWS Budgets, extend the existing naming convention into resource tags, write a lifecycle policy for non-production environments, schedule regular cost reviews.

**Phase 4 — Deployment automation** *(not started)*: integrate IaC into CI/CD, use Change Sets to review infrastructure before applying it, add post-deployment verification, and build rollback and cleanup procedures for failed deployments.

### Diagrams

{{< mermaid >}}
graph LR
    A["Application code"] --> B["Docker build"]
    B --> C["Deploy to AWS"]
    C --> D{"Health check"}
    D -- fail --> E["Debug"]
    E --> F["Fix configuration"]
    F --> G["Redeploy"]
    G --> D
    D -- pass --> H["Monitor"]
{{< /mermaid >}}

*Figure 1 — The deployment debugging loop: every failed health check triggers a round of debugging, fixing configuration and redeploying, and each round costs both engineering time and running-resource time.*

{{< mermaid >}}
graph LR
    subgraph AlwaysOn ["Infrastructure running 24/7 regardless of traffic — conceptual"]
        NAT["NAT Gateway"]
        ALB["Chat ALB"]
        FG["Fargate task"]
        AU["Aurora, minimum capacity"]
        VE["VPC interface endpoints"]
        IP["Public IPv4 addresses"]
    end
    NAT --> SUM["Monthly cost<br/>see Proposal §8"]
    ALB --> SUM
    FG --> SUM
    AU --> SUM
    VE --> SUM
    IP --> SUM
    SUM -. if left running for weeks .-> CREDIT["Free or promotional credit<br/>can deplete faster than expected"]
{{< /mermaid >}}

*Figure 2 — A conceptual diagram, not a real billing chart, showing why hourly-billed resources can add up quickly if left running while the system is still being configured and tested.*

### Evidence and limitations

- **Confirmed in this report:** the seven-service plus AI plus Chat architecture; manual console-based deployment spanning 26 Aug – 23 Sep 2026; the Chat service's Value-versus-ValueFrom secret error and its fix; Lambda's secret caching behavior and the `DEPLOY_REVISION` workaround; the absence of CI/CD and CloudWatch alarms; the published budget estimate of ~190–230 USD/month (24/7) or ~60–90 USD/month (sleep mode); the full clean-up order in 5.7, not yet executed.
- **Reported experience, without logs or billing attached in this report:** the general deploy-test-fix-redeploy cadence across weeks.
- **Possible contributing factor, not confirmed by billing data:** fixed-cost infrastructure running continuously during debugging depleting credit faster than expected.
- **Proposed, not yet implemented:** the entire CloudFormation section, Dev/Staging/Production separation, AWS Budgets, CloudWatch Alarms, a scheduled shutdown for idle infrastructure.
- **Already applied in practice (unrelated to CloudFormation):** pay-per-invocation Lambda, Aurora Serverless v2 with a low capacity floor, OpenSearch Serverless at 0–2 OCU, a single shared NAT Gateway, a right-sized Fargate task for Chat — see [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/).

### References

- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)
- [CloudFormation change sets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)
- [Deleting a CloudFormation stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-delete-stack.html)
- [AWS Well-Architected Framework — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
- [AWS Cost Management documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html)
- [Proposal §8 — Budget Estimation](../../2-Proposal/#budget)
- [Workshop 5.2.7 — Cost Optimization and Clean-up](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)
- [Workshop 5.7 — Clean-up](../../5-Workshop/5.7-Cleanup/)
