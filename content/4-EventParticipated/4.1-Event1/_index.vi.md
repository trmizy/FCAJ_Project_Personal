---
title: "Sự kiện 1: FCAJ Community Day August"
date: 2026-08-22
weight: 1
chapter: false
pre: " <b> 4.1. </b> "
---

# FCAJ COMMUNITY DAY AUGUST

## Báo cáo sự kiện FCAJ Community Day August

### 1. Mục tiêu của sự kiện

FCAJ Community Day August được tổ chức nhằm mang đến không gian chia sẻ kiến thức thực chiến về AWS, Serverless Computing, database optimization, Generative AI và Cloud Operations cho cộng đồng developers và cloud engineers.

Sự kiện tập trung vào các chủ đề kỹ thuật nóng như kiến trúc Serverless, tối ưu hóa cost và performance cho database, Agentic AI, AIOps, và cách migrate GenAI workload lên AWS. Thông qua những trải nghiệm thực tế từ các diễn giả đang làm việc tại các công ty công nghệ và ngân hàng, người tham dự được trang bị kiến thức và best practices để áp dụng vào dự án thực tế.

### 2. Thông tin chung

- **Tên sự kiện:** FCAJ Community Day August
- **Thời gian:** Thứ Bảy, 22/08/2026 (08:00-09:00 Check-in, 09:00-12:00 Technical sessions)
- **Địa điểm:** Bitexco Financial Tower, 2 Đ. Hải Triều, Sài Gòn, Hồ Chí Minh
- **Vai trò:** Người tham dự
- **Đơn vị tổ chức / Hỗ trợ:** First Cloud AI Journey Community & AWS
- **Hình thức:** Tham gia trực tiếp (In-person)

### 3. Diễn giả và chủ đề chính

Dưới đây là danh sách các diễn giả và chủ đề đã được trình bày tại sự kiện:

| Diễn giả | Tổ chức / Vai trò | Chủ đề trình bày |
|---|---|---|
| Kiet Lam | Senior Developer Engineer, FPT Software | Development Application with AWS Serverless |
| Kiet Nguyen & Viet Ly | Software Engineer & DevOps, VPBank | Optimizing Database Cost & Performance with Data Archiving Strategies |
| Long Huynh | Senior Solutions Architect, eCloudvalley | Diffusion and OCR |
| Vi Tran | CloudOps Engineer, VIB | Agentic AIOps on AWS: Inside AWS DevOps Agent |
| Ngoc Tran | Service Delivery Engineer Intern, Accenture | From Local to Global: Migrating a GenAI Product to AWS |
| Xuan Le & Nghi Danh | Data Analytics & Insights, AI Engineer (Renova Cloud) | Agentic Decision Intelligence on AWS |
| Bao Huynh | Cloud Native Developer, Endava Viet Nam | AWS Principles Beyond AWS |

### 4. Nội dung chi tiết đã học được

#### Development Application with AWS Serverless

Speaker Kiet Lam giải thích rằng Serverless giúp developer giảm đáng kể khối lượng công việc quản lý server và infrastructure như OS patching, scaling, và một phần vận hành hạ tầng. Nhờ đó developer có thể tập trung nhiều hơn vào việc viết code và delivery sản phẩm.

**Những điểm cốt lõi:**
- **Mô hình event-driven/on-demand:** Serverless hoạt động theo cơ chế được kích hoạt khi có event hoặc request, không cần duy trì server chạy liên tục 24/7.
- **Auto-scaling:** Hệ thống tự động scale theo traffic và có thể scale về zero khi không còn workload, rất phù hợp với workload không chạy liên tục hoặc traffic khó dự đoán.
- **So sánh với traditional application:** Application truyền thống phải duy trì server hoạt động liên tục dù có traffic hay không, trong khi Serverless chỉ tính phí khi có request thực tế.

**Architecture patterns được trình bày:**

*Synchronous API pattern:*
```
Client → Amazon API Gateway → AWS Lambda → Database
```

Amazon Cognito được kết hợp với API Gateway Authorizer để thực hiện authentication/authorization trước khi request đi vào backend Lambda.

*Event-driven pattern:*
Speaker demo việc tách chức năng gửi email khỏi backend chính bằng Amazon SQS và Lambda. Thay vì backend xử lý trực tiếp, nó push message vào SQS queue và một Lambda function riêng sẽ consume message và gửi email. Pattern này giúp decouple components và tăng resilience.

