---
title: "5.8 Xử lý sự cố và hướng phát triển"
date: 2026-10-23
weight: 8
chapter: false
pre: " <b> 5.8. </b> "
---

Trang này liệt kê các vấn đề thật gặp phải khi triển khai và vận hành Gymini trên AWS: phát hiện ra bằng cách nào, đã sửa ra sao, và lần sau nên kiểm tra gì trước. Mỗi mục đều được xác nhận bằng log, phản hồi API hoặc AWS console, không phải suy đoán.

| # | Vấn đề | Tầng | Trạng thái |
|---|---|---|---|
| 1 | Đăng nhập bị chặn bởi CORS | API Gateway | Đã sửa |
| 2 | Chat bị chặn do mixed content | CloudFront, ALB | Đã sửa |
| 3 | Chat trả 503 sau khi bật môi trường | ECS, ALB, CloudFront | Đã sửa, còn một bước làm tay |
| 4 | Lambda timeout hoặc trả 500 khi môi trường đang "nguội" | VPC, Aurora | Đã sửa bằng thứ tự khởi động |
| 5 | Chat task lỗi `URL must start with postgresql://` | ECS, Secrets Manager | Đã sửa |
| 6 | Hạn mức mô hình Bedrock bằng 0 ở tài khoản chính | Bedrock | Đã sửa bằng role chéo tài khoản |
| 7 | Gọi Bedrock vẫn bị từ chối (Converse, mô hình marketplace) | IAM | Đã sửa |
| 8 | Link đặt lại mật khẩu không xuất hiện | Auth Lambda, SMTP | Đã xử lý tạm, có kiểm soát |
| 9 | Một số route có trong code nhưng thiếu trên API Gateway | API Gateway | Khoảng trống đã biết |
| 10 | Cổng CI/CD lỗi hoặc không chạy được | GitHub Actions, CloudFormation | Đã sửa |
| 11 | Change set CloudFormation đã cũ | CloudFormation | Đã tránh |
| 12 | Fitness service không gọi được AI service | Mạng Lambda | Còn mở |

### 1. Đăng nhập bị chặn bởi CORS

- **Triệu chứng:** trang đăng nhập báo lỗi chung. Console của trình duyệt báo `/auth/login` bị chặn bởi chính sách CORS vì thiếu header `Access-Control-Allow-Origin`.
- **Cách phát hiện:** gọi thẳng `curl` tới `/auth/login` với mật khẩu sai trả đúng `401`, nên dịch vụ vẫn khoẻ. Đọc cấu hình CORS của API cho thấy `AllowOrigins` chỉ liệt kê URL S3 website cũ.
- **Cách sửa:** thêm URL CloudFront vào `AllowOrigins` bằng một lệnh `update-api --cors-configuration` mang tính cộng thêm, giữ nguyên origin cũ. Kiểm tra lại cả preflight và `POST` thật: cả hai đều trả `access-control-allow-origin` với domain CloudFront.
- **Lần sau:** khi frontend chuyển sang domain mới, cập nhật origin cho phép của API trong cùng một thay đổi.

### 2. Chat bị chặn do mixed content

- **Triệu chứng:** khung chat báo "Network Error".
- **Nguyên nhân:** trang được CloudFront phục vụ qua HTTPS, nhưng frontend trỏ client Socket.IO thẳng tới load balancer của chat qua HTTP thuần. Trình duyệt chặn tổ hợp này. Load balancer chỉ có listener HTTP cổng 80; muốn thêm HTTPS phải có tên miền riêng và chứng chỉ.
- **Cách sửa:** thêm một origin CloudFront cho load balancer (`http-only` về phía origin) và một behavior `/socket.io/*` tắt cache, chuyển tiếp mọi header, rồi đặt `chatWsUrl` trong `runtime-config.json` thành domain CloudFront. Trình duyệt giờ chỉ nói chuyện với một origin HTTPS.
- **Kiểm chứng:** `GET /socket.io/?EIO=4&transport=polling` qua CloudFront trả `200` kèm handshake Engine.IO (`sid`, `upgrades: ["websocket"]`).

### 3. Chat trả 503 sau khi bật môi trường

- **Triệu chứng:** CloudFront tới được load balancer nhưng câu trả lời là `503`.
- **Nguyên nhân tìm được:** (a) ECS service có `desiredCount: 0`, nên target group không có target khoẻ; (b) load balancer chạy theo yêu cầu và nhận **tên DNS mới** mỗi lần tạo lại, nên origin CloudFront và cấu hình runtime vẫn trỏ về cái cũ.
- **Cách sửa:** scale ECS service lên 1, trỏ origin CloudFront về tên DNS load balancer hiện tại, và ghi lại URL chat HTTPS vào `runtime-config.json`. Đợi distribution deploy xong rồi lặp lại bước kiểm tra Engine.IO.
- **Lần sau:** sau `dev-start`, kiểm tra theo thứ tự: số task ECS đang chạy, domain origin CloudFront, `chatWsUrl`.

