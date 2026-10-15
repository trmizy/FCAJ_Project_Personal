---
title: "Worklog Tuần 9"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 1.9. </b> "
draft: false
---

# WORKLOG TUẦN 9

### Mục tiêu tuần 9:

- Chia sẻ kiến thức với cộng đồng bằng cách viết technical blog post
- Tìm hiểu cách bảo mật retrieval-augmented generation (RAG) dùng chung cho nhiều nhóm với Amazon Bedrock và Amazon Verified Permissions

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Viết Blog 2, "RAG multi-tenant an toàn với Amazon Bedrock và Verified Permissions", và đăng lên AWS Study Group VN Facebook group | 28-9-2026 | 03-10-2026 | [Bài gốc trên AWS Architecture Blog](https://aws.amazon.com/blogs/architecture/secure-multi-tenant-rag-with-amazon-bedrock-and-verified-permissions/) <br>[Bài đăng trên Facebook](https://www.facebook.com/share/p/19qBt1z5fU/) |

### Kết quả đạt được tuần 9:

**Tổng quan:**

Tuần này dành cho community contribution và knowledge sharing. Mình tìm hiểu một bài trên AWS Architecture Blog về cách giữ an toàn cho một knowledge base RAG dùng chung cho nhiều phòng ban, rồi viết và đăng Blog 2 về chủ đề này lên AWS Study Group VN, liên hệ với AI service của Fitness Assistant.

**Kiến thức lý thuyết học được:**

- **Phân quyền ở mức tài liệu cho RAG:** Một Amazon Bedrock Knowledge Base dùng chung, mỗi tài liệu gắn thuộc tính metadata `department`, và Cedar policy trong Amazon Verified Permissions quyết định tại thời điểm truy xuất những tài liệu nào người dùng được dùng. Quy tắc thay đổi được mà không cần deploy lại code.

- **Defense in depth:** Hai lớp độc lập cùng fail closed: Lambda authorizer trên API Gateway cho quyền gọi API, và middleware Lambda chuyển quyết định của policy thành metadata filter cho `RetrieveAndGenerate`. Sau đó Guardrails for Amazon Bedrock kiểm tra câu trả lời có bám vào ngữ cảnh.

- **Technical Writing:** Học cách effectively communicate technical concepts tới broader audience.

**Hands-on labs đã thực hiện:**

- Viết và đăng Blog 2 trong AWS Study Group VN Facebook group

**Áp dụng vào Fitness Assistant:**

AI service của Fitness Assistant đã làm RAG với Amazon Bedrock và vector index trên OpenSearch Serverless, được các job theo lịch nạp từ những nguồn dùng chung như PubMed, RSS feed và bài viết trên web. Mô hình trong blog áp dụng được ngay khi tài liệu riêng tư được đưa vào index:
- Thuộc tính metadata như `gym_id` cho mỗi tài liệu riêng tư
- Một Cedar policy cho mỗi phòng gym thay vì một index cho mỗi phòng
- Cache của authorizer ngắn, để quyền bị thu hồi hết hiệu lực nhanh
- Fail closed khi dịch vụ policy không khả dụng

### Liên kết Workshop tương ứng:

- [3.2 Blog 2](../../3-BlogsPosted/3.2-Blog2/) - RAG multi-tenant an toàn với Amazon Bedrock và Verified Permissions
- [5.4.9 AI Service — vector search, lịch chạy và API](../../5-Workshop/5.4-Deployment-Guide/5.4.9-AI-Service-Vector-Search/) - Phần vector search mà blog liên hệ tới
