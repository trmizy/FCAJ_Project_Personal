---
title: "Event 2: AWS for Software & Financial Services Companies Day"
date: 2026-10-08
weight: 2
chapter: false
pre: " <b> 4.2. </b> "
draft: false
---

### Event Name

**AWS for Software & Financial Services Companies Day**

*AI Across Your Entire Engineering Lifecycle, Now Hands-On.* A full-day, hands-on event for software and financial-services engineering teams building with AI, delivered in Vietnamese (levels 200–300).

### Date/Time

**Thursday, October 8, 2026**, 09:00 – 18:00 (Asia/Ho_Chi_Minh)

| Time | Session |
|---|---|
| 09:15 – 09:30 | Welcome Address |
| 09:30 – 10:10 | From Demo to Deployment: Solving Agentic AI's Toughest Challenges |
| 10:10 – 10:50 | Building High-Quality Data Products for AI Agents |
| 10:50 – 11:15 | Networking Break |
| 11:15 – 11:55 | Migration at Scale with AWS Transform |
| 11:55 – 12:15 | Afternoon Workshop Briefing — Choose Your Track |
| 12:15 – 13:15 | Lunch |
| 13:15 – 15:15 | Hands-on workshops: **Workshop A** (Build with Kiro) and **Workshop B** (Bedrock AgentCore with Kiro) |
| 15:15 – 15:35 | Afternoon Break |
| 15:35 – 16:15 | Customer Spotlight: building with AI in production — Bui Hoang Viet, Kyanon Digital |
| 16:30 – 18:00 | Networking Drinks |

### Location / Format

**Sheraton Saigon Grand Opera Hotel**
88 Đồng Khởi, District 1, Ho Chi Minh City, Vietnam

**Format:** In-person (capacity 350)

### Role

Hands-on participant, registered as **Trần Minh Duy**. In the afternoon block I worked in **Workshop A — Build with Kiro: From Spec to Working Application**, building an application myself with Kiro under the guidance of AWS solutions architects.

### Main Content

The morning was a set of talks on building AI into the engineering lifecycle; the afternoon was a hands-on workshop block. This is what each part covered, based on the slides shown.

#### 1. From Demo to Deployment: Solving Agentic AI's Toughest Challenges

The session framed Amazon Bedrock as one platform for **building AI apps and agents at scale**, split into two halves:

- **Models and inference:** models, inference and monitoring, plus fine-tuning, knowledge bases and model distillation.
- **Agent development:** **AgentCore**, an open agent-development platform that works with any model and any framework, and Bedrock Managed Agents powered by OpenAI (OpenAI models and the OpenAI harness).
- **Underneath both:** security, guardrails and governance.

The trust section ended with five takeaways: security is not optional, isolate sessions, integrate with existing identity, enforce policies before execution at scale, and define clear boundaries. Katalon then presented its AI platform for software quality, built on AWS, which independently validates AI-generated code through a governed system of record.

#### 2. Building High-Quality Data Products for AI Agents

This was the most detailed session. Its thread: **an agent is only as good as the data it reads**, so data has to be made "AI-ready".

**One wrong fact poisons every layer.** Quality must be enforced where data is produced, not where it is used. The example was a fintech running a card and lending platform: chargebacks and reversals are stored as separate events and never subtracted, so a metric called `monthly_spend` is wrong. It is published to the catalog with no definition, shown as "spend up 40%, this customer looks healthy", read by a credit-limit agent as fact, and finally raises credit limits for thousands of customers automatically. A person would see the jump and check with operations, so the error stops there; an agent has nobody to question it, so the error becomes an action. Catching it at the source is the job of a **data contract**.

**Anatomy of a data contract.** For the data product `monthly_spend` (v2.1) the contract names a business owner (Card Risk) and a steward (Payments Data Engineering), then covers three areas:

