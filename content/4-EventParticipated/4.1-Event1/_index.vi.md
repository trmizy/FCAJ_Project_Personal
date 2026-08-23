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

Phần chia sẻ từ Kiet Lam mang lại góc nhìn thực tế về Serverless Computing và so sánh cách phát triển ứng dụng truyền thống với Serverless. 

**Những điểm cốt lõi:**
- **Serverless không có nghĩa là không có server**, mà là developers không cần quản lý infrastructure. AWS Lambda tự động scale based on demand.
- **Benefits:** Pay-per-use pricing model, automatic scaling, reduced operational overhead.
- **Trade-offs cần lưu ý:** Cold start latency, execution time limits (15 phút cho Lambda), stateless design requirement.
- **AWS Serverless application patterns:** Event-driven architecture với Lambda, API Gateway, DynamoDB, S3, EventBridge.

**Liên hệ với Fitness Assistant:**  
Session này giúp mình nhận ra không phải mọi workload đều cần chạy 24/7. Các tác vụ như gửi notification sau workout, xử lý ảnh nutrition label, tính toán daily statistics có thể sử dụng Lambda thay vì dedicated service, giúp giảm cost đáng kể.

#### Optimizing Database Cost & Performance with Data Archiving Strategies

Kiet Nguyen và Viet Ly từ VPBank chia sẻ kinh nghiệm thực tế về database growth challenges và data archiving architecture.

**Những điểm quan trọng:**
- **Database growth challenge:** Khi dữ liệu tăng từ GB lên TB, query performance giảm và storage cost tăng exponentially.
- **Hot data vs Cold data:** Không phải tất cả dữ liệu đều cần access với performance cao. Hot data (recent 3-6 months) cần fast access, cold data có thể archive.
- **Archiving strategies:** 
  - Initial data load design: Bulk export historical data
  - Daily incremental archiving: Automated jobs chạy hàng ngày
  - Storage tiers: RDS → S3 Standard → S3 Glacier
- **Cost optimization:** VPBank giảm được 60% database cost sau khi implement archiving strategy.

**Liên hệ với Fitness Assistant:**  
Project có các loại dữ liệu sẽ tăng nhanh theo thời gian như workout logs, nutrition tracking, InBody measurements. Từ session này, mình hiểu cần thiết kế data lifecycle từ đầu: dữ liệu gần đây (3 months) query từ RDS, data cũ hơn archive sang S3, và implement retention policy để control cost khi scale.

#### Diffusion and OCR với AWS AI Services

Long Huynh giới thiệu AWS services cho Text-to-Image và Image-to-Text, tập trung vào Amazon Textract và Rekognition.

**Use cases thực tế:**
- **OCR cho documents:** Textract extract thông tin từ forms, invoices, receipts với accuracy cao.
- **Image analysis:** Rekognition detect objects, text in images, facial recognition.
- **Integration patterns:** S3 trigger → Lambda → Textract/Rekognition → Store results to DynamoDB.

**Liên hệ với Fitness Assistant:**  
OCR có thể hữu ích khi user chụp ảnh nutrition label để tự động extract calories, protein, carbs. Hoặc analyze workout posture từ ảnh/video. Tuy nhiên đây là future expansion, hiện tại chưa implement.

#### Agentic AIOps on AWS: Inside AWS DevOps Agent

Vi Tran trình bày về AWS DevOps Agent - một trong những session quan trọng nhất liên quan trực tiếp đến operational aspects của Fitness Assistant.

**Core concepts:**
- **Operational challenges:** Khi deploy microservices, debugging trở nên phức tạp. Service nào đang có vấn đề? Root cause là gì?
- **Investigation workflow:** Agent tự động analyze logs từ CloudWatch, gather evidence từ X-Ray traces/metrics, form hypothesis về root cause, generate recommendation.
- **Security boundaries:** Agent chỉ có controlled access, không thể execute destructive actions without approval.
- **MCP extensibility:** Có thể extend agent với custom tools và knowledge base.

**Liên hệ trực tiếp với Fitness Assistant:**  
Khi deploy nhiều services (frontend, gateway, auth-service, user-service, fitness-service, ai-service), việc troubleshoot trở nên phức tạp. Session này cho thấy importance của observability stack: CloudWatch cho logs/metrics, X-Ray cho distributed tracing, và có thể leverage AI agent để assist troubleshooting.

#### From Local to Global: Migrating a GenAI Product to AWS

Ngoc Tran chia sẻ real-world experience migrate GenAI product, đặc biệt relevant vì Fitness Assistant có ai-service.

**Migration journey:**
- **Challenge:** Di chuyển từ Azure OpenAI sang AWS ecosystem
- **Key considerations:** Model availability (GPT-4, Claude trên Bedrock), latency requirements, cost comparison, data residency và compliance

**Guardrails & Governance:**
- Input validation (toxic content filtering)
- Output validation (factual accuracy, hallucination detection)
- PII detection and redaction
- Cost monitoring và rate limiting
- Audit logging cho compliance

**Liên hệ với Fitness Assistant:**  
AI service hiện đang integrate với external LLM APIs. Session này cho thấy để production-ready, cần implement guardrails (ensure AI không generate harmful workout advice), evaluation (đảm bảo AI recommendations accurate và safe), monitoring (track AI performance, cost, errors). Consider Amazon Bedrock as future option cho centralized AI infrastructure.

#### Agentic Decision Intelligence on AWS

Xuan Le và Nghi Danh giới thiệu về AI Agent hỗ trợ business decision-making, khác với traditional chatbot.

**Core concepts:**
- **Traditional Chatbot:** User hỏi → Bot trả lời (reactive)
- **Agentic AI:** Agent proactively analyze context → Generate insights → Suggest actions (proactive)

**Liên hệ với Fitness Assistant:**  
AI Fitness Assistant có thể evolve từ simple Q&A bot thành intelligent agent: collect workout history/nutrition logs/health metrics, analyze patterns ("User tends to skip leg day"), generate personalized recommendations, auto-adjust workout plan based on progress.

#### AWS Principles Beyond AWS

Bao Huynh kết thúc sự kiện với message về cloud-native thinking không limited to AWS.

**Core principles transferable across platforms:**
- Infrastructure as Code, Automation, Observability
- Security best practices, Cost optimization
- Resilience patterns (Multi-AZ, backup, disaster recovery)

**Liên hệ với quá trình thực tập:**  
Session này remind rằng mục tiêu không phải memorize AWS service names, mà là understand distributed systems architecture, practice operational excellence, learn cost optimization mindset, build observability culture.

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
- **Host:** Huỳnh Hoàng Long
- **Thời gian:** Saturday, August 22, 2026 - 9:00 AM to 12:00 PM
- **Địa điểm:** Bitexco Financial Tower, Thành phố Hồ Chí Minh
