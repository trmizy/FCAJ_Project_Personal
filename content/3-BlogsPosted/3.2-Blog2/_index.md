---
title: "Blog 2: Secure Multi-tenant RAG with Amazon Bedrock and Verified Permissions"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 3.2. </b> "
draft: false
---

## Secure Multi-tenant RAG with Amazon Bedrock and Verified Permissions

**Original article:** [Secure multi-tenant RAG with Amazon Bedrock and Verified Permissions](https://aws.amazon.com/blogs/architecture/secure-multi-tenant-rag-with-amazon-bedrock-and-verified-permissions/) (AWS Architecture Blog, 22 June 2026)

**Shared on Facebook:** https://www.facebook.com/share/p/19qBt1z5fU/

---

In a generative AI assistant shared by a whole company, every department wants answers from the same pool of documents, but not every employee should see every document. Finance reports belong to finance and HR files to HR, while managers may need to read across departments. A recent post on the AWS Architecture Blog shows how to enforce this inside one shared knowledge base, by deciding at retrieval time which documents each user is allowed to use.

### 1. Why the obvious approaches do not scale

- **One knowledge base per department:** the isolation is clear, but cost and operations grow with every new team.
- **Filters hard-coded in the application:** a metadata filter such as `department = finance` works, but every rule change means editing code and redeploying.
- **No central record of decisions:** when access logic is spread across code, it is hard to answer "why could this user see that document?".

### 2. The solution: one knowledge base, two authorization layers

All documents live in one Amazon Bedrock Knowledge Base and carry a `department` metadata attribute. Access rules are written as Cedar policies in Amazon Verified Permissions and evaluated on every request:

- **Layer 1, API access.** A Lambda authorizer on Amazon API Gateway verifies the Amazon Cognito JWT and calls `IsAuthorized` for each of the caller's groups. If no group is allowed, or Verified Permissions returns an error, the caller gets HTTP 403.
- **Layer 2, document access.** A middleware Lambda asks Verified Permissions which department knowledge bases the caller may query, and turns the answer into a metadata filter for `RetrieveAndGenerate`: `equals` for one department, `orAll` for several. The same policy store decides which model the caller may invoke.
- **Output check.** Guardrails for Amazon Bedrock checks that the answer is grounded in the retrieved context and filters harmful content.

In the article's example, dept-a and dept-b may query only their own documents and use Claude 3 Haiku, while dept-c may query every department and uses Amazon Nova Lite 2. Anything not permitted is denied by default, and a policy change applies on the next request without redeploying any code.

### 3. How a request flows

{{< mermaid >}}
graph LR
  U[User with Cognito JWT] --> W[CloudFront and AWS WAF]
  W --> G[API Gateway]
  G -- Layer 1 --> A[Lambda authorizer]
  A -- IsAuthorized --> P[Verified Permissions]
  G --> M[Middleware Lambda]
  M -- Layer 2 --> P
  M -- metadata filter --> K[Bedrock Knowledge Base]
  K --> R[Guardrails]
  R --> O[Grounded answer]
{{< /mermaid >}}

1. **AWS WAF** applies rate limits and rules. If it denies, the request is blocked.
2. **Lambda authorizer (Layer 1)** checks whether the caller may invoke the API. If not, the answer is 403.
3. **Middleware (Layer 2)** works out which departments the caller may read. If none, the result is empty.
4. **Bedrock Knowledge Bases** applies the metadata filter before the vector search, so the model never sees an unauthorized document.
5. **Guardrails** checks that the answer is grounded. If not, it is blocked or modified.

### 4. Tagging documents at ingestion

1. A file uploaded to S3 under a department prefix (for example `docs/dept-a/report.pdf`) triggers an EventBridge event, which is queued in SQS.
2. A Lambda function writes a `.metadata.json` sidecar next to the file, `{"metadataAttributes": {"department": "dept-a"}}`. Failed attempts go to a dead-letter queue.
3. Every five minutes a scheduled Lambda calls `StartIngestionJob`. Bedrock chunks the documents (300 tokens with 20% overlap), embeds them and indexes them together with their department attribute.
4. A document without a sidecar is skipped and logged, so an untagged file never becomes visible to everyone.

### 5. Safe deployment checklist

- **Know the isolation level.** This is filter-level (logical) isolation, not isolation enforced by IAM or separate infrastructure. For different customers of a SaaS product, the article recommends one knowledge base per tenant.
- **Fail closed.** Both layers deny when Verified Permissions is unavailable. Caching the last known decisions would improve availability, but could keep honouring revoked access.
- **Keep the authorizer cache short.** The API Gateway default of 300 seconds can keep revoked access alive for up to five minutes. A TTL of 0 or 30–60 seconds revokes faster, at the cost of more Verified Permissions calls.
- **Protect the policies and the tags.** Restrict who can create, update or delete policies, log every change with CloudTrail, and let only the tagging Lambda write sidecar files. S3 Versioning and Object Lock help here.
- **Mind the ingestion window.** There is a short gap between an upload and its sidecar. The SQS batching window (30 seconds by default) should fit the ingestion schedule.
- **Guardrails are not a complete defence** against prompt injection, so input length checks and query sanitization are still needed.

### Personal view

What I like most in this pattern is that authorization becomes data instead of code. Adding a department takes a Cedar policy, a Cognito group and tagged documents, with no new infrastructure.

The AI service of Fitness Assistant already does retrieval-augmented generation with Amazon Bedrock and a vector index on OpenSearch Serverless (see Workshop [5.4.8](../../5-Workshop/5.4-Deployment-Guide/5.4.8-AI-Service-Core/) and [5.4.9](../../5-Workshop/5.4-Deployment-Guide/5.4.9-AI-Service-Vector-Search/)). Its index is filled by scheduled jobs from shared sources such as PubMed, RSS feeds and web articles. Access is controlled per function with IAM: each Lambda role may invoke only the Bedrock models it needs, and the AI routes are throttled in API Gateway. The article's pattern becomes useful as soon as private documents enter that index, for example a gym's internal material that only its own trainers and members should see. A Cedar policy per gym and a `gym_id` metadata attribute would then fit better than one index per gym.

### Conclusion

The pattern combines three ideas: one shared knowledge base with metadata, Cedar policies that live outside the code and change at runtime, and two independent layers that both fail closed. It is a cost-effective way to give each department its own view of shared data, as long as the team remembers that the isolation is logical and protects the policies and tags as carefully as the documents themselves.

### References

- AWS Architecture Blog: [Secure multi-tenant RAG with Amazon Bedrock and Verified Permissions](https://aws.amazon.com/blogs/architecture/secure-multi-tenant-rag-with-amazon-bedrock-and-verified-permissions/)
- [Amazon Verified Permissions documentation](https://docs.aws.amazon.com/verifiedpermissions/)
- [Amazon Bedrock Knowledge Bases documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)
- [Cedar policy language](https://www.cedarpolicy.com/)
