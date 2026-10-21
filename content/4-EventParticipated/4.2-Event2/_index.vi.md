---
title: "Sự kiện 2: AWS for Software & Financial Services Companies Day"
date: 2026-10-08
weight: 2
chapter: false
pre: " <b> 4.2. </b> "
draft: false
---

### Tên sự kiện

**AWS for Software & Financial Services Companies Day**

*AI Across Your Entire Engineering Lifecycle, Now Hands-On.* Sự kiện cả ngày, thực hành, dành cho đội ngũ kỹ sư phần mềm và dịch vụ tài chính đang xây dựng với AI, trình bày bằng tiếng Việt (mức 200–300).

### Ngày/Giờ

**Thứ Năm, ngày 8 tháng 10 năm 2026**, 09:00 – 18:00 (Asia/Ho_Chi_Minh)

| Thời gian | Phiên |
|---|---|
| 09:15 – 09:30 | Welcome Address |
| 09:30 – 10:10 | From Demo to Deployment: Solving Agentic AI's Toughest Challenges |
| 10:10 – 10:50 | Building High-Quality Data Products for AI Agents |
| 10:50 – 11:15 | Networking Break |
| 11:15 – 11:55 | Migration at Scale with AWS Transform |
| 11:55 – 12:15 | Afternoon Workshop Briefing — chọn track |
| 12:15 – 13:15 | Ăn trưa |
| 13:15 – 15:15 | Workshop thực hành: **Workshop A** (Build with Kiro) và **Workshop B** (Bedrock AgentCore với Kiro) |
| 15:15 – 15:35 | Afternoon Break |
| 15:35 – 16:15 | Customer Spotlight: building with AI in production — Bui Hoang Viet, Kyanon Digital |
| 16:30 – 18:00 | Networking Drinks |

### Địa điểm / Hình thức

**Sheraton Saigon Grand Opera Hotel**
88 Đồng Khởi, Quận 1, Thành phố Hồ Chí Minh, Việt Nam

**Hình thức:** Trực tiếp (sức chứa 350 người)

### Vai trò

Người tham gia thực hành, đăng ký với tên **Trần Minh Duy**. Trong khối buổi chiều, tôi làm việc trong **Workshop A — Build with Kiro: From Spec to Working Application**, tự xây một ứng dụng bằng Kiro dưới sự hướng dẫn của các solutions architect AWS.

### Nội dung chính

Buổi sáng là các bài nói về đưa AI vào vòng đời kỹ thuật phần mềm; buổi chiều là khối workshop thực hành. Từng phần như sau, dựa trên các slide được trình chiếu.

#### 1. From Demo to Deployment: Solving Agentic AI's Toughest Challenges

Phiên này mô tả Amazon Bedrock như một nền tảng để **xây ứng dụng và agent AI ở quy mô lớn**, chia làm hai nửa:

- **Models và inference:** models, inference và monitoring, cùng fine-tuning, knowledge bases và model distillation.
- **Phát triển agent:** **AgentCore**, nền tảng phát triển agent mở, dùng được với mọi model và mọi framework, và Bedrock Managed Agents chạy bằng OpenAI (model OpenAI và harness của OpenAI).
- **Bên dưới cả hai:** bảo mật, guardrails và quản trị.

Phần về tin cậy kết thúc bằng năm điểm rút ra: bảo mật không phải tuỳ chọn, cô lập các session, tích hợp với hệ thống định danh sẵn có, áp chính sách trước khi thực thi ở quy mô lớn, và xác định ranh giới rõ ràng. Sau đó Katalon giới thiệu nền tảng AI cho chất lượng phần mềm xây trên AWS, kiểm chứng độc lập code do AI sinh ra qua một hệ thống ghi nhận có quản trị.

#### 2. Building High-Quality Data Products for AI Agents

Đây là phiên chi tiết nhất. Mạch chính: **agent chỉ tốt bằng dữ liệu nó đọc**, nên dữ liệu phải được làm cho "sẵn sàng cho AI".

**Một sự thật sai làm nhiễm mọi tầng.** Chất lượng phải được đảm bảo ở nơi dữ liệu được tạo ra, không phải nơi nó được dùng. Ví dụ là một fintech chạy nền tảng thẻ và cho vay: chargeback và reversal được lưu như các sự kiện riêng và không bao giờ bị trừ đi, nên chỉ số `monthly_spend` bị sai. Nó được công bố lên catalog không có định nghĩa, hiển thị thành "chi tiêu tăng 40%, khách hàng này có vẻ khoẻ mạnh", được một agent hạn mức tín dụng đọc như sự thật, và cuối cùng tự động nâng hạn mức cho hàng nghìn khách. Một người sẽ thấy bước nhảy và hỏi lại bộ phận vận hành, nên lỗi dừng ở đó; agent không có ai để chất vấn, nên lỗi biến thành hành động. Chặn lỗi từ nguồn là việc của **data contract**.