| Area | Element | Example |
|---|---|---|
| Manage | Quality rules | Every reversal matches an original transaction; `net_spend` ≤ settled; a month-on-month jump above 30% is flagged |
| Manage | Freshness | Updated by 06:00 daily; older than 24 hours is flagged as unusable |
| Manage | Version | Changes reviewed and announced to every consumer before release |
| Understand | Schema | Named columns; breaking changes need a new version |
| Understand | Meaning | `net_spend` = settled − chargebacks − reversals, per calendar month |
| Protect | Access | The agent reads totals only, no card numbers; every read is logged |

"No contract, no data product: just a table someone hopes is right."

**What "AI-ready" has to mean now.** Every judgment a human analyst supplied for free has to live in the data itself, in five properties: **trusted** (accurate, fresh and validated before the agent sees it), **contextual** (business meaning made explicit), **traceable** (what the agent did, and why, captured as it happens), **governed** (bounded by design: scoped, controlled, auditable) and **operational** (actionable, not just readable). Miss one, and the agent does not degrade gracefully the way a person would; it fails confidently.

**Four building blocks, in the order to build them:** (1) data contracts and quality, (2) traceability and governance, (3) the context layer, (4) from searchable to actionable. The order matters: start with quality, because every layer built on top inherits its mistakes.

**One copy, any engine, any agent.** A data product only helps agents if every engine and agent can reach it: open table formats (store it once, for example in Apache Iceberg on Amazon S3 Tables), open engines (Athena, Redshift and Spark on EMR or Glue read the same table through the Glue Data Catalog), and open protocols (agents use data and tools through MCP and hand work to other agents through A2A, via AgentCore Gateway and Runtime). The contract travels with the data: the same quality checks, catalog entry and Lake Formation permissions apply to every reader.

**Data retrieval, the core problem.** Before writing agent code, answer three questions: what data does the agent need, where does it live, and which retrieval mechanism fits. Four mechanisms were compared: semantic search / RAG (unstructured content), structured lookup (exact records through SQL or an API), graph traversal (entity relationships and multi-hop paths) and cached context (stable, high-frequency context). One rule stood out: design for silence, not just bad data, because agents hallucinate from absent data as well as wrong data.

**Chat with your data.** Text-to-SQL becomes much more accurate and deterministic with a semantic layer, 25–50 percentage points better regardless of the model. The reasoning-effort setting made little difference, and the quality of data modeling was the key driver of determinism.

**How Vanguard built AI-ready data** (AWS Machine Learning Blog, April 2026): eight principles — a data product and operating model with an owner per asset, governance and security, a unified metadata catalog, a semantic layer, ground-truth examples (50+ question-to-SQL pairs), automated quality checks, change control with definitions as code, and continuous evaluation. Results: time-to-insight from days to minutes, self-service without SQL, high SQL accuracy, and reuse across the business.

#### 3. Migration at Scale with AWS Transform

AWS Transform automates large-scale code modernisation — Java upgrades, .NET porting, framework migrations and tech-debt removal — by describing the transformation in natural language and letting autonomous agents plan, execute and validate the changes. The reference architecture shown for orchestrating a migration had these parts:

- **People and surface:** engineers and approvers work from Kiro (IDE or CLI), which drives AWS Transform jobs and approval gates through MCP servers.
- **AWS Transform:** one migration agent made of composable job steps (perform discovery, build a migration plan, build a landing zone, migrate network, migrate servers, containerize), with chat approvals, approvers for plan, network and cutover, and a worklog as the audit trail.
- **Source and target:** a source environment (VMware, Hyper-V, Nutanix, KVM, bare metal) with a discovery tool, and multi-account AWS targets with a Control Tower landing zone and infrastructure as code (CloudFormation, CDK, Terraform).
- **Custom agents on AgentCore:** an Agent Builder toolkit lets custom agents run on Amazon Bedrock AgentCore (runtime, gateway, identity through Cognito, memory, guardrails with Cedar policy, CloudWatch and CloudTrail) and integrate with ticketing (ServiceNow, Jira) and SNS notifications.