### 4. Lambda timeout hoặc trả 500 khi môi trường đang "nguội"

- **Triệu chứng:** lời gọi một Lambda gắn VPC treo đủ 30 giây, hoặc về sau trả `500`.
- **Nguyên nhân tìm được:** NAT Gateway đang tắt, nên hàm cần internet (ví dụ để gửi email) không có đường ra và bị timeout. Khi NAT bật lại, một lời gọi dùng database trả `500` vì cluster Aurora vẫn đang `stopped`.
- **Cách sửa:** bật các tầng theo thứ tự: mạng (NAT), rồi database, rồi các lịch. Script khởi động làm đúng việc này và chỉ bật lại các lịch EventBridge sau khi Aurora `available`.
- **Lần sau:** timeout chỉ về đường mạng; `500` ở lời gọi database chỉ về việc database đang dừng.

### 5. Chat task lỗi `URL must start with postgresql://`

- **Triệu chứng:** Chat task đầu tiên lỗi ngay khi khởi động và Prisma báo URL không hợp lệ.
- **Nguyên nhân:** trong task definition, hai dòng secret có value type *Value* với **tên** secret, nên container nhận tên thay vì chuỗi kết nối.
- **Cách sửa:** đăng ký revision task definition mới trong đó secret dùng **ValueFrom** với ARN đầy đủ cộng hậu tố khoá JSON, rồi cập nhật service với force new deployment. Secret không bao giờ nằm trong environment variable thường.

### 6. Hạn mức mô hình Bedrock bằng 0 ở tài khoản chính

- **Triệu chứng:** mọi lời gọi mô hình theo yêu cầu đều lỗi hạn mức.
- **Cách xác nhận:** Service Quotas cho thấy hạn mức on-demand cấp tài khoản của các mô hình đã chọn là `0` và không nâng được.
- **Cách sửa:** giữ AI service dùng Bedrock nhưng gọi qua một tài khoản AWS thứ hai có hạn mức thật. Một role ở tài khoản đó chỉ tin cậy các execution role của AI Lambda và yêu cầu `ExternalId`; AI service assume role bằng STS cho mỗi lần gọi. Không lưu khoá tĩnh ở đâu cả.
- **Kết quả:** log có các dòng `llm_call` thành công với `provider: bedrock`.

### 7. Gọi Bedrock vẫn bị từ chối dù đã có role

- **Triệu chứng:** `AccessDeniedException` trong log AI Lambda.
- **Nguyên nhân tìm được:** (a) `bedrock:InvokeModel` không bao gồm Converse API, vốn cần action riêng trên cùng tài nguyên; (b) mô hình marketplace như mô hình embedding Cohere cần principal gọi có `aws-marketplace:ViewSubscriptions` và `aws-marketplace:Subscribe`.
- **Cách sửa:** thêm `bedrock:Converse` cạnh `InvokeModel` trên inference profile và mô hình đích, và thêm các action marketplace thành một policy nhỏ riêng. Mỗi thay đổi đều được kiểm tra bằng `iam:SimulatePrincipalPolicy` rồi bằng một lời gọi thật.

### 8. Link đặt lại mật khẩu không xuất hiện

- **Triệu chứng:** yêu cầu đặt lại trả thông báo chung và không có link, trong khi địa chỉ admin có sẵn không có hộp thư thật.
- **Nguyên nhân:** ở chế độ không phải production, dịch vụ chỉ trả link đặt lại dành cho phát triển khi email **chưa được cấu hình**. Lambda đã deploy có đủ bốn thiết lập SMTP, nên nó gửi thật và báo thành công kể cả với địa chỉ không tồn tại.
- **Cách xử lý tạm có kiểm soát:** trong vài phút, chuyển `NODE_ENV` sang development và chỉ xoá trống `SMTP_HOST` trên auth Lambda, yêu cầu đặt lại, hoàn tất bằng cách gọi Lambda trực tiếp, rồi khôi phục môi trường gốc từ bản đã lưu và đọc lại để xác nhận (`NODE_ENV=production`, `SMTP_HOST` được khôi phục, đủ các biến).
- **Lần sau:** cách sửa thật là có luồng đặt lại dùng được cho người dùng thật (xem vấn đề 9).