**Cấu trúc của một data contract.** Với data product `monthly_spend` (v2.1), contract nêu chủ sở hữu nghiệp vụ (Card Risk) và người quản lý (Payments Data Engineering), rồi bao gồm ba mảng:

| Mảng | Thành phần | Ví dụ |
|---|---|---|
| Manage | Quality rules | Mỗi reversal khớp một giao dịch gốc; `net_spend` ≤ settled; tăng quá 30% so với tháng trước bị gắn cờ |
| Manage | Freshness | Cập nhật trước 06:00 mỗi ngày; cũ hơn 24 giờ bị gắn cờ không dùng được |
| Manage | Version | Thay đổi được xem lại và thông báo cho mọi bên dùng trước khi phát hành |
| Understand | Schema | Các cột có tên; thay đổi phá vỡ cần phiên bản mới |
| Understand | Meaning | `net_spend` = settled − chargebacks − reversals, theo tháng dương lịch |
| Protect | Access | Agent chỉ đọc tổng, không có số thẻ; mọi lần đọc đều được ghi log |

"Không có contract thì không có data product: chỉ là một cái bảng mà ai đó hy vọng là đúng."

**"Sẵn sàng cho AI" giờ phải nghĩa là gì.** Mọi phán đoán mà một nhà phân tích con người cung cấp miễn phí giờ phải nằm trong chính dữ liệu, qua năm thuộc tính: **trusted** (chính xác, mới và đã được kiểm tra trước khi agent thấy), **contextual** (ý nghĩa nghiệp vụ được nêu rõ), **traceable** (agent đã làm gì và tại sao, ghi lại ngay khi xảy ra), **governed** (bị giới hạn theo thiết kế: có phạm vi, được kiểm soát, kiểm toán được) và **operational** (hành động được, không chỉ đọc được). Thiếu một thứ, agent không suy giảm nhẹ nhàng như con người; nó sai một cách tự tin.

**Bốn khối xây dựng, theo thứ tự cần xây:** (1) data contract và chất lượng, (2) truy vết và quản trị, (3) lớp ngữ cảnh, (4) từ tìm kiếm được đến hành động được. Thứ tự quan trọng: bắt đầu từ chất lượng, vì mọi tầng xây lên trên đều thừa hưởng lỗi của nó.

**Một bản sao, mọi engine, mọi agent.** Một data product chỉ giúp agent nếu mọi engine và mọi agent đều tiếp cận được nó: định dạng bảng mở (lưu một lần, ví dụ Apache Iceberg trên Amazon S3 Tables), engine mở (Athena, Redshift và Spark trên EMR hoặc Glue đọc cùng một bảng qua Glue Data Catalog), và giao thức mở (agent dùng dữ liệu và công cụ qua MCP và giao việc cho agent khác qua A2A, thông qua AgentCore Gateway và Runtime). Contract đi cùng dữ liệu: cùng kiểm tra chất lượng, cùng mục trong catalog và cùng quyền Lake Formation áp dụng cho mọi người đọc.

**Truy xuất dữ liệu, vấn đề cốt lõi.** Trước khi viết code agent, trả lời ba câu hỏi: agent cần dữ liệu gì, dữ liệu nằm ở đâu, và cơ chế truy xuất nào phù hợp. Bốn cơ chế được so sánh: semantic search / RAG (nội dung phi cấu trúc), structured lookup (bản ghi chính xác qua SQL hoặc API), graph traversal (quan hệ thực thể và đường đi nhiều bước) và cached context (ngữ cảnh ổn định, tần suất cao). Một quy tắc nổi bật: thiết kế cho sự im lặng, không chỉ cho dữ liệu xấu, vì agent bịa ra không chỉ từ dữ liệu sai mà còn từ dữ liệu vắng mặt.

**Chat với dữ liệu của bạn.** Text-to-SQL chính xác và tất định hơn nhiều khi có semantic layer, tốt hơn 25–50 điểm phần trăm bất kể model nào. Mức reasoning effort ít tạo khác biệt, và chất lượng mô hình hoá dữ liệu là yếu tố chính của tính tất định.

