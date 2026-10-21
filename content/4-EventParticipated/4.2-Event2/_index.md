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

The morning was a set of talks on building AI into the engineering lifecycle; the afternoon was a hands-on workshop block. This is what each part covered:

#### 1. From Demo to Deployment: Solving Agentic AI's Toughest Challenges

Agentic AI demos well, but deployment needs operational excellence, data governance, reliability and trust. The session walked through the four pillars that separate a proof of concept from production, with practical solutions using Amazon Bedrock and Bedrock AgentCore. Katalon then presented its AI platform for software quality, built on AWS, which independently validates AI-generated code through a governed system of record.

**Connection to Fitness Assistant:**
The project's AI service already runs on Amazon Bedrock. The same pillars — reliability, governance, trust — apply to the AI coach, which is why it only proposes plans and waits for the user to confirm before anything is saved.

#### 2. Building High-Quality Data Products for AI Agents

AI agents are only as good as the data they consume. The session covered patterns for data products that agents can trust: quality, schema design for agent consumption, and real-time integration.

**Connection to Fitness Assistant:**
The coach reads measurements, profile and workout history. Keeping one authoritative source for each kind of data is the project's equivalent of a trustworthy data product.

#### 3. Migration at Scale with AWS Transform

AWS Transform automates large-scale code modernisation — Java upgrades, .NET porting, framework migrations and tech-debt removal — by describing the transformation in natural language and letting autonomous agents plan, execute and validate the changes.

#### 4. Workshop A — Build with Kiro: From Spec to Working Application (the track I attended)

Workshop A teaches spec-driven development in Kiro, AWS's agentic IDE, by building an application from scratch with AWS solutions architects on hand. AWS sponsored **1,000 Kiro credits per attendee, valid for one day**, so everyone could build and test freely with the newest Claude Opus model.

The application I built was a web game: I turned **Flappy Bird into "Flappy Kiro"**. The process followed Kiro's spec workflow:

1. **Requirements.** Describe the game I wanted; Kiro drafts the requirements and I review them.
2. **Design.** Kiro drafts the design and a task plan from the approved requirements, which I review before any code is written.
3. **Build and fix.** Guide Kiro through the tasks and fix issues as they appear.
4. **Run and test.** Run the app and play-test the game.

The outcome is a working app built spec-first, and a workflow that can be reused on the next feature. What made the session valuable was seeing the whole process of building an application with Kiro, from a plain-language idea to a running game, not only the end result.

*Workshop B, in the same time slot, was the other track (not attended): build an AI agent with Kiro, deploy it on Amazon Bedrock AgentCore, extend it step by step, and see what it takes to run agents in production.*

#### 5. Customer Spotlight — Kyanon Digital

Bui Hoang Viet, DevOps Engineer at Kyanon Digital, spoke on *Beyond Single-YAML: Taming the Blast Radius of LLM Remediation in Kubernetes*, a talk about real engineering teams running AI in production.

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
