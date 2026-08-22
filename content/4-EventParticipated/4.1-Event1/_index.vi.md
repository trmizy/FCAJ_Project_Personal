---
title: "Sự kiện 1: FCAJ Community Day August"
date: 2026-08-22
weight: 1
chapter: false
pre: " <b> 4.1. </b> "
---

### Tên sự kiện

**FCAJ Community Day August**

### Thời gian

**Thứ Bảy, 22/08/2026**
- 08:00 – 09:00: Check-in
- 09:00 – 12:00: Technical sessions

### Địa điểm / Hình thức

**Bitexco Financial Tower**  
2 Đ. Hải Triều, Sài Gòn, Hồ Chí Minh, Việt Nam

**Hình thức:** Tham gia trực tiếp (In-person)

### Vai trò

Người tham dự (Attendee)

### Diễn giả và chủ đề chính

Dưới đây là danh sách diễn giả và chủ đề được trình bày tại sự kiện:

| Diễn giả | Tổ chức / Vai trò | Chủ đề trình bày |
|---|---|---|
| Kiệt Lam | Senior Developer Engineer, FPT Software | Development Application with AWS Serverless |
| Kiệt Nguyen & Việt Lý | Software Engineer (VPBank), DevOps (VPBank) | Optimizing Database Cost & Performance with Data Archiving Strategies |
| Long Huynh | Senior Solutions Architect, eCloudvalley | Diffusion and OCR |
| Vi Tran | CloudOps Engineer, VIB | Agentic AIOps on AWS: Inside AWS DevOps Agent |
| Ngoc Tran | Service Delivery Engineer Intern, Accenture | From Local to Global: Migrating a GenAI Product to AWS |
| Xuan Le & Nghi Danh | Data Analytics & Insights, AI Engineer (Renova Cloud) | Agentic Decision Intelligence on AWS |
| Bao Huynh | Cloud Native Developer, Endava Viet Nam | AWS Principles Beyond AWS: How AWS Knowledge Transfers to Cloud-Native Roles |

### Nội dung chính

Sáng ngày 22/08/2026, mình tham gia FCAJ Community Day August tại Bitexco Financial Tower. Sự kiện tập trung vào các chủ đề AWS, Serverless, database optimization, Generative AI, Agentic AI và Cloud Operations. Dưới đây là những gì mình học được từ các session:

#### 1. Development Application with AWS Serverless

Session này giới thiệu về Serverless Computing và so sánh cách phát triển ứng dụng truyền thống với Serverless. Phần demo cho thấy các AWS Serverless application patterns thực tế.

**Điểm đáng chú ý:**
- Serverless không có nghĩa là không có server, mà là developer không cần quản lý server.
- Các lợi ích về scaling tự động và pay-per-use.
- Trade-offs cần xem xét: cold start, execution time limits, stateless design.

**Liên hệ với Fitness Assistant:**  
Serverless cho mình thêm góc nhìn về cách một số workload có thể được tách khỏi backend chạy liên tục. Ví dụ như các tác vụ event-driven (gửi notification, xử lý ảnh, tính toán nutrition) hoặc scheduled tasks (tổng hợp thống kê hàng ngày) có thể cân nhắc sử dụng AWS Lambda thay vì phải chạy service 24/7.

#### 2. Optimizing Database Cost & Performance with Data Archiving Strategies

Session này đi sâu vào vấn đề database growth và operational challenges khi dữ liệu ngày càng lớn. Nội dung bao gồm data archiving architecture, initial data load design, daily incremental archiving, và cost optimization techniques.

**Điểm đáng chú ý:**
- Không phải tất cả dữ liệu đều cần truy cập với performance cao.
- Data lifecycle và retention policy cần được thiết kế từ đầu.
- Cost optimization bằng cách tách hot data và cold data.