**Vấn đề production thực tế - Database Connection Overload:**

Một điểm rất quan trọng mà speaker nhấn mạnh: khi nhiều Lambda instance chạy đồng thời (ví dụ traffic spike), mỗi instance có thể mở database connection riêng, dẫn đến database bị overload vì quá nhiều concurrent connections.

**Giải pháp:** Sử dụng **Amazon RDS Proxy** nằm giữa Lambda và database để quản lý và reuse connection pool, giúp giảm số lượng connection trực tiếp tới database.

**Liên hệ với Fitness Assistant:**  
Sau session này em hiểu rằng không phải mọi service đều cần chạy 24/7. Các tác vụ như gửi notification sau workout, xử lý ảnh nutrition label upload, tính toán daily statistics aggregation có thể sử dụng Lambda. Tuy nhiên cần lưu ý về database connection management nếu Lambda cần query database thường xuyên.

#### Optimizing Database Cost & Performance with Data Archiving Strategies

Kiet Nguyen và Viet Ly từ VPBank trình bày bài toán thực tế: database của hệ thống production ngày càng lớn theo thời gian, trong khi không phải tất cả dữ liệu cũ đều cần được truy cập thường xuyên. Giải pháp là giữ dữ liệu thường xuyên sử dụng trong operational database, chuyển historical data sang storage rẻ hơn, từ đó giảm kích thước database, tối ưu chi phí và cải thiện performance.

**Architecture chính được trình bày:**
```
Amazon RDS → AWS DMS → Amazon S3 (RAW) → AWS Glue → Partitioned Data → Amazon Athena
```

**Chi tiết implementation:**

1. **Initial Migration với AWS DMS:**
   - Khi hệ thống đã có nhiều năm dữ liệu historical, AWS DMS được sử dụng cho initial migration để chuyển một lượng lớn dữ liệu cũ từ RDS xuống S3.
   - Ví dụ: chỉ giữ dữ liệu gần đây (90 ngày) trong RDS, phần cũ hơn được archive.

2. **Data Processing với AWS Glue:**
   - AWS Glue xử lý dữ liệu đã được export xuống S3.
   - Thực hiện partition dữ liệu theo cấu trúc year/month/day.
   - Partition giúp Amazon Athena giảm lượng dữ liệu cần scan khi query, cải thiện performance và giảm cost.

3. **Query Historical Data với Amazon Athena:**
   - Thay vì bắt buộc giữ toàn bộ historical data trong RDS (đắt và ảnh hưởng performance), Amazon Athena cho phép query trực tiếp từ S3 khi cần.
   - Dữ liệu được partition tốt sẽ giúp query nhanh hơn rất nhiều.

4. **Cleanup RDS:**
   - Sau khi xác nhận archive thành công và có khả năng query từ S3/Athena, dữ liệu tương ứng trong RDS có thể được xóa để giải phóng storage.

**Demo rule-based archiving:**
Speaker demo một rule đơn giản: dữ liệu cũ hơn 90 ngày được xem như historical data và được archive. Rule này có thể customize tùy business requirement.

**Liên hệ với Fitness Assistant:**  
Đây là bài học rất quan trọng cho dự án. Fitness Assistant có các loại dữ liệu sẽ tăng nhanh theo thời gian:
- Workout logs (mỗi user có thể có hàng trăm records/năm)
- Nutrition tracking (daily entries)
- InBody measurements (weekly/monthly)
- Activity history

Thay vì chỉ nghĩ "scale database lên", em học được cần thiết kế data lifecycle từ đầu:
- Dữ liệu recent (3 months) query từ RDS cho performance cao
- Historical data (>3 months) archive sang S3
- Implement retention policy để control cost khi scale
- Sử dụng Athena khi cần query historical data cho reporting

Session này cho thấy database optimization không chỉ là index và query tuning mà còn có thể giải quyết bằng architecture và data lifecycle management.

#### Diffusion and OCR với AWS AI Services

Long Huynh chia session thành 3 phần: Diffusion model, OCR applications, và Vision AI context understanding.

**Phần 1: Diffusion Model Overview**

