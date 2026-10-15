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
- Learn how to secure retrieval-augmented generation (RAG) shared by many teams with Amazon Bedrock and Amazon Verified Permissions

### Work Completed This Week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Wrote Blog 2, "Secure Multi-tenant RAG with Amazon Bedrock and Verified Permissions", and published it to the AWS Study Group VN Facebook group | 28-9-2026 | 03-10-2026 | [Original article on the AWS Architecture Blog](https://aws.amazon.com/blogs/architecture/secure-multi-tenant-rag-with-amazon-bedrock-and-verified-permissions/) <br>[Post on Facebook](https://www.facebook.com/share/p/19qBt1z5fU/) |

### Week 9 Results:

**Overview:**

This week was dedicated to community contribution and knowledge sharing. I studied an AWS Architecture Blog article on keeping one shared RAG knowledge base safe for many departments, then wrote and published Blog 2 about it for the AWS Study Group VN, relating it to the AI service of the Fitness Assistant.

**Theoretical Knowledge Gained:**

- **Document-level authorization for RAG:** One shared Amazon Bedrock Knowledge Base whose documents carry a `department` metadata attribute, and Cedar policies in Amazon Verified Permissions that decide at retrieval time which documents each user may use. Rules change without redeploying code.

- **Defense in depth:** Two independent layers that both fail closed: a Lambda authorizer on API Gateway for API access, and a middleware Lambda that turns the policy decision into a metadata filter for `RetrieveAndGenerate`. Guardrails for Amazon Bedrock then checks that the answer is grounded.

- **Technical Writing:** Learned how to effectively communicate technical concepts to a broader audience.

**Hands-on Labs Completed:**

- Wrote and published Blog 2 in the AWS Study Group VN Facebook group

**Application to Fitness Assistant:**

The AI service of the Fitness Assistant already does RAG with Amazon Bedrock and a vector index on OpenSearch Serverless, filled by scheduled jobs from shared sources such as PubMed, RSS feeds and web articles. The pattern from the blog applies as soon as private documents enter that index:
- A metadata attribute such as `gym_id` on each private document
- A Cedar policy per gym instead of one index per gym
- A short authorizer cache, so revoked access ends quickly
- Fail-closed behavior when the policy service is unavailable

### Related Workshop Links:

- [3.2 Blog 2](../../3-BlogsPosted/3.2-Blog2/) - Secure Multi-tenant RAG with Amazon Bedrock and Verified Permissions
- [5.4.9 AI Service — vector search, scheduling and API](../../5-Workshop/5.4-Deployment-Guide/5.4.9-AI-Service-Vector-Search/) - The vector search the blog relates to