**Liên hệ với Fitness Assistant:**  
Project Fitness Assistant có khả năng phát sinh nhiều dữ liệu theo thời gian như lịch sử cân nặng, InBody measurements, workout logs, nutrition logs và activity history. Từ session này, mình hiểu rằng khi lượng dữ liệu tăng lên thì không nên chỉ nghĩ đến việc scale database hiện tại mà còn cần xem xét:
- Dữ liệu nào cần truy cập thường xuyên (recent workouts, current stats)
- Dữ liệu nào có thể archive (historical data từ 1-2 năm trước)
- Retention policy và storage cost
- Query performance optimization

Đây là hướng cần nghiên cứu thêm khi hệ thống phát triển.

#### 3. Diffusion and OCR

Session về AWS services cho Text-to-Image generation và Image-to-Text extraction. Phần demo cho thấy các real-world use cases trong việc xử lý và phân tích hình ảnh.

**Điểm đáng chú ý:**
- Amazon Textract cho OCR.
- Amazon Rekognition cho image analysis.
- Integration với các AI services khác.

**Liên hệ với Fitness Assistant:**  
Session này giúp mình suy nghĩ thêm về các khả năng AI trong tương lai cho Fitness Assistant. Ví dụ như OCR có thể hữu ích khi người dùng chụp ảnh nutrition label để tự động extract thông tin dinh dưỡng, hoặc phân tích hình ảnh để đánh giá posture trong workout. Tuy nhiên đây là hướng mở rộng trong tương lai, hiện tại project chưa có chức năng này.

#### 4. Agentic AIOps on AWS: Inside AWS DevOps Agent

Đây là một trong những session quan trọng nhất đối với quá trình thực tập của mình. Nội dung bao gồm AWS DevOps Agent, operational challenges, incident troubleshooting, investigation workflow, architecture overview và security boundaries.

**Điểm đáng chú ý:**
- Agent tự động phân tích logs và metrics để tạo hypothesis.
- Thu thập evidence từ nhiều nguồn (CloudWatch, X-Ray, logs).
- Đưa ra recommendation dựa trên context.
- Security boundaries và controlled automation.
- MCP (Model Context Protocol) extensibility.

**Liên hệ trực tiếp với Fitness Assistant:**  
Trong quá trình deploy một hệ thống gồm nhiều service như Fitness Assistant, không chỉ quan tâm đến việc application chạy được mà còn phải quan tâm tới:
- Monitoring: service nào đang có vấn đề?
- Logs: lỗi xảy ra ở đâu trong flow?
- Incident investigation: tại sao service A không connect được service B?
- Root cause analysis: vấn đề do network, security group, hay application logic?
- Security boundary: đảm bảo automated action không gây ra rủi ro.
- Observability: có đủ thông tin để troubleshoot không?

Session này liên hệ trực tiếp với phần mình đang tìm hiểu về Amazon CloudWatch và monitoring trong quá trình thực tập. Mình nhận ra rằng một hệ thống production tốt cần có khả năng tự quan sát và hỗ trợ troubleshooting hiệu quả.

#### 5. From Local to Global: Migrating a GenAI Product to AWS

Session này đặc biệt liên quan đến Fitness Assistant vì project có AI service. Nội dung bao gồm challenges khi migrate GenAI product, chuyển từ Azure OpenAI sang Amazon Bedrock, Agentic AI systems, guardrails, evaluation frameworks và operational governance.

**Điểm đáng chú ý:**
- Một hệ thống AI production không chỉ là gọi model API.
- Cần có guardrails để kiểm soát output.
- Evaluation framework để đánh giá quality.
- Operational governance cho security và compliance.
- Migration considerations về cost, latency, model availability.

**Liên hệ với Fitness Assistant:**  
Điều này đặc biệt có ý nghĩa vì project đang có ai-service. Session giúp mình hiểu rằng khi đưa AI workload lên AWS, cần quan tâm tới:
- Model integration architecture
- Security và data privacy
- Guardrails để đảm bảo AI responses phù hợp
- Evaluation để đảm bảo quality
- Monitoring AI performance
- Governance và compliance
- Scalability và operational cost