Speaker giải thích Diffusion là một trong những breakthrough trong Generative AI, cho phép tạo ảnh từ text prompts (Text-to-Image) hoặc biến đổi ảnh hiện có (Image-to-Image).

- **Ứng dụng thực tế:** Marketing (generate product images), content creation, design prototyping
- **AWS integration:** Amazon Bedrock hỗ trợ Stable Diffusion models, có thể invoke qua API
- **Trade-offs:** Image generation cost cao hơn so với text generation, cần evaluate use case carefully

**Phần 2: OCR với Amazon Textract**

Session tập trung vào 2 document types phổ biến ở Việt Nam:
- **CCCD (Căn cước công dân):** Textract extract thông tin structured như số ID, họ tên, ngày sinh, địa chỉ với accuracy cao
- **Biển số xe (License plate):** Demo Textract kết hợp Amazon Rekognition để detect và extract license plate number từ ảnh xe

**Real-world application pattern:**
```
User upload ảnh → S3 → Lambda trigger → Textract/Rekognition → Extract structured data → Validate → Store to database
```

Speaker nhấn mạnh importance của validation logic sau khi extract: ví dụ CCCD phải match format 12 digits, license plate phải conform với VN format rules.

**Phần 3: Vision AI với Context Understanding**

Điểm nổi bật: Amazon Bedrock (Claude 3 Sonnet) không chỉ extract text mà còn understand context trong ảnh.

Speaker demo một ví dụ ấn tượng:
- Upload ảnh 1 table có nhiều giấy tờ/documents rải rác
- Hỏi Claude: "Hãy liệt kê tất cả documents trên bàn và tóm tắt nội dung chính của mỗi document"
- Claude trả về structured response: list documents, vị trí trong ảnh, content summary của từng document

**Key insight:** Multimodal AI (text + vision) mở ra possibilities mới cho document processing, không chỉ là "đọc text" mà còn "hiểu context và relationship giữa các elements trong ảnh".

**Liên hệ với Fitness Assistant:**  
OCR có thể apply cho:
- User chụp ảnh nutrition label → Auto extract calories, macros, serving size
- Upload ảnh meal → AI identify food items và estimate nutrition info
- Analyze workout form từ ảnh/video (future enhancement)

Context understanding đặc biệt hữu ích: user chụp ảnh bữa ăn với nhiều món, AI không chỉ recognize từng món mà còn estimate portion size based on relative size và context.

#### Agentic AIOps on AWS: Inside AWS DevOps Agent

Vi Tran từ VIB chia sẻ về AWS DevOps Agent - một AI agent được design specifically cho CloudOps và incident troubleshooting.

**Core Philosophy: Hypothesis-Driven Investigation**

Thay vì engineer phải manually check từng service, parse logs, trace requests, AWS DevOps Agent automate investigation workflow theo scientific method:
1. **Observe symptoms** từ CloudWatch alarms, metrics anomalies
2. **Form hypothesis** về potential root causes
3. **Gather evidence** từ logs, traces, metrics để validate/reject hypothesis
4. **Generate recommendations** based on findings
5. **Human review and approval** trước khi execute any actions

**Agent Space - The Investigation Workspace**

Speaker giới thiệu concept "Agent Space" - một workspace riêng cho mỗi investigation session:
- Agent maintain conversation context về incident đang troubleshoot
- Có thể access relevant AWS resources (CloudWatch logs, X-Ray traces, service metrics)
- Track investigation progress: hypotheses tested, evidence gathered, conclusions reached
- Generate investigation report tự động

**MCP (Model Context Protocol) Integration**

Một điểm technical quan trọng: Agent extensibility thông qua MCP.
- MCP cho phép agent integrate với external tools và data sources
- Ví dụ: có thể extend agent để query custom monitoring systems, internal documentation, runbooks
- Agent có thể learn from past incidents stored trong knowledge base

**Human-in-the-Loop Emphasis**

Vi Tran nhấn mạnh nhiều lần: Agent là "assistant", không phải "autonomous operator".
- Agent **suggest** actions, không tự động execute destructive operations
- Engineer phải **review và approve** recommendations
- Agent có **restricted permissions** - không thể delete resources, modify production config without approval
- Philosophy: "AI augments human expertise, not replaces it"

**Demo Scenario - API Latency Spike**