#### 4. Workshop A — Build with Kiro: From Spec to Working Application (the track I attended)

Workshop A teaches spec-driven development in Kiro, AWS's agentic IDE, by building an application from scratch with AWS solutions architects on hand. It ran as a guided "Kiro Express" workshop on AWS Workshop Studio: attendees joined the event with an access code, opened Kiro from the event outputs, and followed the workshop steps starting from "Initialize the project". Nothing had to be installed and no AWS account was needed. AWS sponsored **1,000 Kiro credits per attendee, valid for one day**, so everyone could build and test freely with the newest Claude Opus model.

The application I built was a web game: I turned **Flappy Bird into "Flappy Kiro"**. The process followed Kiro's spec workflow:

1. **Requirements.** Describe the game I wanted; Kiro drafts the requirements and I review them.
2. **Design.** Kiro drafts the design and a task plan from the approved requirements, which I review before any code is written.
3. **Build and fix.** Guide Kiro through the tasks and fix issues as they appear.
4. **Run and test.** Run the app and play-test the game.

The outcome is a working app built spec-first, and a workflow that can be reused on the next feature. What made the session valuable was seeing the whole process of building an application with Kiro, from a plain-language idea to a running game, not only the end result.

*Workshop B, in the same time slot, was the other track (not attended): build an AI agent with Kiro, deploy it on Amazon Bedrock AgentCore, extend it step by step, and see what it takes to run agents in production.*

#### 5. Customer Spotlight — Kyanon Digital

Bui Hoang Viet, DevOps Engineer at Kyanon Digital, spoke on *Beyond Single-YAML: Taming the Blast Radius of LLM Remediation in Kubernetes*.

- **LLM remediation today** works one unit at a time: a Trivy finding becomes a prompt, the LLM writes a patched YAML, which is dry-run and then applied. Published results look strong: 0.990 precision (GenKubeSec) and 94% repair success on 1,000 manifests (LLMSecConfig). The weakness is the input unit: **one finding plus one manifest**, with no view of how services call each other.
- **The proposed system** adds cluster context. Trivy findings and Prometheus mesh metrics (call-graph edges) are merged into a ClusterContext. The **upper branch** decides which attack paths matter most: a prioritiser ranks the top-k paths (Bellman-Ford), and an LLM annotator labels them with MITRE ATT&CK techniques (retrieved from a FAISS index) and writes a risk narrative, producing an attack report. The **lower branch** writes a patch and then checks it: remediation generates the patch, validates the schema and runs a health gate, and a "functional blast radius" check confirms that the finding is cleared, the call edges are preserved and the health gate passes.
- **The test cluster** had 36 deployments, 4 namespaces, 51 call edges and 31 injected findings. 25 were topology-dependent (the correct fix needs a value only the running cluster has) and 6 topology-independent (the fix is fully written in the finding text), which served as the control group.

The point of the talk: a patch that closes a finding can still break the service next to it, so remediation has to be judged by its blast radius, not only by whether the finding disappears.

### Photos / Video

**Photo 1: At the event backdrop**
![At the AWS for Software & Financial Services Companies Day backdrop](/images/events/aws-sw-fsi-day-1.png)
*At the entrance of the event, Sheraton Saigon Grand Opera, October 8*

**Photo 2: Workshop briefing on stage**
![Presenter introducing Workshop B on stage](/images/events/aws-sw-fsi-day-2.png)
*The afternoon workshop briefing, introducing both tracks; the slide shows Workshop B on Amazon Bedrock AgentCore with Kiro*

**Photo 3: Event badge**
![Event badge for Trần Minh Duy](/images/events/aws-sw-fsi-day-3.png)
*My attendee badge*

### Lessons Learned

