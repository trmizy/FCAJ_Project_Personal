---
title: "Blog 4: Giới hạn truy cập AWS Management Console từ mạng tin cậy"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 3.4. </b> "
draft: false
---

## Giới hạn truy cập AWS Management Console từ mạng tin cậy bằng sign-in policy và RCP

**Bài gốc:** [Restrict AWS Management Console access to expected networks with sign-in resource-based policies and RCPs](https://aws.amazon.com/blogs/security/restrict-aws-management-console-access-to-expected-networks-with-sign-in-resource-based-policies-and-rcps/) (AWS Security Blog, 24/06/2026)

**Chia sẻ trên Facebook:** https://www.facebook.com/share/p/19qBt1z5fU/

---

Với phần lớn các đội ngũ, AWS Management Console là cánh cửa quyền lực nhất để vào một tài khoản AWS: ai đăng nhập được là xem và thay đổi được gần như mọi thứ mà quyền của họ cho phép. Mật khẩu và MFA chứng minh người dùng là ai, nhưng không cho biết request đến từ đâu. Tháng 6/2026, AWS Sign-In bổ sung resource-based policy và resource control policy (RCP), nhờ đó một tài khoản, hoặc cả một organization, có thể từ chối việc đăng nhập console từ những mạng không mong đợi. Một bài viết trên AWS Security Blog hướng dẫn chi tiết cơ chế kiểm soát mới này.

### 1. Vì sao trước đây khó giới hạn đăng nhập theo mạng

- **Điều kiện trong IAM và SCP chỉ có tác dụng sau khi đăng nhập.** Điều kiện như `aws:SourceIp` trong IAM policy hay SCP có thể từ chối các API action từ mạng lạ, nhưng người dùng vẫn đăng nhập và mở được console.
- **Quy tắc của identity provider chỉ áp dụng cho người dùng federated.** Quy tắc mạng trong một identity provider bên ngoài không áp dụng cho IAM user hay root user.
- **Không có một nơi thực thi chung.** Mỗi tài khoản và mỗi loại danh tính lại cần một cách xử lý riêng.

### 2. Cơ chế mới: sign-in policy và RCP

- **Sign-in resource-based policy, cho một tài khoản.** Người quản trị mô tả các mạng được mong đợi bằng vài tham số (dải IP nguồn, VPC nguồn cùng Region của nó, và một principal được loại trừ), rồi AWS Sign-In tự sinh policy: các câu lệnh deny chặn đăng nhập trừ khi request đến từ mạng được mong đợi hoặc từ principal được loại trừ.
- **Resource control policy, cho nhiều tài khoản.** Cùng các quy tắc đó, gắn trong AWS Organizations ở mức organization, organizational unit hoặc một tài khoản, và tự áp dụng cho mọi tài khoản trong phạm vi.
- **Một công tắc để bật.** Các câu lệnh chưa có tác dụng cho đến khi console authorization được bật cho tài khoản, nên có thể rà soát trước khi thực thi.

Cơ chế này không tốn thêm chi phí và có ở mọi AWS commercial Region. Nó không thay thế IAM identity-based policy, vốn vẫn quyết định người dùng đã đăng nhập được làm gì.

### 3. Một request đăng nhập được kiểm tra thế nào

{{< mermaid >}}
graph LR
  S[Request đăng nhập] --> N{Mạng được mong đợi hoặc principal được loại trừ}
  N -- không --> D[Bị từ chối và ghi vào CloudTrail]
  N -- có --> A[Mật khẩu và MFA]
  A --> T[Token phiên console]
  T -- kiểm tra lại khi làm mới --> N
  T --> I[IAM policy quyết định từng action]
{{< /mermaid >}}

1. **Trước khi kiểm tra thông tin đăng nhập**, AWS Sign-In đánh giá action `signin:Authenticate` theo policy. Request từ ngoài dải IP hoặc VPC được mong đợi sẽ bị từ chối, kể cả khi mật khẩu và MFA đúng, trừ khi đến từ principal được loại trừ.
2. **Xác thực bình thường** diễn ra sau đó: mật khẩu và MFA, hoặc đăng nhập federated.
3. **Khi console xin token phiên** (`signin:CreateOAuth2Token` và `signin:AuthorizeOAuth2Access`), cùng các quy tắc mạng được đánh giá lại, và lặp lại mỗi lần phiên xin credential mới.
4. **Ràng buộc Region** chặn request tự nhận đến từ VPC được phép nhưng lại xin một Region khác, vì VPC ID chỉ là duy nhất trong một Region.
5. **Mọi lần thử đều được ghi lại** thành event `ConsoleLogin` trong CloudTrail. Lần bị chặn hiện `AccessDenied` kèm thông báo "Authorization denied because of a resource-based policy", hoặc "...resource control policy" nếu RCP chặn.

### 4. Checklist triển khai an toàn

- **Liệt kê các mạng được mong đợi trước:** dải IP egress của văn phòng và VPN, cùng các VPC ID (kèm Region) mà người dùng đăng nhập từ đó.
- **Luôn giữ một principal được loại trừ** để truy cập khẩn cấp (break-glass), tránh việc khai báo sai dải IP khóa tất cả mọi người ở ngoài.
- **Tạo, rà soát, rồi mới bật.** Tạo các câu lệnh (thao tác ghi thực hiện ở `us-east-1`), rà soát bằng `aws signin get-resource-policy`, và chỉ sau đó mới chạy `aws signin put-console-authorization-configuration`.
- **Biết cách quay lui:** `delete-console-authorization-configuration` tắt việc thực thi, còn `delete-resource-permission-statement` xóa một câu lệnh.
- **Bắt đầu với một tài khoản thử nghiệm**, rồi chuyển sang RCP ở mức organization hoặc OU khi nhiều tài khoản cần cùng một quy tắc.
- **Theo dõi CloudTrail** để thấy các lần `ConsoleLogin` thất bại do sign-in policy, vừa phát hiện tấn công vừa phát hiện người dùng hợp lệ đang ở mạng mới.
- **Kết hợp với Console Private Access** và VPC endpoint policy để xây dựng đủ ba lớp perimeter: mạng, danh tính và tài nguyên.

### Góc nhìn cá nhân

Điều mình thích ở cơ chế này là nó đưa bước kiểm tra lên ngay đầu tiên. Kẻ tấn công lừa lấy được cả mật khẩu lẫn mã MFA vẫn không dùng được chúng từ một mạng lạ.

Môi trường DEV của Fitness Assistant được dựng phần lớn qua AWS Management Console (xem Workshop [5.4](../../5-Workshop/5.4-Deployment-Guide/)), nên đăng nhập console là cách vào tài khoản đó mạnh nhất. MFA đã bảo vệ bước này, nhưng dự án không có mạng văn phòng cố định. Trước khi bật sign-in policy, mình cần một địa chỉ nguồn ổn định, ví dụ VPN có IP egress cố định hoặc một VPC truy cập qua Console Private Access, cùng một principal break-glass được loại trừ, để việc đổi IP ở nhà không khóa chính mình khỏi tài khoản.

### Kết luận

Sign-in resource-based policy và RCP lấp được khoảng trống mà IAM policy không làm được: chúng quyết định một phiên console có được bắt đầu hay không, dựa trên nơi request xuất phát. Policy được sinh từ vài tham số, rà soát trước khi thực thi, ghi log trong CloudTrail và miễn phí. Vì vậy đây là một lớp bảo vệ dễ thêm cho bất kỳ tài khoản nào được quản lý qua console, miễn là luôn giữ một principal được loại trừ làm đường quay lại an toàn.

### Tài liệu tham khảo

- AWS Security Blog: [Restrict AWS Management Console access to expected networks with sign-in resource-based policies and RCPs](https://aws.amazon.com/blogs/security/restrict-aws-management-console-access-to-expected-networks-with-sign-in-resource-based-policies-and-rcps/)
- [AWS Sign-In User Guide: console access control](https://docs.aws.amazon.com/signin/latest/userguide/console-access-control.html)
- [AWS Organizations: resource control policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html)
- [Data perimeter policy examples (aws-samples)](https://github.com/aws-samples/data-perimeter-policy-examples)
