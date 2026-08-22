---
title: "Event 1: FCAJ Community Day August"
date: 2026-08-22
weight: 1
chapter: false
pre: " <b> 4.1. </b> "
---

### Event Name

**FCAJ Community Day August**

### Date/Time

**Saturday, August 22, 2026**
- 08:00 – 09:00: Check-in
- 09:00 – 12:00: Technical sessions

### Location / Format

**Bitexco Financial Tower**  
2 Đ. Hải Triều, Sài Gòn, Hồ Chí Minh, Vietnam

**Format:** In-person

### Role

Attendee

### Main Content

On the morning of August 22, 2026, I attended FCAJ Community Day August at Bitexco Financial Tower. The event focused on AWS, Serverless, database optimization, Generative AI, Agentic AI, and Cloud Operations. Here's what I learned from the sessions:

#### 1. Development Application with AWS Serverless

This session introduced Serverless Computing and compared traditional application development with Serverless. The demo showed practical AWS Serverless application patterns.

**Key points:**
- Serverless doesn't mean no servers, but rather developers don't need to manage servers.
- Benefits include automatic scaling and pay-per-use.
- Trade-offs to consider: cold start, execution time limits, stateless design.

**Connection to Fitness Assistant:**  
Serverless gives me another perspective on how certain workloads can be separated from continuously running backends. For example, event-driven tasks (sending notifications, image processing, nutrition calculations) or scheduled tasks (daily statistics aggregation) could consider using AWS Lambda instead of running services 24/7.

#### 2. Optimizing Database Cost & Performance with Data Archiving Strategies

This session dived deep into database growth and operational challenges as data increases. Content included data archiving architecture, initial data load design, daily incremental archiving, and cost optimization techniques.

**Key points:**
- Not all data needs high-performance access.
- Data lifecycle and retention policy should be designed from the start.
- Cost optimization by separating hot data and cold data.

**Connection to Fitness Assistant:**  
The Fitness Assistant project can generate significant data over time such as weight history, InBody measurements, workout logs, nutrition logs, and activity history. From this session, I understand that as data volume increases, we shouldn't just think about scaling the current database but also consider:
- Which data needs frequent access (recent workouts, current stats)
- Which data can be archived (historical data from 1-2 years ago)
- Retention policy and storage cost
- Query performance optimization

This is a direction that needs further research as the system grows.

#### 3. Diffusion and OCR

Session on AWS services for Text-to-Image generation and Image-to-Text extraction. The demo showed real-world use cases in image processing and analysis.

**Key points:**
- Amazon Textract for OCR.
- Amazon Rekognition for image analysis.
- Integration with other AI services.

**Connection to Fitness Assistant:**  
This session helps me think more about future AI capabilities for Fitness Assistant. For example, OCR could be useful when users photograph nutrition labels to automatically extract nutritional information, or analyze images to assess posture during workouts. However, this is a future expansion direction; the project doesn't currently have this functionality.

#### 4. Agentic AIOps on AWS: Inside AWS DevOps Agent

This was one of the most important sessions for my internship process. Content included AWS DevOps Agent, operational challenges, incident troubleshooting, investigation workflow, architecture overview, and security boundaries.

**Key points:**
- Agent automatically analyzes logs and metrics to create hypotheses.
- Collects evidence from multiple sources (CloudWatch, X-Ray, logs).
- Provides recommendations based on context.
- Security boundaries and controlled automation.
- MCP (Model Context Protocol) extensibility.

**Direct connection to Fitness Assistant:**  
When deploying a system with multiple services like Fitness Assistant, we don't just care about whether the application runs but also need to consider:
- Monitoring: which service is having issues?
- Logs: where in the flow do errors occur?
- Incident investigation: why can't service A connect to service B?
- Root cause analysis: is the problem network, security group, or application logic?
- Security boundary: ensure automated actions don't cause risks.
- Observability: is there enough information to troubleshoot?

This session directly relates to what I'm learning about Amazon CloudWatch and monitoring during my internship. I realize that a good production system needs the ability to self-observe and effectively support troubleshooting.

#### 5. From Local to Global: Migrating a GenAI Product to AWS

This session is particularly relevant to Fitness Assistant because the project has an AI service. Content included challenges when migrating GenAI product, moving from Azure OpenAI to Amazon Bedrock, Agentic AI systems, guardrails, evaluation frameworks, and operational governance.

**Key points:**
- An AI production system is more than just calling a model API.
- Need guardrails to control output.
- Evaluation framework to assess quality.
- Operational governance for security and compliance.
- Migration considerations regarding cost, latency, model availability.

**Connection to Fitness Assistant:**  
This is especially meaningful because the project has an ai-service. The session helps me understand that when bringing AI workload to AWS, we need to consider:
- Model integration architecture
- Security and data privacy
- Guardrails to ensure appropriate AI responses
- Evaluation to ensure quality
- Monitoring AI performance
- Governance and compliance
- Scalability and operational cost

The session gives me additional perspective on Amazon Bedrock as a direction worth considering in the future when expanding Fitness Assistant's AI capabilities. However, the project hasn't migrated to Bedrock yet.

#### 6. Agentic Decision Intelligence on AWS

This session introduced Agentic Decision Intelligence and how AI Agents support business decision-making. Content included intelligent decision workflows, banking use cases, and Amazon QuickSight.

**Key points:**
- AI Agent is more than a chatbot answering questions.
- Agent can collect context, analyze data, and support decisions.
- Workflow based on rules and actual data.
- Transform data into business insights.