**1. A working demo is not a production service.**
The opening session and the Workshop B description say the same thing: build, deploy, extend, then operate. Amazon Bedrock and AgentCore put security, guardrails and governance underneath every model and agent, not on top as an afterthought. Deploying Fitness Assistant to AWS showed the same gap: a service that runs locally still needs security, monitoring and a repeatable deploy before it counts as production.

**2. One wrong fact poisons every layer, so quality must be enforced where data is produced.**
The fintech example showed a missing subtraction in one metric (`monthly_spend`) travelling through the pipeline, the catalog and the semantic layer until an agent used it to raise credit limits for thousands of customers. A person would notice the jump and ask; an agent has nobody to question it, so the error becomes an action. The fix is a **data contract**: a named owner and steward, quality rules, freshness, versioning, an explicit meaning, and bounded access with every read logged. For Fitness Assistant this is the reason each kind of data has one authoritative owner, and a forecast never overwrites an actual measurement.

**3. "AI-ready" data means five things: trusted, contextual, traceable, governed and operational.**
Every judgment a human analyst supplies for free has to live in the data itself. Miss one, and an agent does not degrade gracefully the way a person would; it fails confidently. This is why the AI coach only proposes and waits for the user's confirmation, and why every recommendation is recorded so the decision can be explained afterwards.

**4. Retrieval has to be designed, including for silence.**
Before writing agent code, decide what data the agent needs, where it lives and which retrieval mechanism fits: semantic search for documents, structured lookup for exact records, graph traversal for relationships, cached context for stable rules. Agents hallucinate from absent data as well as wrong data, so retrieval should return an explicit "nothing found". A semantic layer made text-to-SQL 25–50 percentage points more accurate regardless of the model, which means data modeling matters more than a bigger model.

**5. Fix quality first, and expose the data once through open standards.**
The order of the four building blocks matters: start with data contracts and quality, then traceability and governance, then the context layer, then making data actionable. One copy of the data in an open format, readable by every engine and agent through MCP and A2A, avoids copies drifting apart and avoids locking every agent into one tool.

**6. A fix is only good if it does not break its neighbours.**
Kyanon's talk showed that LLM remediation can look excellent per finding (0.990 precision, 94% repair success) while a patch still breaks the service next to it. Judging a change by its "blast radius" — the finding is cleared, the call edges are preserved, the health gate passes — is the same discipline as verifying a deploy with a post-apply check.

**7. Security boundaries come before scale.**
The trust takeaways were: security is not optional, isolate sessions, integrate with existing identity, enforce policies before execution at scale, and define clear boundaries. They match how the project separates users: every user-owned surface has to stay isolated across logout, login and account switch.

**8. Spec-first development fits a project with strict ownership rules.**
Building Flappy Kiro in Workshop A — requirements, then design, then a task plan, then build and play-test — mirrors how Fitness Assistant changes are handled: investigate, decide what owns the data, then implement. Reviewing the requirements and design before any code is written is what keeps the result predictable.

### Personal Contribution

I attended in person and followed the morning sessions. In Workshop A I did the hands-on work myself: I used Kiro with the newest Claude Opus model (on the 1,000 credits AWS sponsored for the day) to turn Flappy Bird into Flappy Kiro, going through requirements, then design, then running and testing the app. I then compared this spec-first workflow with how Fitness Assistant changes are designed and implemented.

### Evidence Link

**Official event page:**
[AWS for Software & Financial Services Companies Day](https://aws-experience.com/apj/smb/event/a838fd41-1aeb-4ee8-a3d9-636583344707)

**Registration ticket:**
[My Event Ticket](https://luma.com/e/ticket/evt-7FMzezxlttxLCjI?pk=g-ZTbdpfRmRBdRrtW)

**Key information:**
- **Time:** Thursday, October 8, 2026, 09:00 – 18:00
- **Location:** Sheraton Saigon Grand Opera Hotel, 88 Đồng Khởi, District 1, Ho Chi Minh City
- **Evidence:** the registration ticket and the photos above (event backdrop, workshop briefing, attendee badge)