**Cách Vanguard xây dữ liệu sẵn sàng cho AI** (AWS Machine Learning Blog, tháng 4/2026): tám nguyên tắc — data product và mô hình vận hành với một chủ sở hữu cho mỗi tài sản, quản trị và bảo mật, catalog metadata hợp nhất, semantic layer, ví dụ chuẩn (50+ cặp câu hỏi-SQL), kiểm tra chất lượng tự động, kiểm soát thay đổi với định nghĩa dưới dạng code, và đánh giá liên tục. Kết quả: thời gian ra insight từ vài ngày xuống vài phút, tự phục vụ không cần SQL, độ chính xác SQL cao, và dùng lại trên toàn doanh nghiệp.

#### 3. Migration at Scale with AWS Transform

AWS Transform tự động hoá hiện đại hoá code quy mô lớn — nâng cấp Java, chuyển .NET, di chuyển framework và xoá nợ kỹ thuật — bằng cách mô tả phép biến đổi bằng ngôn ngữ tự nhiên rồi để các agent tự động lên kế hoạch, thực thi và kiểm tra. Kiến trúc tham chiếu để điều phối một cuộc migration gồm các phần:

- **Con người và giao diện:** kỹ sư và người duyệt làm việc từ Kiro (IDE hoặc CLI), điều khiển các job và cổng duyệt của AWS Transform qua MCP server.
- **AWS Transform:** một migration agent gồm các bước job ghép được (khám phá, lập kế hoạch migration, dựng landing zone, migrate mạng, migrate server, container hoá), với duyệt qua chat, người duyệt cho kế hoạch, mạng và cutover, và worklog làm dấu vết kiểm toán.
- **Nguồn và đích:** môi trường nguồn (VMware, Hyper-V, Nutanix, KVM, bare metal) với công cụ khám phá, và các tài khoản AWS đích nhiều tài khoản với landing zone Control Tower và hạ tầng dưới dạng code (CloudFormation, CDK, Terraform).
- **Agent tuỳ biến trên AgentCore:** bộ Agent Builder cho phép agent tuỳ biến chạy trên Amazon Bedrock AgentCore (runtime, gateway, identity qua Cognito, memory, guardrails với chính sách Cedar, CloudWatch và CloudTrail) và tích hợp với ticketing (ServiceNow, Jira) và thông báo SNS.

#### 4. Workshop A — Build with Kiro: From Spec to Working Application (track tôi tham gia)

Workshop A dạy phát triển hướng đặc tả trong Kiro, IDE agentic của AWS, bằng cách xây một ứng dụng từ đầu với các solutions architect của AWS hỗ trợ tại chỗ. Workshop chạy theo kiểu "Kiro Express" có hướng dẫn trên AWS Workshop Studio: người tham dự vào sự kiện bằng một mã truy cập, mở Kiro từ phần event outputs, và làm theo các bước workshop bắt đầu từ "Initialize the project". Không cần cài gì và không cần tài khoản AWS. AWS tài trợ **1.000 credit Kiro cho mỗi người tham dự, dùng trong một ngày**, để mọi người xây và thử thoải mái với model Claude Opus mới nhất.

Ứng dụng tôi xây là một web game: tôi biến **Flappy Bird thành "Flappy Kiro"**. Quy trình theo luồng spec của Kiro:

1. **Requirements.** Mô tả game muốn làm; Kiro soạn yêu cầu và tôi xem lại.
2. **Design.** Kiro soạn thiết kế và kế hoạch công việc từ yêu cầu đã duyệt, tôi xem lại trước khi viết bất kỳ dòng code nào.
3. **Build và sửa lỗi.** Hướng dẫn Kiro thực hiện từng task và sửa lỗi khi phát sinh.
4. **Chạy và test.** Chạy ứng dụng và chơi thử game.

Kết quả là một ứng dụng chạy được, xây theo đặc tả trước, và một quy trình dùng lại cho tính năng tiếp theo. Điều làm buổi này đáng giá là được thấy toàn bộ quá trình xây một ứng dụng bằng Kiro, từ ý tưởng bằng lời thường đến game chạy được, chứ không chỉ kết quả cuối.

*Workshop B, cùng khung giờ, là track còn lại (tôi không tham gia): xây một AI agent bằng Kiro, deploy lên Amazon Bedrock AgentCore, mở rộng từng bước, và xem điều gì cần thiết để vận hành agent trong production.*

#### 5. Customer Spotlight — Kyanon Digital

Bui Hoang Viet, DevOps Engineer tại Kyanon Digital, trình bày *Beyond Single-YAML: Taming the Blast Radius of LLM Remediation in Kubernetes*.