### 9. Một số route có trong code nhưng thiếu trên API Gateway

- **Triệu chứng:** kiểm tra route parity giữa source code và API đang chạy báo 10 route chỉ có trong source: đặt lại mật khẩu và yêu cầu đặt lại, onboarding đối tác, một webhook chữ ký, và hai link dựa trên token.
- **Nguyên nhân:** mọi route `/auth/*` được cho phép từng cái một và các route này chưa bao giờ được thêm, nên không truy cập được trên API đã deploy.
- **Cách xử lý:** bước kiểm tra sau-apply của workflow hạ tầng vẫn fail với mọi route lệch, nhưng chấp nhận 10 route chỉ-có-trong-source đã biết để một lần deploy đúng không bị báo lỗi.
- **Bước tiếp theo:** thêm các route vào định nghĩa API. Đây là lý do chính khiến người dùng chưa tự đặt lại mật khẩu được trên app đã deploy.

### 10. Cổng CI/CD lỗi hoặc không chạy được

| Triệu chứng | Nguyên nhân | Cách sửa |
|---|---|---|
| Workflow mới bị từ chối: `'name' is already defined` | Dòng `name:` bị trùng sau khi ghép phần đầu và phần thân | Xoá dòng trùng, diff với bản gốc |
| Workflow chạy tay không hiện trong danh sách | `workflow_dispatch` chỉ hoạt động với workflow nằm trên **nhánh mặc định** (`master`) | Chép hai workflow chạy tay sang `master` giống từng byte |
| Job apply lỗi `AccessDenied` cho `cloudformation:GetTemplate` | Role apply không đọc được template của change set | Thêm đúng action đó, giới hạn trong một stack, kiểm chứng bằng mô phỏng policy |
| Bước kiểm tra sau-apply fail với mọi lần apply đúng | Nó coi 10 route chỉ-có-trong-source đã biết là lỗi | Thêm công tắc tuỳ chọn `-AllowKnownSourceOnly`, chỉ dùng ở bước đó; route lệch vẫn fail |
| Một pull request hiện 104 commit và 1.215 file | Branch được cắt từ đầu local có nhiều commit chưa push | Cắt branch mới từ đầu remote thật và cherry-pick đúng một commit |

### 11. Change set CloudFormation đã cũ

- **Triệu chứng:** một change set cũ không có thay đổi trông như an toàn để apply.
- **Nguyên nhân:** nó mang tên DNS load balancer từ ngày được tạo, mà load balancer đó không còn tồn tại. Bước kiểm tra digest chỉ chứng minh **template** không đổi, không chứng minh giá trị tham số đã gắn vẫn còn mới.
- **Cách sửa:** không apply nó. Tạo plan mới, có giá trị tham số hiện tại, rồi apply cái đó.

### 12. Fitness service không gọi được AI service (còn mở)

- **Triệu chứng:** tạo lộ trình kết thúc bằng bản nháp dự phòng và màn hình báo AI service không khả dụng. Log của Fitness Lambda có `getaddrinfo ENOTFOUND ai-service`.
- **Nguyên nhân:** client mặc định dùng tên máy container `ai-service`, chỉ tồn tại trong mạng Docker local, và Lambda không có thiết lập nào cho địa chỉ AI service.
- **Cách sửa dự kiến:** gọi thẳng AI Lambda, giống cách Fitness service đã gọi auth và user service. AI coach và việc tạo kế hoạch qua SQS không bị ảnh hưởng.

### Ghi chú về công cụ

- **AWS CLI lỗi codec `charmap`** khi in log CloudWatch có tiếng Việt. Ghi output ra file không giúp được; đọc log event qua một script nhỏ chuyển văn bản về ASCII thì được.
- **Git Bash tự đổi tham số** có dấu hai chấm hoặc bắt đầu bằng dấu gạch chéo (ví dụ `branch:path`). Đặt `MSYS_NO_PATHCONV=1` trước các lệnh như vậy.

### Hạn chế đã biết và bước tiếp theo

- Thêm các route còn thiếu vào API Gateway, để đặt lại mật khẩu tự phục vụ và onboarding đối tác chạy được trên app đã deploy.
- Sửa kết nối từ Fitness service tới AI service (vấn đề 12).
- Đưa chat lên HTTPS với tên miền riêng và chứng chỉ riêng.
- Thêm kiểm thử tự động và kiểm tra route parity vào pipeline pull request.
- Đổi mật khẩu của 12 tài khoản seed còn lại trước khi phát hành rộng hơn.
- Tìm hiểu sâu hơn về AI trên AWS với Amazon Bedrock và AgentCore.
