---
title: "5.6 Demo"
date: 2026-07-15
weight: 6
chapter: false
pre: " <b> 5.6. </b> "
---

{{% notice info %}}
Ảnh chụp thật từ môi trường DEV (22–23/10/2026) đã có cho **5.6.1 bước 1 (đăng ký, đăng nhập), bước 2 (onboarding, hồ sơ), bước 3 (lộ trình, tập luyện), bước 4 (AI coach), bước 5 (gym và PT), bước 6 (thanh toán qua VNPAY sandbox), bước 7 (chat) và 5.6.2 mục 4 (tài chính admin)**. Các bước còn lại (xử lý rút tiền, quản trị AI) vẫn chưa có ảnh — xem [danh sách kịch bản ảnh cần chụp](#kịch-bản-ảnh-còn-cần-chụp) ở cuối trang. Email trên các ảnh đã được che. **Khung đỏ và số thứ tự trên ảnh chỉ đúng chỗ cần bấm hoặc nhập, theo thứ tự từ 1.**
{{% /notice %}}

#### Điểm truy cập

| Gì | URL |
|---|---|
| Ứng dụng web | `https://d1ub83a48p566t.cloudfront.net` (CloudFront, HTTPS) |
| REST API | `https://id1iz7upbl.execute-api.ap-southeast-1.amazonaws.com` |
| Chat real-time | Cùng địa chỉ CloudFront, đường dẫn `/socket.io/*` (CloudFront chuyển tới Chat ALB; frontend dùng cho Socket.IO) |

#### 5.6.1 Hành trình của thành viên

1. **Đăng ký và đăng nhập** — `/register`, xác minh, rồi `/login` (Auth Lambda, JWT).

   ![Form đăng ký tài khoản, bước 1/2](/images/workshop/demo/demo-register.png)
   *Đăng ký tài khoản — nhập tên, email và mật khẩu (bước 1/2).*

   ![Màn hình nhập mã xác nhận gửi qua email](/images/workshop/demo/demo-verify.png)
   *Bước 2/2 — hệ thống gửi mã xác nhận 6 chữ số qua email; có đếm ngược để gửi lại mã.*

   ![Trang đăng nhập trên địa chỉ CloudFront](/images/workshop/demo/demo-login.png)
   *Trang đăng nhập mở bằng địa chỉ CloudFront (HTTPS).*

   ![Dashboard sau khi đăng nhập](/images/workshop/demo/demo-dashboard.png)
   *Dashboard ngay sau khi đăng nhập — số đo cơ thể, xu hướng cân nặng, kế hoạch đang dùng và AI Insights.*
2. **Onboarding và hồ sơ** — body profile, mục tiêu, ảnh hồ sơ upload thẳng lên S3 bucket private bằng presigned URL (User Lambda).

   ![Onboarding bước 1: trình độ và mục tiêu](/images/workshop/demo/demo-onboarding-1.png)
   *Onboarding bước 1/6 — chọn trình độ tập luyện và mục tiêu chính.*

   ![Onboarding bước 2: lịch tập](/images/workshop/demo/demo-onboarding-2.png)
   *Bước 2/6 — chọn ngày tập trong tuần, thời lượng mỗi buổi và kiểu chia lịch.*

   ![Onboarding bước 3: thiết bị](/images/workshop/demo/demo-onboarding-3.png)
   *Bước 3/6 — chọn nơi tập và thiết bị có thể sử dụng (gợi ý sẵn theo loại phòng tập).*

   ![Onboarding bước 5: chỉ số cơ thể](/images/workshop/demo/demo-onboarding-4.png)
   *Bước 5/6 — tuổi, giới tính, mức độ vận động hằng ngày, chiều cao và cân nặng.*

   ![Onboarding bước 6: xem lại](/images/workshop/demo/demo-onboarding-5.png)
   *Bước 6/6 — xem lại toàn bộ thông tin trước khi hoàn tất.*

   ![Trang Hồ sơ và Mục tiêu](/images/workshop/demo/demo-profile.png)
   *Trang Hồ sơ & Mục tiêu sau onboarding — thông tin cá nhân, mục tiêu tập luyện, mức độ hoạt động.*

   ![Hồ sơ với ảnh đại diện](/images/workshop/demo/demo-profile-avatar.jpg)
   *Hồ sơ sau khi đổi ảnh — ảnh đại diện được tải lên S3 private bằng presigned URL và hiển thị ngay trong trang Hồ sơ.*
3. **Tập luyện** — xem bài tập, tạo hoặc import kế hoạch tập, bắt đầu và hoàn thành một workout; job nhắc lịch quét các workout được lên kế hoạch hôm nay (Fitness Lambda + EventBridge).

   ![Tạo lộ trình cùng Gymini, bước 1](/images/workshop/demo/demo-roadmap-1.png)
   *Tạo lộ trình cùng Gymini — bước 1/4: thông tin cơ bản (cân nặng, chiều cao, tuổi, giới tính, tỷ lệ mỡ ước lượng).*

   ![Tạo lộ trình cùng Gymini, bước 2](/images/workshop/demo/demo-roadmap-2.png)
   *Bước 2/4: mức độ vận động và số ngày tập; hệ thống tính ngay tiêu hao năng lượng (BMR, bước chân, tập kháng lực, TDEE).*

   ![Tạo lộ trình cùng Gymini, bước 3](/images/workshop/demo/demo-roadmap-3.png)
   *Bước 3/4: mục tiêu (tăng cơ), cân nặng mục tiêu, thời gian mong muốn và tỷ lệ mỡ mục tiêu kèm chỉ số FFMI.*

   ![Tạo lộ trình cùng Gymini, bước 4](/images/workshop/demo/demo-roadmap-4.jpg)
   *Bước 4/4: chẩn đoán thể trạng và báo cáo lộ trình (giai đoạn khởi đầu 6 tuần, mức ăn ước tính, FFMI, tỷ lệ mỡ). Khi AI service không khả dụng, hệ thống dùng bản nháp dự phòng và ghi rõ điều đó trên màn hình để người dùng chỉnh sửa thủ công.*

   ![Tạo lộ trình thủ công](/images/workshop/demo/demo-roadmap-manual.jpg)
   *Cách thay thế: tạo lộ trình thủ công — đặt tên, mục tiêu, giai đoạn bắt đầu và thời gian giai đoạn, rồi tạo bản nháp.*

   {{% notice note %}}
   Ảnh chụp thật trên môi trường DEV (23/10/2026) — luồng đầy đủ từ kế hoạch do AI tạo đến hoàn thành một buổi tập:
   {{% /notice %}}

   ![Kế hoạch tập do AI Coach tạo (Nova Pro), lịch tập theo tuần](/images/workshop/demo/01-ai-plan-detail.png)
   *Kế hoạch "Tăng cơ Plan" do AI tạo — 20 tuần, 6 buổi/tuần, có giải thích vì sao AI điều chỉnh kế hoạch.*

   ![Lưu kế hoạch vào lịch tập thật](/images/workshop/demo/02-plan-saved-to-schedule.png)
   *Sau khi xác nhận: đồng bộ 120 buổi tập thật vào lịch, gắn Program ID thật.*

   ![Hộp thoại chọn ngày bắt đầu và các ngày tập trong tuần](/images/workshop/demo/03-save-schedule-dialog.png)
   *Chọn thay thế lịch cũ hay thêm mới, ngày bắt đầu, số tuần áp dụng, ngày tập trong tuần.*

   ![Trang Workout Log tổng quan](/images/workshop/demo/04-workout-log-overview.png)
   *Trang tổng quan tập luyện sau khi đồng bộ — có cảnh báo khi hồ sơ/lịch chưa khớp mục tiêu.*

   ![Lịch tập theo tháng kèm chỉ số cơ thể](/images/workshop/demo/05-workout-calendar-inbody.png)
   *Lịch theo tháng (từng ngày gắn đúng nhóm cơ) và panel chỉ số cơ thể (cân nặng, mỡ, cơ, nước).*

   ![Chi tiết bài tập của một ngày](/images/workshop/demo/06-day-detail-exercises.png)
   *Chi tiết Ngày 5 — 4 bài tập đúng nhóm cơ "Ngực + Lưng nhẹ".*

   ![Màn hình thực hiện bài tập có đồng hồ đếm giờ](/images/workshop/demo/07-exercise-execution-timer.png)
   *Thực hiện bài Tire Flip — đồng hồ đếm giờ nghỉ, theo dõi tiến độ từng set.*

   ![Ghi chép khối lượng tạ và số reps cho một set](/images/workshop/demo/08-set-logging-weight-reps.png)
   *Ghi set thật: khối lượng tạ, cân nặng cơ thể tại thời điểm tập, số reps, loại set, tempo.*

   ![Ghi RPE và RIR kèm giải thích](/images/workshop/demo/09-set-logging-rpe-rir.png)
   *Ghi mức độ gắng sức (RPE) và số reps còn có thể làm (RIR) — có giải thích cách ước lượng ngay trong app.*

   ![Thông báo đã hoàn thành set](/images/workshop/demo/10-set-completed-toast.png)
   *Xác nhận hoàn thành Set 1, chuyển sang Set 2.*

   ![Màn hình chúc mừng hoàn thành buổi tập](/images/workshop/demo/11-workout-session-complete.png)
   *Hoàn thành buổi tập — 4/4 bài tập, trạng thái Hoàn thành.*

   ![Chi tiết ngày tập đã hoàn thành 100%](/images/workshop/demo/12-day-detail-100-percent.png)
   *Ngày 5 sau khi hoàn thành — 100%, đã ghi cảm nhận buổi tập.*
4. **AI coach** — đặt câu hỏi trong AI chat (Bedrock Nova Pro, dựa trên các index tri thức trong OpenSearch), rồi yêu cầu tạo kế hoạch tập hoặc dinh dưỡng và theo dõi nó hoàn tất qua SQS worker (AI HTTP Lambda → SQS → AI Worker).

   ![AI Coach chào và hiển thị chỉ số mới nhất](/images/workshop/demo/demo-coach-1.png)
   *Mở AI Coach — lời chào kèm gợi ý câu hỏi nhanh (phân tích InBody, lập lịch tập, ...).*

   ![AI Coach trả lời lịch tập ngày mai](/images/workshop/demo/demo-coach-2.png)
   *Hỏi "ngày mai tôi tập gì" — AI Coach trả lời từ kế hoạch đã lưu: Thứ Bảy 24/10/2026 là Ngực + Lưng + Core, kèm bảng bài tập và nguồn "Kế hoạch AI đã lưu".*

   ![Đang tạo kế hoạch AI](/images/workshop/demo/demo-ai-plan-processing.jpg)
   *Yêu cầu tạo kế hoạch tập luyện bằng AI — hệ thống báo đã gửi yêu cầu, hiển thị trạng thái PROCESSING và cho phép chuyển trang trong lúc worker xử lý qua SQS.*

   ![Trang Dinh dưỡng hôm nay](/images/workshop/demo/demo-nutrition-page.jpg)
   *Trang Dinh dưỡng — mục tiêu mặc định (2000 kcal, protein 150 g), lời nhắc thiết lập cá nhân hoá và nút Tạo kế hoạch mới.*

   ![AI Plans, tab kế hoạch dinh dưỡng trống](/images/workshop/demo/demo-nutrition-plans-empty.jpg)
   *Kế hoạch AI → Kế hoạch dinh dưỡng — trạng thái trống trước khi tạo kế hoạch.*

   ![Hộp thoại tạo kế hoạch dinh dưỡng AI](/images/workshop/demo/demo-nutrition-create.jpg)
   *Hộp thoại Tạo kế hoạch dinh dưỡng AI — mục tiêu Tăng cơ, 3 bữa/ngày, chế độ High protein, phong cách món Việt Nam (Miền Nam); kế hoạch 7 ngày được tạo trong 2–5 phút.*

   ![AI đang tạo kế hoạch dinh dưỡng](/images/workshop/demo/demo-nutrition-processing.jpg)
   *Thông báo đã bắt đầu tạo kế hoạch (chạy ngầm); trang hiển thị "AI đang tạo kế hoạch dinh dưỡng…" và cho phép rời trang, kết quả hiện khi hoàn tất.*

   ![Kế hoạch dinh dưỡng đã hoàn thành](/images/workshop/demo/demo-nutrition-result.jpg)
   *Kế hoạch hoàn thành (23/10/2026) — Tăng cơ, 2200 kcal/ngày, 3 bữa/ngày; thực đơn Ngày 1 gồm ba bữa với khối lượng và kcal từng món.*

   ![Thực đơn 7 ngày](/images/workshop/demo/demo-nutrition-days.jpg)
   *Thực đơn 7 ngày — mỗi ngày hiển thị tổng kcal và macro (P/C/F), cùng các thao tác Lưu vào Dinh dưỡng, Giải thích và Điều chỉnh.*
5. **Phòng gym và huấn luyện viên** — xem danh sách gym và PT, check-in tại phòng tập bằng mã QR có chữ ký (Gym Lambda).

   ![Danh sách PT](/images/workshop/demo/demo-pt-search.jpg)
   *Tìm PT — danh sách huấn luyện viên đã xác minh, lọc theo mục tiêu, giá từ 250.000 ₫/buổi.*

   ![Hồ sơ của một PT](/images/workshop/demo/demo-pt-detail.jpg)
   *Hồ sơ PT — huy hiệu đã xác minh, hình ảnh, phương pháp huấn luyện, đối tượng và mục tiêu, nút Nhắn tin.*

   ![Danh sách phòng gym](/images/workshop/demo/demo-gym-list.jpg)
   *Tìm phòng gym — danh sách chuỗi và chi nhánh, có ô tìm kiếm và bộ lọc.*

   ![Chi tiết một phòng gym](/images/workshop/demo/demo-gym-detail.jpg)
   *Chi tiết phòng gym — địa chỉ, giới thiệu, tiện ích; các tab Giá gói và Bình luận.*

   ![Mã QR check-in của chủ phòng gym](/images/workshop/demo/demo-gym-owner-qr.jpg)
   *Phía chủ phòng gym (Titan Gym) — mã QR check-in có chữ ký để đặt tại quầy lễ tân, danh sách check-in gần đây, số tiền có thể rút và số tiền đang chờ.*
6. **Thanh toán** — nạp ví hoặc thanh toán hợp đồng PT qua VNPAY sandbox; giao dịch được xác nhận bởi callback của provider và job reconciliation 5 phút (Payment Lambda).

   ![Chọn phương thức thanh toán gói tập](/images/workshop/demo/demo-pay-method.jpg)
   *Thanh toán gói tập phòng gym 350.000 ₫ — chọn VNPay, ZaloPay hoặc MoMo; hợp đồng chỉ được kích hoạt sau khi cổng xác nhận giao dịch thành công.*

   ![Cổng thanh toán VNPAY sandbox](/images/workshop/demo/demo-vnpay-1.jpg)
   *Chuyển sang cổng thanh toán VNPAY (môi trường Test) — chọn phương thức thanh toán.*

   ![Trang quét mã VNPAY QR](/images/workshop/demo/demo-vnpay-2.jpg)
   *Trang VNPAY QR (Test) — số tiền 350.000 VND, mã đơn hàng, mã QR và đồng hồ hết hạn giao dịch.*

   ![Hợp đồng PT chờ thanh toán](/images/workshop/demo/demo-contract-payment-due.jpg)
   *Hợp đồng gói PT 12 buổi 3.600.000 ₫ ở trạng thái Payment Due — chưa có ngày bắt đầu và kết thúc, chờ thanh toán.*

   ![Hợp đồng PT đã kích hoạt](/images/workshop/demo/demo-contract-active.jpg)
   *Cùng hợp đồng sau khi cổng thanh toán xác nhận — trạng thái Active, có ngày bắt đầu 23/10/2026, ngày kết thúc 20/02/2027 và 0/12 buổi.*
7. **Chat** — mở một hội thoại với PT; tin nhắn đến ngay qua Socket.IO (Chat trên ECS Fargate).

   ![Chat phía học viên](/images/workshop/demo/demo-chat-client.jpg)
   *Tài khoản học viên (Tuấn Trần) trao đổi với Professional Trainer qua Chat service.*

   ![Chat phía PT, tin nhắn đầu](/images/workshop/demo/demo-chat-pt-1.jpg)
   *Cùng lúc, tài khoản PT mở chế độ Trainer và thấy tin nhắn của học viên trong danh sách hội thoại.*

   ![Chat phía PT, hội thoại đầy đủ](/images/workshop/demo/demo-chat-pt-2.jpg)
   *Hội thoại hai chiều đầy đủ nhìn từ phía PT — tin nhắn đi và đến qua Socket.IO.*

#### 5.6.2 Hành trình của admin

1. Đăng nhập bằng tài khoản admin.
2. **Người dùng** — xem danh sách, đổi role, khoá và mở lại tài khoản (`/auth/users/*`).
3. **Hồ sơ ứng tuyển PT và hợp đồng** — duyệt hồ sơ ứng tuyển PT và tài liệu kèm theo (User Lambda, S3 private).

   ![Danh sách hồ sơ ứng tuyển PT](/images/workshop/demo/demo-admin-pt-applications.jpg)
   *Admin → Quản lý PT — danh sách hồ sơ ứng tuyển, lọc theo trạng thái (Draft, Approved, ...).*

   ![Duyệt một hồ sơ PT](/images/workshop/demo/demo-admin-pt-review.jpg)
   *Chi tiết một hồ sơ: bio, chuyên môn, lịch làm việc, tài liệu đính kèm (View Documents) và các thao tác Approve, Reject, Need Info, Investigate.*
4. **Thanh toán** — xem giao dịch và yêu cầu rút tiền (`/admin/payments/*`).

   ![Tài chính admin, tổng quan](/images/workshop/demo/demo-admin-finance-overview.jpg)
   *Admin → Tài chính → Tổng quan — tổng thu 2.600.000 ₫, tổng chi 10.000 ₫, biểu đồ thu chi theo ngày.*

   ![Đối soát toàn nền tảng](/images/workshop/demo/demo-admin-reconciliation.jpg)
   *Đối soát toàn nền tảng — trạng thái Cân bằng (chênh lệch 0 ₫), ESCROW và các bên nhận quyền lợi, cùng danh sách mục cần theo dõi.*

   ![Các kiểm tra toàn vẹn ví](/images/workshop/demo/demo-admin-wallet-checks.jpg)
   *Các kiểm tra toàn vẹn: không ví nào âm, mọi ví khớp với sổ cái, tiền tạm giữ của PT theo hợp đồng.*

   ![Nghĩa vụ đã đóng theo nhóm](/images/workshop/demo/demo-admin-obligations.jpg)
   *Nghĩa vụ chưa thanh toán và đã đóng, mỗi trạng thái một nhóm, kèm lý do và trạng thái xác minh chứng từ.*
5. **Quản trị AI** — mở trang tổng quan AI (`/admin/ai/*`), cũng bị rate limit như mọi route AI.

#### Demo chứng minh điều gì

| Bước | Đường đi trên AWS được kiểm chứng |
|---|---|
| Mọi lần tải trang | CloudFront (HTTPS) → S3 |
| Đăng nhập, hồ sơ, tập luyện, gym, thanh toán, admin | API Gateway → Lambda của service → Aurora (private subnet) |
| Câu trả lời và kế hoạch từ AI | API Gateway → AI Lambda → Bedrock (qua NAT) và OpenSearch (qua VPC endpoint), SQS → AI Worker |
| Nhắc lịch, settlement, reconciliation | EventBridge Scheduler → jobs Lambda |
| Chat trực tiếp | Chat ALB → ECS Fargate → Aurora |

Cả AI coach lẫn bất kỳ tính năng nào khác của ứng dụng đều không thay thế được tư vấn y tế.

#### Kịch bản ảnh còn cần chụp

Đã có ảnh cho **5.6.1 bước 1, 2, 3, 4a, 4b, 5a, 5b, 6a, 6b (một phần) và 7** và cho phần tài chính của admin ở trên. Hành trình thành viên đã đủ ảnh. Phần admin dưới đây là tuỳ chọn — mỗi bước nên chụp **ảnh toàn trang (không che bởi DevTools)**, độ phân giải desktop bình thường, sau khi hành động đã thực sự xảy ra trên môi trường DEV thật (không phải local).

**Hành trình admin**

| # | Hành động trên app | Ảnh cần chụp |
|---|---|---|
| A4 | Xử lý 1 yêu cầu rút tiền ở `/admin/payments/*` | Còn thiếu: màn hình xử lý rút tiền (đã có tổng quan, đối soát và kiểm tra ví) |
| A5 | Vào `/admin/ai/*`, xem tổng quan AI | Dashboard AI admin, thử chạm ngưỡng rate limit để chụp luôn thông báo giới hạn nếu có |

Sau khi chụp xong từng nhóm, gửi lại ảnh theo đúng thứ tự trong bảng kèm số thứ tự (#) — sẽ được chèn vào đúng vị trí tương ứng trong 5.6.1/5.6.2 như cách đã làm với bước 3.