- **LLM remediation hiện nay** làm việc theo từng đơn vị: một phát hiện của Trivy thành một prompt, LLM viết ra YAML đã vá, sau đó dry-run rồi apply. Kết quả đã công bố trông rất tốt: precision 0,990 (GenKubeSec) và 94% sửa thành công trên 1.000 manifest (LLMSecConfig). Điểm yếu nằm ở đơn vị đầu vào: **một phát hiện cộng một manifest**, không nhìn thấy các service gọi nhau thế nào.
- **Hệ thống đề xuất** thêm ngữ cảnh cụm. Các phát hiện của Trivy và metric mesh của Prometheus (các cạnh call-graph) được gộp thành ClusterContext. **Nhánh trên** quyết định đường tấn công nào quan trọng nhất: một bộ ưu tiên xếp hạng top-k đường (Bellman-Ford), và một LLM annotator gắn nhãn chúng bằng kỹ thuật MITRE ATT&CK (truy xuất từ chỉ mục FAISS) và viết mô tả rủi ro, tạo ra một báo cáo tấn công. **Nhánh dưới** viết bản vá rồi kiểm tra nó: remediation sinh bản vá, kiểm tra schema và chạy health gate, và bước "functional blast radius" xác nhận phát hiện đã được xoá, các cạnh gọi được giữ nguyên và health gate qua.
- **Cụm thử nghiệm** có 36 deployment, 4 namespace, 51 cạnh gọi và 31 phát hiện được chèn vào. 25 phát hiện phụ thuộc topology (bản sửa đúng cần một giá trị chỉ cụm đang chạy mới có) và 6 độc lập topology (bản sửa được viết đầy đủ trong nội dung phát hiện), dùng làm nhóm đối chứng.

Ý chính của bài nói: một bản vá đóng được một phát hiện vẫn có thể làm hỏng service bên cạnh, nên remediation phải được đánh giá bằng blast radius, không chỉ bằng việc phát hiện có biến mất hay không.

### Hình ảnh / Video

**Ảnh 1: Tại phông nền sự kiện**
![Tại phông nền AWS for Software & Financial Services Companies Day](/images/events/aws-sw-fsi-day-1.png)
*Tại lối vào sự kiện, Sheraton Saigon Grand Opera, ngày 8/10*

**Ảnh 2: Phần giới thiệu workshop trên sân khấu**
![Diễn giả giới thiệu Workshop B trên sân khấu](/images/events/aws-sw-fsi-day-2.png)
*Phần giới thiệu workshop buổi chiều cho cả hai track; slide hiện Workshop B về Amazon Bedrock AgentCore với Kiro*

**Ảnh 3: Thẻ tham dự**
![Thẻ tham dự của Trần Minh Duy](/images/events/aws-sw-fsi-day-3.png)
*Thẻ tham dự của tôi*

### Bài học rút ra

**1. Một bản demo chạy được chưa phải là một dịch vụ production.**
Phiên mở đầu và mô tả Workshop B đều nói cùng một ý: xây, deploy, mở rộng, rồi vận hành. Amazon Bedrock và AgentCore đặt bảo mật, guardrails và quản trị bên dưới mọi model và agent, chứ không phải thêm vào sau. Việc deploy Fitness Assistant lên AWS cho thấy cùng khoảng cách đó: một dịch vụ chạy được trên máy vẫn cần bảo mật, giám sát và quy trình deploy lặp lại được trước khi tính là production.

**2. Một sự thật sai làm nhiễm mọi tầng, nên chất lượng phải được đảm bảo ở nơi dữ liệu được tạo ra.**
Ví dụ fintech cho thấy một phép trừ bị thiếu trong một chỉ số (`monthly_spend`) đi qua pipeline, catalog và semantic layer cho đến khi một agent dùng nó để nâng hạn mức tín dụng cho hàng nghìn khách. Một người sẽ nhận ra bước nhảy và hỏi lại; agent không có ai để chất vấn, nên lỗi biến thành hành động. Cách xử lý là **data contract**: có chủ sở hữu và người quản lý, quy tắc chất lượng, độ mới, phiên bản, ý nghĩa được nêu rõ, và quyền truy cập có giới hạn với mọi lần đọc được ghi log. Với Fitness Assistant, đây là lý do mỗi loại dữ liệu có một chủ sở hữu có thẩm quyền duy nhất, và một dự báo không bao giờ ghi đè một số đo thực.

**3. Dữ liệu "sẵn sàng cho AI" nghĩa là năm điều: trusted, contextual, traceable, governed và operational.**
Mọi phán đoán mà nhà phân tích con người cung cấp miễn phí giờ phải nằm trong chính dữ liệu. Thiếu một thứ, agent không suy giảm nhẹ nhàng như con người; nó sai một cách tự tin. Đây là lý do AI coach chỉ đề xuất và chờ người dùng xác nhận, và mọi đề xuất đều được ghi lại để có thể giải thích quyết định sau này.