**Connection to Fitness Assistant:**  
This session expands how I think about AI in Fitness Assistant. AI Agent could:
- Collect context about users (workout history, nutrition, health metrics)
- Analyze patterns and trends
- Provide personalized recommendations based on actual data
- Adjust workout plans based on progress

This is an interesting development direction for AI Fitness Assistant in the future - not just answering questions but also proactively analyzing and providing recommendations based on each user's profile.

#### 7. AWS Principles Beyond AWS: How AWS Knowledge Transfers to Cloud-Native Roles

The final session talked about how AWS knowledge isn't limited to using AWS services. Content included operational principles, release management, incident recovery, security operations, and cloud-native skills.

**Key points:**
- AWS knowledge is the foundation for cloud-native thinking.
- Principles like automation, infrastructure as code, monitoring, security apply to many platforms.
- Skills transferable across cloud providers.

**Connection to internship process:**  
Through learning AWS during my internship, I realize what's important isn't just remembering service names but understanding:
- How distributed systems work
- Security best practices
- Scalability and high availability
- Monitoring and observability
- Deployment strategies
- Cost optimization
- Troubleshooting methodology

These principles have long-term value, not limited to AWS.

### Photos / Video

**Photo 1: Technical session with Architecture Overview**
![Technical session](/images/events/fcaj-aug-2026-1.jpg)
*Attending AWS architecture presentation at FCAJ Community Day August*

**Photo 2: At AWS Office**
![Selfie at AWS Office](/images/events/fcaj-aug-2026-2.jpg)
*Check-in at FCAJ Community Day August - Bitexco Financial Tower*

**Photo 3: Pipeline and Release Management Session**
![Pipeline session](/images/events/fcaj-aug-2026-3.jpg)
*Session on incident troubleshooting and investigation workflows*

**Photo 4: Serverless Application Structure Demo**
![Serverless demo](/images/events/fcaj-aug-2026-4.jpg)
*Demo of serverless application structure with Lambda function apps*

**Photo 5: Development Application with AWS Serverless**
![Serverless session](/images/events/fcaj-aug-2026-5.jpg)
*Session introducing Serverless Computing and application patterns*

### Lessons Learned

After attending FCAJ Community Day August, I learned important lessons:

**1. AWS architecture is more than deploying applications**

A production system needs to simultaneously consider compute, database, monitoring, security, cost, and scalability. We can't just focus on "code works" while ignoring operational aspects.

**2. Serverless is an architecture worth considering for certain workloads**

Not every workload needs a continuously running server/service. Serverless can be useful for event-driven tasks, scheduled tasks, background processing, and intermittent workloads. However, trade-offs regarding cold start, execution limits, and stateless design need to be considered before applying to Fitness Assistant.

**3. Database needs to be designed for long-term growth**

For Fitness Assistant, workout, nutrition, and InBody measurement data can increase very rapidly over time and number of users. Therefore, we need to think early about data lifecycle, retention policy, archiving strategy, performance optimization, and cost management.

**4. GenAI production needs more than a model**

From the GenAI migration session, an important lesson is that AI production must have guardrails, evaluation framework, monitoring, security, and governance. We can't just integrate a model API and consider it done. We need to design a complete architecture to ensure the AI system operates stably, safely, and with quality.

**5. Observability and troubleshooting are mandatory**

The Agentic AIOps session showed the value of logs, metrics, evidence-based analysis, and root cause investigation. This directly relates to what I'm learning about CloudWatch for Fitness Assistant. A good system needs the ability to self-observe and effectively support developers in troubleshooting when issues arise.

**6. AI Agents can develop beyond chatbots**

Agents can collect context, analyze data, and support decision-making instead of just answering questions. This is an interesting research direction for Fitness Assistant in the future - AI can proactively analyze workout patterns, nutrition trends, and health metrics to provide personalized recommendations.

**7. Cloud-native thinking has long-term value**

AWS knowledge isn't just learning how to use AWS Console. Operational principles like automation, infrastructure as code, security, monitoring, cost optimization, and troubleshooting methodology are transferable skills with long-term value in a cloud-native career path.

### Personal Contribution

I attended FCAJ Community Day August in person as an attendee. Throughout the event, I:
- Followed all technical sessions from 09:00 to 12:00
- Noted knowledge related to AWS, Serverless, database optimization, Generative AI, Agentic AI, and AIOps
- Compared acquired knowledge with the Fitness Assistant architecture being implemented during my internship
- Identified directions needing further research such as Amazon Bedrock, Serverless patterns, data archiving strategies, CloudWatch monitoring, and operational best practices

Sessions particularly relevant to the project include:
- **Agentic AIOps on AWS** - directly related to monitoring and troubleshooting I'm learning
- **From Local to Global: Migrating a GenAI Product to AWS** - important because Fitness Assistant has an ai-service
- **Optimizing Database Cost & Performance** - necessary for designing data lifecycle for workout and nutrition data
- **Development Application with AWS Serverless** - expands perspective on architecture patterns

### Evidence Link

**Official event page:**  
[FCAJ Community Day August – Luma](https://luma.com/m8h7l900)

**Key information:**
- **Host:** Huỳnh Hoàng Long
- **Time:** Saturday, August 22, 2026 - 9:00 AM to 12:00 PM
- **Location:** Bitexco Financial Tower, Ho Chi Minh City
