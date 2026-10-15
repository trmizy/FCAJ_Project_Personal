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
- Tìm hiểu cách giới hạn đăng nhập AWS Management Console chỉ từ các mạng được mong đợi bằng sign-in resource-based policy và resource control policy (RCP)

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Viết Blog 2, "Giới hạn truy cập AWS Management Console từ mạng tin cậy", và đăng lên AWS Study Group VN Facebook group | 28-9-2026 | 03-10-2026 | [Bài gốc trên AWS Security Blog](https://aws.amazon.com/blogs/security/restrict-aws-management-console-access-to-expected-networks-with-sign-in-resource-based-policies-and-rcps/) <br>[Bài đăng trên Facebook](https://www.facebook.com/share/p/19qBt1z5fU/) |

### Kết quả đạt được tuần 9:

**Tổng quan:**

Tuần này dành cho community contribution và knowledge sharing. Mình tìm hiểu một bài trên AWS Security Blog về tính năng mới của AWS Sign-In giúp giới hạn đăng nhập console chỉ từ các mạng được mong đợi, rồi viết và đăng Blog 2 về chủ đề này lên AWS Study Group VN, liên hệ với cách quản lý tài khoản của Fitness Assistant.

**Kiến thức lý thuyết học được:**

- **Sign-in resource-based policy:** Các câu lệnh deny gắn vào AWS Sign-In cho một tài khoản, được sinh từ dải IP nguồn, VPC nguồn và một principal được loại trừ. Policy được kiểm tra trước khi xác thực thông tin đăng nhập (`signin:Authenticate`) và lặp lại mỗi khi phiên console xin token, và chỉ có hiệu lực sau khi bật console authorization.

- **Resource control policy (RCP):** Cùng các quy tắc mạng đó, áp dụng qua AWS Organizations cho mọi tài khoản trong một organization hoặc organizational unit.

- **Technical Writing:** Học cách effectively communicate technical concepts tới broader audience.

**Hands-on labs đã thực hiện:**

- Viết và đăng Blog 2 trong AWS Study Group VN Facebook group

**Áp dụng vào Fitness Assistant:**

Môi trường DEV của Fitness Assistant được dựng phần lớn qua AWS Management Console (xem Workshop 5.4), nên đăng nhập console là cách vào tài khoản mạnh nhất. Các cơ chế trong blog sẽ thêm một điều kiện về mạng bên cạnh MFA:
- Chỉ cho phép đăng nhập từ mạng được mong đợi, ví dụ VPN có IP egress cố định hoặc một VPC truy cập qua Console Private Access
- Giữ một principal break-glass được loại trừ, để việc đổi IP ở nhà không khóa tài khoản
- Theo dõi các lần `ConsoleLogin` thất bại do sign-in policy trong CloudTrail
- Dùng RCP thay cho policy từng tài khoản nếu sau này dự án mở rộng ra nhiều tài khoản

### Liên kết Workshop tương ứng:

- [3.2 Blog 2](../../3-BlogsPosted/3.2-Blog2/) - Giới hạn truy cập AWS Management Console từ mạng tin cậy
- [5.2.5 Bảo mật và IAM](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/) - Cách dự án đang bảo vệ quyền truy cập hiện nay
