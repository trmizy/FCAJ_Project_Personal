---
title: "Blog 3: RAG multi-tenant an toàn với Amazon Bedrock và Verified Permissions"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 3.3. </b> "
draft: false
---

## RAG multi-tenant an toàn với Amazon Bedrock và Verified Permissions

**Bài gốc:** [Secure multi-tenant RAG with Amazon Bedrock and Verified Permissions](https://aws.amazon.com/blogs/architecture/secure-multi-tenant-rag-with-amazon-bedrock-and-verified-permissions/) (AWS Architecture Blog, 22/06/2026)

**Chia sẻ trên Facebook:** https://www.facebook.com/groups/awsstudygroupfcj/permalink/2314341139330845/

---

Trong một trợ lý AI dùng chung cho cả doanh nghiệp, phòng ban nào cũng muốn hỏi đáp trên cùng một kho tài liệu, nhưng không phải nhân viên nào cũng được xem mọi tài liệu. Báo cáo tài chính chỉ dành cho phòng tài chính, hồ sơ nhân sự chỉ dành cho phòng nhân sự, trong khi cấp quản lý có thể cần đọc xuyên phòng ban. Một bài viết gần đây trên AWS Architecture Blog trình bày cách thực thi điều này ngay trong một knowledge base dùng chung, bằng cách quyết định tại thời điểm truy xuất (retrieval) những tài liệu nào người dùng được phép dùng.

### 1. Vì sao các cách làm quen thuộc khó mở rộng

- **Mỗi phòng ban một knowledge base:** cô lập rõ ràng, nhưng chi phí và công vận hành tăng theo từng phòng ban mới.
- **Filter viết cứng trong code:** metadata filter kiểu `department = finance` vẫn chạy được, nhưng mỗi lần đổi quy tắc là phải sửa code và deploy lại.
- **Không có nơi ghi lại quyết định:** khi logic phân quyền nằm rải rác trong code, rất khó trả lời câu hỏi "vì sao người dùng này xem được tài liệu kia?".

### 2. Giải pháp: một knowledge base, hai lớp phân quyền

Toàn bộ tài liệu nằm trong một Amazon Bedrock Knowledge Base và được gắn thuộc tính metadata `department`. Quy tắc truy cập được viết bằng Cedar policy trong Amazon Verified Permissions và được đánh giá ở mỗi request:

- **Lớp 1, quyền gọi API.** Một Lambda authorizer trên Amazon API Gateway xác thực JWT của Amazon Cognito và gọi `IsAuthorized` cho từng group của người dùng. Nếu không group nào được phép, hoặc Verified Permissions trả lỗi, người dùng nhận HTTP 403.
- **Lớp 2, quyền đọc tài liệu.** Một middleware Lambda hỏi Verified Permissions người dùng được truy vấn knowledge base của những phòng ban nào, rồi chuyển kết quả thành metadata filter cho lệnh `RetrieveAndGenerate`: `equals` khi chỉ có một phòng ban, `orAll` khi có nhiều phòng ban. Cùng policy store đó cũng quyết định người dùng được gọi model nào.
- **Kiểm tra đầu ra.** Guardrails for Amazon Bedrock kiểm tra câu trả lời có bám vào ngữ cảnh đã truy xuất (contextual grounding) và lọc nội dung độc hại.

Trong ví dụ của bài, dept-a và dept-b chỉ được truy vấn tài liệu của phòng mình và dùng Claude 3 Haiku, còn dept-c được truy vấn mọi phòng ban và dùng Amazon Nova Lite 2. Những gì không được cho phép thì mặc định bị từ chối, và thay đổi policy có hiệu lực ngay ở request tiếp theo mà không cần deploy lại code.

### 3. Luồng xử lý một request

![Luồng xử lý request với hai lớp phân quyền dùng Amazon Verified Permissions](/images/blogs/blog3-request-flow-vi.svg)

*Hình 1 — Luồng xử lý một request qua hai lớp phân quyền. Mã nguồn sơ đồ có thể chỉnh sửa: [file draw.io](../../../files/diagrams/blog3-request-flow-vi.drawio).*

1. **AWS WAF** áp rate limit và các rule. Nếu bị từ chối, request bị chặn.
2. **Lambda authorizer (Lớp 1)** kiểm tra người dùng có được gọi API không. Nếu không, kết quả là 403.
3. **Middleware (Lớp 2)** xác định người dùng được đọc tài liệu của những phòng ban nào. Nếu không có phòng nào, kết quả rỗng.
4. **Bedrock Knowledge Bases** áp metadata filter trước khi vector search, nên model không bao giờ thấy tài liệu không được phép.
5. **Guardrails** kiểm tra câu trả lời có bám vào ngữ cảnh không. Nếu không, câu trả lời bị chặn hoặc chỉnh sửa.

### 4. Gắn nhãn tài liệu khi ingest

1. Tệp được upload lên S3 theo prefix của phòng ban (ví dụ `docs/dept-a/report.pdf`) phát sinh một event EventBridge, được đưa vào hàng đợi SQS.
2. Một Lambda function ghi file sidecar `.metadata.json` bên cạnh tệp, với nội dung `{"metadataAttributes": {"department": "dept-a"}}`. Lần xử lý lỗi được đưa vào dead-letter queue.
3. Cứ năm phút, một Lambda chạy theo lịch gọi `StartIngestionJob`. Bedrock chia tài liệu thành đoạn (300 token, chồng lấp 20%), tạo embedding và đánh index kèm thuộc tính phòng ban.
4. Tài liệu chưa có sidecar bị bỏ qua và ghi log, để một tệp chưa gắn nhãn không bao giờ hiển thị cho tất cả mọi người.

### 5. Checklist triển khai an toàn

- **Hiểu đúng mức cô lập.** Đây là cô lập ở mức filter (logic), không phải cô lập bằng IAM hay hạ tầng riêng. Với các khách hàng khác nhau của một sản phẩm SaaS, bài viết khuyến nghị mỗi tenant một knowledge base riêng.
- **Fail closed.** Cả hai lớp đều từ chối khi Verified Permissions không khả dụng. Cache các quyết định cũ giúp tăng availability, nhưng có thể vẫn cho phép quyền đã bị thu hồi.
- **Giữ cache của authorizer ngắn.** Mặc định 300 giây của API Gateway có thể giữ quyền đã thu hồi tới năm phút. Đặt TTL 0 hoặc 30–60 giây thì thu hồi nhanh hơn, đổi lại nhiều lời gọi Verified Permissions hơn.
- **Bảo vệ policy và nhãn.** Giới hạn ai được tạo, sửa, xóa policy, ghi lại mọi thay đổi bằng CloudTrail, và chỉ cho phép Lambda gắn nhãn được ghi file sidecar. S3 Versioning và Object Lock hỗ trợ việc này.
- **Chú ý khoảng trễ khi ingest.** Có một khoảng ngắn giữa lúc upload và lúc sidecar được tạo. Batching window của SQS (mặc định 30 giây) cần khớp với lịch ingest.
- **Guardrails không chặn được mọi prompt injection**, nên vẫn cần kiểm tra độ dài input và làm sạch câu truy vấn.

### Góc nhìn cá nhân

Điều mình thích nhất ở mô hình này là phân quyền trở thành dữ liệu thay vì code. Thêm một phòng ban chỉ cần một Cedar policy, một Cognito group và tài liệu đã gắn nhãn, không cần thêm hạ tầng.

AI service của Fitness Assistant đã làm retrieval-augmented generation với Amazon Bedrock và vector index trên OpenSearch Serverless (xem Workshop [5.4.8](../../5-Workshop/5.4-Deployment-Guide/5.4.8-AI-Service-Core/) và [5.4.9](../../5-Workshop/5.4-Deployment-Guide/5.4.9-AI-Service-Vector-Search/)). Index này được các job theo lịch nạp từ những nguồn dùng chung như PubMed, RSS feed và bài viết trên web. Quyền được kiểm soát theo từng function bằng IAM: mỗi Lambda role chỉ được gọi đúng các model Bedrock nó cần, và các route AI bị giới hạn tần suất trên API Gateway. Mô hình trong bài sẽ hữu ích ngay khi tài liệu riêng tư được đưa vào index, ví dụ tài liệu nội bộ của một phòng gym chỉ dành cho huấn luyện viên và hội viên của phòng đó. Khi ấy, một Cedar policy cho mỗi phòng gym cùng thuộc tính metadata `gym_id` sẽ hợp lý hơn việc tạo một index riêng cho từng phòng.

### Kết luận

Mô hình này kết hợp ba ý chính: một knowledge base dùng chung có metadata, Cedar policy nằm ngoài code và thay đổi được lúc runtime, và hai lớp phân quyền độc lập cùng fail closed. Đây là cách tiết kiệm chi phí để mỗi phòng ban có góc nhìn riêng trên dữ liệu dùng chung, miễn là đội ngũ nhớ rằng đây là cô lập logic và bảo vệ policy cùng nhãn tài liệu cẩn thận như chính tài liệu.

### Tài liệu tham khảo

- AWS Architecture Blog: [Secure multi-tenant RAG with Amazon Bedrock and Verified Permissions](https://aws.amazon.com/blogs/architecture/secure-multi-tenant-rag-with-amazon-bedrock-and-verified-permissions/)
- [Tài liệu Amazon Verified Permissions](https://docs.aws.amazon.com/verifiedpermissions/)
- [Tài liệu Amazon Bedrock Knowledge Bases](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html)
- [Ngôn ngữ policy Cedar](https://www.cedarpolicy.com/)