**4. Truy xuất dữ liệu phải được thiết kế, kể cả cho trường hợp im lặng.**
Trước khi viết code agent, cần quyết định agent cần dữ liệu gì, dữ liệu nằm ở đâu và cơ chế truy xuất nào phù hợp: semantic search cho tài liệu, structured lookup cho bản ghi chính xác, graph traversal cho quan hệ, cached context cho quy tắc ổn định. Agent bịa ra không chỉ từ dữ liệu sai mà còn từ dữ liệu vắng mặt, nên truy xuất nên trả về rõ ràng "không tìm thấy". Một semantic layer làm text-to-SQL chính xác hơn 25–50 điểm phần trăm bất kể model nào, nghĩa là mô hình hoá dữ liệu quan trọng hơn một model lớn hơn.

**5. Sửa chất lượng trước, và chỉ mở dữ liệu một lần qua chuẩn mở.**
Thứ tự bốn khối xây dựng rất quan trọng: bắt đầu từ data contract và chất lượng, rồi truy vết và quản trị, rồi lớp ngữ cảnh, rồi mới làm dữ liệu hành động được. Một bản sao dữ liệu ở định dạng mở, mọi engine và agent đều đọc được qua MCP và A2A, tránh việc các bản sao lệch nhau và tránh khoá mọi agent vào một công cụ.

**6. Một bản sửa chỉ tốt nếu không làm hỏng những thứ bên cạnh.**
Bài của Kyanon cho thấy LLM remediation có thể trông rất tốt theo từng phát hiện (precision 0,990, sửa thành công 94%) mà một bản vá vẫn làm hỏng service bên cạnh. Đánh giá một thay đổi bằng "blast radius" — phát hiện được xoá, các cạnh gọi được giữ nguyên, health gate qua — cùng kỷ luật với việc kiểm chứng một lần deploy bằng bước kiểm tra sau-apply.

**7. Ranh giới bảo mật đi trước quy mô.**
Các điểm rút ra về tin cậy là: bảo mật không phải tuỳ chọn, cô lập session, tích hợp với định danh sẵn có, áp chính sách trước khi thực thi ở quy mô lớn, và xác định ranh giới rõ ràng. Chúng khớp với cách dự án tách người dùng: mọi bề mặt thuộc về người dùng phải giữ cô lập qua đăng xuất, đăng nhập và đổi tài khoản.

**8. Phát triển hướng đặc tả hợp với dự án có quy tắc sở hữu dữ liệu chặt.**
Việc xây Flappy Kiro ở Workshop A — yêu cầu, rồi thiết kế, rồi kế hoạch công việc, rồi build và chơi thử — giống cách xử lý thay đổi ở Fitness Assistant: tìm hiểu, xác định cái gì sở hữu dữ liệu, rồi mới triển khai. Xem lại yêu cầu và thiết kế trước khi viết code là điều giữ cho kết quả dự đoán được.

### Đóng góp cá nhân

Tôi tham dự trực tiếp và theo dõi các phiên buổi sáng. Ở Workshop A, tôi tự làm phần thực hành: dùng Kiro với model Claude Opus mới nhất (trên 1.000 credit AWS tài trợ trong ngày) để biến Flappy Bird thành Flappy Kiro, đi qua requirements, rồi design, rồi chạy và test ứng dụng. Sau đó tôi so sánh quy trình hướng đặc tả này với cách thiết kế và triển khai thay đổi ở Fitness Assistant.

### Link bằng chứng

**Trang sự kiện chính thức:**
[AWS for Software & Financial Services Companies Day](https://aws-experience.com/apj/smb/event/a838fd41-1aeb-4ee8-a3d9-636583344707)

**Vé đăng ký:**
[Vé sự kiện của tôi](https://luma.com/e/ticket/evt-7FMzezxlttxLCjI?pk=g-ZTbdpfRmRBdRrtW)

**Thông tin chính:**
- **Thời gian:** Thứ Năm, ngày 8 tháng 10 năm 2026, 09:00 – 18:00
- **Địa điểm:** Sheraton Saigon Grand Opera Hotel, 88 Đồng Khởi, Quận 1, Thành phố Hồ Chí Minh
- **Bằng chứng:** vé đăng ký và các ảnh phía trên (phông nền sự kiện, phần giới thiệu workshop, thẻ tham dự)