Speaker demo incident response workflow:
1. CloudWatch alarm: API Gateway latency tăng đột ngột
2. Agent analyze metrics → notice Lambda cold start spike
3. Agent correlate với deployment event 30 minutes ago
4. Agent check Lambda configuration → detect memory allocation decreased từ 1024MB xuống 512MB
5. Agent suggest: "Recent deployment reduced Lambda memory, causing more cold starts. Recommend rollback or increase memory allocation."
6. Engineer review evidence, approve rollback

**Liên hệ với Fitness Assistant:**  
Khi Fitness Assistant scale và có nhiều services (auth, user-service, fitness-service, ai-service, notification), manual troubleshooting sẽ time-consuming. Session này cho thấy:
- Cần invest vào structured logging và metrics từ đầu (để Agent có data để analyze)
- Implement distributed tracing (X-Ray) để understand request flow
- Consider AWS DevOps Agent (hoặc similar tools) cho incident response automation
- **Mindset shift:** Troubleshooting không phải "guess and check" mà là systematic, hypothesis-driven investigation

#### From Local to Global: Migrating a GenAI Product to AWS

Ngoc Tran chia sẻ migration journey từ local development environment sang AWS production - một case study rất practical cho những ai đang build GenAI applications.

**The Starting Point: Local Development Challenges**

Project ban đầu develop locally với:
- LLM API keys hard-coded trong code
- No proper secrets management
- Development và production share same API keys
- Cost tracking impossible (không biết feature nào xài bao nhiêu)
- No rate limiting → risk of unexpected bills

**Why Migrate to AWS?**

Speaker explain decision rationale:
- **Scalability:** Local setup không handle được concurrent users
- **Security:** Need proper secrets management (không thể commit API keys vào Git)
- **Cost governance:** Cần track và control AI inference costs
- **Team collaboration:** Multiple developers cần shared infrastructure
- **Operational maturity:** Monitoring, logging, alerting

**Target Architecture trên AWS**

```
AWS Amplify (Frontend hosting)
    ↓
Amazon API Gateway (API management + authentication)
    ↓
AWS Lambda (Business logic)
    ↓
Amazon Bedrock (LLM inference)
    ↓
Amazon DynamoDB (Session/user data storage)
```

**Key Migration Steps:**

1. **Secrets Management Migration:**
   - Move API keys từ code → AWS Secrets Manager
   - Lambda functions fetch secrets at runtime
   - Implement automatic secret rotation

2. **Frontend Hosting:**
   - Migrate frontend từ local → AWS Amplify
   - Amplify handle CI/CD automatically (git push → auto deploy)
   - CloudFront distribution cho global low-latency access

3. **Backend API Migration:**
   - Wrap business logic trong Lambda functions
   - API Gateway làm single entry point
   - Cognito integration cho user authentication

4. **LLM Provider Decision:**
   - Evaluate giữa keeping external LLM API vs migrate sang Amazon Bedrock
   - **Bedrock advantages:** Managed service, no separate API keys, integrated với AWS IAM, support multiple models (Claude, Llama, etc.)
   - **Trade-offs:** Model availability, pricing comparison, latency

**Model Selection Strategy**

Speaker share practical tips:
- **Start với smaller models** cho development/testing (cost savings)
- **Evaluate model performance** với real user queries before committing
- **Consider model switching capability** - don't hard-code model dependency
- **Monitor cost per request** và adjust model choice based on ROI

**Challenges Encountered:**

1. **Cold Start Latency:** Lambda cold start + Bedrock model loading → first request slow
   - Solution: Implement provisioned concurrency cho critical endpoints

2. **Cost Monitoring:** Ban đầu không track costs properly
   - Solution: Implement CloudWatch custom metrics, set up billing alarms

3. **Error Handling:** LLM calls có thể fail (rate limits, timeouts)
   - Solution: Implement retry logic with exponential backoff, fallback responses

**Liên hệ với Fitness Assistant:**  
AI service trong Fitness Assistant hiện integrate với external LLM APIs. Session này show roadmap để production-ready:
- **Phase 1:** Move API keys sang Secrets Manager (immediate security improvement)
- **Phase 2:** Wrap AI service với proper API Gateway + authentication
- **Phase 3:** Evaluate Amazon Bedrock cho centralized AI infrastructure
- **Phase 4:** Implement comprehensive monitoring: track latency, cost, error rate, user satisfaction per AI feature