Session cho mình thêm góc nhìn về Amazon Bedrock như một hướng đáng cân nhắc trong tương lai khi mở rộng AI capabilities của Fitness Assistant. Tuy nhiên hiện tại project chưa migrate sang Bedrock.

#### 6. Agentic Decision Intelligence on AWS

Session này giới thiệu về Agentic Decision Intelligence và cách AI Agent hỗ trợ business decision-making. Nội dung bao gồm intelligent decision workflows, banking use cases và Amazon QuickSight.

**Điểm đáng chú ý:**
- AI Agent không chỉ là chatbot trả lời câu hỏi.
- Agent có thể thu thập context, phân tích dữ liệu và hỗ trợ quyết định.
- Workflow dựa trên rule và dữ liệu thực tế.
- Chuyển dữ liệu thành business insight.

**Liên hệ với Fitness Assistant:**  
Session này mở rộng cách mình nghĩ về AI trong Fitness Assistant. AI Agent có thể:
- Thu thập context về người dùng (workout history, nutrition, health metrics)
- Phân tích patterns và trends
- Đưa ra personalized recommendations dựa trên dữ liệu thực tế
- Điều chỉnh workout plan dựa trên progress

Đây là hướng phát triển thú vị cho AI Fitness Assistant trong tương lai - không chỉ trả lời câu hỏi mà còn chủ động phân tích và đưa ra recommendations dựa trên profile của từng người dùng.

#### 7. AWS Principles Beyond AWS: How AWS Knowledge Transfers to Cloud-Native Roles

Session cuối cùng nói về việc kiến thức AWS không chỉ giới hạn trong việc sử dụng AWS services. Nội dung bao gồm operational principles, release management, incident recovery, security operations và cloud-native skills.

**Điểm đáng chú ý:**
- AWS knowledge là foundation cho cloud-native thinking.
- Các principles như automation, infrastructure as code, monitoring, security áp dụng được cho nhiều platform.
- Skills transferable across cloud providers.

**Liên hệ với quá trình thực tập:**  
Qua quá trình học AWS trong kỳ thực tập, mình nhận ra điều quan trọng không chỉ là nhớ tên service mà còn hiểu:
- Hệ thống distributed hoạt động như thế nào
- Security best practices
- Scalability và high availability
- Monitoring và observability
- Deployment strategies
- Cost optimization
- Troubleshooting methodology

Những nguyên tắc này có giá trị lâu dài, không chỉ giới hạn trong AWS.

### Hình ảnh / Video

**Ảnh 1: Technical session với Architecture Overview**
![Technical session](/images/events/fcaj-aug-2026-1.jpg)
*Theo dõi phần trình bày về kiến trúc AWS tại FCAJ Community Day August*

**Ảnh 2: Tham dự sự kiện tại AWS Office**
![Selfie tại AWS Office](/images/events/fcaj-aug-2026-2.jpg)
*Check-in tại FCAJ Community Day August - Bitexco Financial Tower*

**Ảnh 3: Session về Pipeline và Release Management**
![Pipeline session](/images/events/fcaj-aug-2026-3.jpg)
*Session về incident troubleshooting và investigation workflows*

**Ảnh 4: Demo Serverless Application Structure**
![Serverless demo](/images/events/fcaj-aug-2026-4.jpg)
*Demo về cấu trúc serverless application với Lambda function apps*

**Ảnh 5: Development Application with AWS Serverless**
![Serverless session](/images/events/fcaj-aug-2026-5.jpg)
*Session giới thiệu về Serverless Computing và application patterns*

### Bài học rút ra

Sau khi tham dự FCAJ Community Day August, mình rút ra được những bài học quan trọng:

**1. AWS architecture không chỉ là deploy application**

Một hệ thống production cần đồng thời quan tâm tới compute, database, monitoring, security, cost và scalability. Không thể chỉ focus vào việc "code chạy được" mà bỏ qua operational aspects.