#### Agentic Decision Intelligence on AWS

Xuan Le và Nghi Danh present về AI Agent cho business decision-making - không chỉ là chatbot trả lời câu hỏi mà là proactive intelligent system support complex decisions.

**Key Distinction: Chatbot vs Agentic AI**

Speaker bắt đầu bằng comparison rõ ràng:

**Traditional Chatbot:**
- **Reactive:** User hỏi → Bot trả lời
- **Stateless:** Mỗi query độc lập, không context
- **Limited capability:** Chỉ retrieve information, không analyze hoặc reason
- **Example:** "What is the sales revenue last month?" → Return number from database

**Agentic AI:**
- **Proactive:** Analyze data → Generate insights → Suggest actions (không cần user hỏi trước)
- **Stateful:** Maintain context across conversation, understand follow-up questions
- **Reasoning capability:** Có thể break down complex questions, reason across multiple data sources, generate explanations
- **Example:** "Should we expand to market X?" → Agent analyze market data, financial projections, competitive landscape, risk factors → Generate comprehensive recommendation with supporting evidence

**Use Case Demo: Financial Forecasting với Simulation**

Speaker demo business scenario: Company planning investment decision, cần forecast financial outcomes với different scenarios.

**Traditional approach:** Analyst manually run Excel models, estimate outcomes based on assumptions.

**Agentic approach:**
1. **User query:** "What is the expected ROI if we invest $1M in project X?"
2. **Agent reasoning:**
   - Retrieve historical financial data
   - Analyze market trends
   - Identify key variables (market growth rate, customer acquisition cost, churn rate)
   - **Run Monte Carlo simulation** để account for uncertainty
   - Generate probability distribution của outcomes (không chỉ single point estimate)
3. **Agent response:** 
   - "Based on 10,000 simulations với Markov Chain model:"
   - "70% probability ROI between 15-25%"
   - "15% probability ROI > 25% (best case)"
   - "15% probability ROI < 15% (worst case)"
   - "Key risk factors: Customer churn rate variance, market competition intensity"

**Technical Stack được nhắc đến:**
- **Amazon Bedrock** (Claude) cho reasoning và natural language interaction
- **AWS Lambda** execute simulation code (Monte Carlo, Markov Chain models)
- **Amazon QuickSight** visualize results và probability distributions
- **Amazon S3** store historical data và simulation results

**Fail-Closed Principle**

Một điểm security/governance quan trọng mà speaker emphasize:
- Agent design theo "fail-closed" principle: nếu agent không confident về answer (hoặc có contradicting evidence), nó sẽ **acknowledge uncertainty** thay vì generate potentially incorrect answer.
- Better to say "I don't have enough data to answer confidently" than give wrong recommendation.
- Agent có thể suggest "what additional data would improve confidence level."

**Demo với Amazon QuickSight**

Speaker demo QuickSight dashboard tích hợp với Agent:
- User có thể ask questions bằng natural language directly trong QuickSight
- Agent query underlying data, generate visualization on-the-fly
- Không cần biết SQL hoặc dashboard configuration

**Liên hệ với Fitness Assistant:**  
Session này mở ra vision cho AI evolution trong Fitness Assistant:

**Current state (Chatbot-like):**
- User: "Suggest workout plan" → AI: Return generic workout plan

**Future state (Agentic):**
- Agent analyze user history: workout logs, nutrition, sleep, progress photos, InBody measurements
- Proactively identify patterns: "User skipping leg days, protein intake below target, sleep quality decreased last 2 weeks"
- Generate insights: "Current workout intensity may be too high given sleep quality decline. Recovery is compromised."
- **Suggest adaptive plan:** "Recommend reducing volume by 20%, focus on recovery, increase protein by 30g/day. Re-evaluate in 2 weeks."

**Technical approach:**
- Implement data pipeline: aggregate user data → Feature engineering → Pattern detection
- Use Bedrock Agent framework để orchestrate reasoning
- Store user context và conversation state
- Implement feedback loop: user rate AI recommendations → improve model over time

#### AWS Principles Beyond AWS

Bao Huynh kết thúc sự kiện với message quan trọng: Cloud engineering principles không limited to AWS hay bất kỳ cloud provider nào - đây là universal mindset và practices.