**2. Serverless là kiến trúc đáng cân nhắc cho một số workload**

Không phải workload nào cũng cần một server/service chạy liên tục. Serverless có thể hữu ích với các tác vụ event-driven, scheduled task, background processing và workload không liên tục. Tuy nhiên cần cân nhắc trade-offs về cold start, execution limits và stateless design trước khi áp dụng vào Fitness Assistant.

**3. Database cần được thiết kế cho sự tăng trưởng lâu dài**

Đối với Fitness Assistant, dữ liệu workout, nutrition và InBody measurements có thể tăng rất nhanh theo thời gian và số lượng người dùng. Do đó cần suy nghĩ từ sớm về data lifecycle, retention policy, archiving strategy, performance optimization và cost management.

**4. GenAI production cần nhiều hơn một model**

Từ session migration GenAI, bài học quan trọng là AI production phải có guardrails, evaluation framework, monitoring, security và governance. Không thể chỉ tích hợp model API rồi coi như xong. Cần thiết kế architecture đầy đủ để đảm bảo AI system hoạt động ổn định, an toàn và có chất lượng.

**5. Observability và troubleshooting là bắt buộc**

Session về Agentic AIOps cho thấy giá trị của logs, metrics, evidence-based analysis và root cause investigation. Điều này liên hệ trực tiếp với việc mình đang tìm hiểu CloudWatch cho Fitness Assistant. Một hệ thống tốt cần có khả năng tự quan sát và hỗ trợ developer troubleshoot hiệu quả khi có vấn đề.

**6. AI Agent có thể phát triển xa hơn chatbot**

Agent có thể thu thập context, phân tích dữ liệu và hỗ trợ decision-making thay vì chỉ trả lời câu hỏi. Đây là một hướng nghiên cứu thú vị cho Fitness Assistant trong tương lai - AI có thể chủ động phân tích workout patterns, nutrition trends và health metrics để đưa ra personalized recommendations.

**7. Cloud-native thinking có giá trị lâu dài**

Kiến thức về AWS không chỉ là học cách dùng AWS Console. Các operational principles như automation, infrastructure as code, security, monitoring, cost optimization và troubleshooting methodology là những skills transferable có giá trị lâu dài trong career path cloud-native.

### Đóng góp cá nhân

Mình tham dự trực tiếp FCAJ Community Day August với vai trò người tham dự. Trong suốt sự kiện, mình:
- Theo dõi đầy đủ các technical sessions từ 09:00 đến 12:00
- Ghi nhận các kiến thức liên quan đến AWS, Serverless, database optimization, Generative AI, Agentic AI và AIOps
- Đối chiếu các kiến thức thu được với kiến trúc Fitness Assistant đang thực hiện trong kỳ thực tập
- Xác định các hướng cần nghiên cứu thêm như Amazon Bedrock, Serverless patterns, data archiving strategies, CloudWatch monitoring và operational best practices

Các session đặc biệt liên quan đến project bao gồm:
- **Agentic AIOps on AWS** - liên quan trực tiếp đến monitoring và troubleshooting mình đang tìm hiểu
- **From Local to Global: Migrating a GenAI Product to AWS** - quan trọng vì Fitness Assistant có ai-service
- **Optimizing Database Cost & Performance** - cần thiết cho việc thiết kế data lifecycle của workout và nutrition data
- **Development Application with AWS Serverless** - mở rộng góc nhìn về architecture patterns

### Link bằng chứng

**Trang sự kiện chính thức:**  
[FCAJ Community Day August – Luma](https://luma.com/m8h7l900)

**Thông tin chính:**
- **Host:** Huỳnh Hoàng Long
- **Thời gian:** Saturday, August 22, 2026 - 9:00 AM to 12:00 PM
- **Địa điểm:** Bitexco Financial Tower, Thành phố Hồ Chí Minh