**Core Message: Principles Over Services**

Speaker start với câu hỏi provocative: "What happens if tomorrow you have to migrate từ AWS sang GCP hay Azure? Có phải everything you learned becomes useless?"

**Answer:** Không. Vì điều quan trọng không phải service names (Lambda vs Cloud Functions vs Azure Functions) mà là **underlying principles:**
- Event-driven architecture
- Infrastructure as Code
- Observability và monitoring culture
- Security best practices (least privilege, defense in depth)
- Cost optimization mindset
- Automation over manual operations

**Real-World Example: Jenkins Troubleshooting**

Speaker share case study để illustrate:

**Scenario:** Jenkins pipeline failing intermittently. Error message unhelpful: "Build failed."

**Wrong approach (service-focused):**
- Google "Jenkins build failed AWS"
- Try random solutions from Stack Overflow
- Restart Jenkins, hope it works

**Right approach (principle-focused - Troubleshooting methodology):**
1. **Gather evidence systematically:**
   - Check Jenkins logs (when did it start failing? Any pattern?)
   - Check system resources (CPU, memory, disk space)
   - Check network connectivity
   - Review recent changes (code, config, infrastructure)

2. **Form hypothesis:**
   - Pattern detected: Failures happen during peak hours
   - Hypothesis: Resource contention issue

3. **Validate hypothesis:**
   - Monitor resources during build → Confirm memory spike
   - Root cause: Jenkins running on t2.micro instance (insufficient memory)

4. **Implement solution:**
   - Upgrade instance type
   - Add monitoring/alerting để catch similar issues early

**Key insight:** Troubleshooting methodology (systematic investigation, hypothesis testing, root cause analysis) applies to any system, không chỉ AWS.

**Example 2: Amazon Inspector CVE Evaluation**

Speaker demo another scenario về security vulnerability management:

**Scenario:** Amazon Inspector report 50 CVEs (Common Vulnerabilities and Exposures) trong application.

**Wrong approach:**
- Panic và try to fix tất cả ngay lập tức
- Hoặc ignore vì "quá nhiều, không biết bắt đầu từ đâu"

**Right approach (Risk-based prioritization):**
1. **Understand severity:** Critical > High > Medium > Low
2. **Assess exploitability:** CVE có exploit code publicly available chưa?
3. **Evaluate impact:** Service này có exposed to internet không? Có chứa sensitive data không?
4. **Prioritize:** Fix Critical CVEs trong internet-facing services trước, sau đó High severity, v.v.
5. **Implement process:** Regular vulnerability scanning, patching schedule, exception process

**Key insight:** Security principles (risk assessment, prioritization, defense in depth) transfer across platforms.

**Universal Cloud Principles Speaker Emphasized:**

1. **Infrastructure as Code mindset:**
   - Manual changes = bad (not reproducible, error-prone)
   - Code-driven infrastructure = good (version controlled, testable, repeatable)
   - Terraform, CloudFormation, Pulumi - tools change, principle remains

2. **Observability culture:**
   - Không thể manage những gì không measure được
   - Logging, metrics, tracing là fundamentals
   - Alert on symptoms, not just thresholds

3. **Automation bias:**
   - "If you do it twice, automate it"
   - Reduce toil, increase reliability
   - CI/CD, automated testing, automated remediation

4. **Cost optimization:**
   - Understand resource utilization
   - Right-sizing, reserved capacity, spot instances
   - Tag resources cho cost allocation

5. **Security by default:**
   - Principle of least privilege
   - Encryption in-transit và at-rest
   - Regular security audits

**Closing Message:**

"Don't memorize AWS service names. Understand distributed systems principles, practice operational excellence, build resilience patterns. Khi đó, whether you work with AWS, GCP, Azure, hay on-premises infrastructure, you'll be effective engineer."

**Liên hệ với Fitness Assistant và quá trình thực tập:**  
Session này remind rằng goal của thực tập không phải "học AWS" mà là:
- **Learn systems thinking:** Understand how distributed systems work, fail, và recover
- **Develop operational maturity:** Monitoring, incident response, continuous improvement
- **Practice engineering discipline:** IaC, testing, documentation, automation
- **Build problem-solving skills:** Systematic troubleshooting, root cause analysis, pragmatic trade-offs

Fitness Assistant project là vehicle để practice những principles này. AWS là tool, principles là transferable skills.

### 5. Kiến thức và kỹ năng rút ra

- **Serverless architecture** là viable option cho event-driven workloads. Cần evaluate trade-offs (cold start vs cost savings) trước khi decide.

- **Data lifecycle management** cần thiết kế từ đầu. Không thể chỉ nghĩ về "lưu data" mà phải plan cho growth: hot/cold data separation, archiving strategy, retention policy.

- **AI production system** phức tạp hơn nhiều so với AI prototype. Cần guardrails, evaluation framework, monitoring, security, governance.

- **Observability is mandatory** cho microservices architecture. CloudWatch logs/metrics, X-Ray tracing, và có thể leverage AI agents for automated troubleshooting.

- **Agentic AI** represents evolution from reactive chatbots to proactive intelligent assistants.

- **Cloud-native principles transferable** across platforms. Focus on learning architectural patterns và operational practices.

- **Operational maturity** quan trọng không kém technical implementation.

### 6. Ứng dụng sau sự kiện

Sau FCAJ Community Day August, mình sẽ apply những insights vào Fitness Assistant project:

**Ngắn hạn (1-2 tuần):**
- Review Fitness Assistant architecture để identify workloads có thể convert sang Serverless (notification service, image processing, daily stats aggregation).
- Design data lifecycle cho workout logs và nutrition tracking: define hot/cold data boundary, plan archiving strategy.
- Implement comprehensive CloudWatch monitoring cho tất cả services: structured logging, custom metrics, alarms.
- Research Amazon Bedrock capabilities và compare với current LLM integration approach.

**Trung hạn (1-2 tháng):**
- Implement basic data archiving: automated job move old workout data (>6 months) từ RDS sang S3.
- Add X-Ray tracing để better understand request flow across microservices.
- Develop evaluation framework cho AI service: accuracy metrics, response time, cost per request.
- Prototype guardrails cho AI fitness recommendations.

**Dài hạn (3-6 tháng):**
- Migrate appropriate workloads sang Lambda để optimize cost (estimate potential 30-40% reduction).
- Enhance AI agent capabilities: từ Q&A bot evolve thành proactive fitness coach.
- Implement full observability stack với automated alerting.
- Explore Bedrock Agents cho unified AI orchestration.

**Mindset changes:**
- **"Go Build" mentality:** Start implementing và iterate quickly thay vì wait for perfect design.
- **Think in systems:** Consider full lifecycle: deployment, monitoring, scaling, cost, security.
- **Operational excellence:** Architecture tốt là insufficient. Cần invest vào monitoring, automation, documentation.
- **Cost-conscious development:** Evaluate cost implications của technical decisions.

### 7. Hình ảnh tham dự

![Technical session](/images/events/fcaj-aug-2026-1.jpg)
*Theo dõi phần trình bày về kiến trúc AWS tại FCAJ Community Day August*

![Check-in tại sự kiện](/images/events/fcaj-aug-2026-2.jpg)
*Check-in tại FCAJ Community Day August - Bitexco Financial Tower*

![Session về Pipeline](/images/events/fcaj-aug-2026-3.jpg)
*Session về incident troubleshooting và investigation workflows*

![Demo Serverless](/images/events/fcaj-aug-2026-4.jpg)
*Demo về cấu trúc serverless application với Lambda function apps*

![Serverless Computing](/images/events/fcaj-aug-2026-5.jpg)
*Session giới thiệu về Serverless Computing và application patterns*

### 8. Link bằng chứng

- **Trang sự kiện chính thức:** [FCAJ Community Day August – Luma](https://luma.com/m8h7l900)
- **Vé tham gia của tôi:** [My Event Ticket](https://luma.com/e/ticket/evt-c2ShqHj9N1WwOTN?pk=g-pw3kjKE8DqhuRjD)
- **Video recording sự kiện:** [FCAJ Community Day August - YouTube](https://www.youtube.com/watch?v=25BbjYNwewk)
- **Host:** Huỳnh Hoàng Long
- **Thời gian:** Saturday, August 22, 2026 - 9:00 AM to 12:00 PM
- **Địa điểm:** Bitexco Financial Tower, Thành phố Hồ Chí Minh
