---
title: "5.4.13 Kích hoạt pipeline CD"
date: 2026-10-16
weight: 13
chapter: false
pre: " <b> 5.4.13. </b> "
---

[5.4.12](../5.4.12-CICD-Pipeline/) mới kích hoạt **chỉ CI** (kiểm tra PR, không có AWS credential). Bước này bổ sung phần **CD**: cho GitHub Actions khả năng deploy code và hạ tầng lên tài khoản AWS DEV qua năm workflow có cổng kiểm soát — `dev-build`, `dev-deploy`, `chat-deploy`, `infra-plan`, `infra-deploy`.

#### Bước 1 — Rà soát năm workflow CD

Năm workflow được thiết kế ở giai đoạn lập kế hoạch dưới `ci/drafts/github-actions/`, với cùng kỷ luật an toàn như phần còn lại của dự án:

- `dev-build.yml` — build và băm các file zip Lambda với **không có quyền AWS nào** (không `id-token`, không credential). Tự chạy mỗi lần push lên `aws-deploy`.
- `dev-deploy.yml` — chạy tay (`workflow_dispatch`), mặc định `dry_run: true`, kiểm tra hash artifact với build manifest trước mọi lệnh gọi AWS, chụp trạng thái EventBridge Scheduler trước và sau để bảo đảm không đổi, và quét output mọi lệnh tìm chuỗi giống secret.
- `chat-deploy.yml` — chạy tay; không bao giờ đổi `desiredCount` của ECS service trừ khi truyền `force_on` rõ ràng, nên một lần deploy code không thể vô tình bật hay tắt Chat.
- `infra-plan.yml` — chạy tay; chỉ tạo CloudFormation change set. IAM role của nó (`GyminiDevInfraPlanRole`) có **Deny** rõ ràng với `cloudformation:ExecuteChangeSet`, nên workflow này không thể apply gì.
- `infra-deploy.yml` — chạy tay; quét lại change set được chỉ định và khoá nó bằng SHA-256 digest với đúng thứ `infra-plan.yml` đã in ra, nên change set bị sửa sau khi duyệt không thể được thực thi.

#### Bước 2 — Tạo ba GitHub Environment

Các workflow chạm AWS khai báo `environment: dev` / `dev-infra` / `dev-infra-plan`, cơ chế của GitHub để bắt buộc một người duyệt trước khi job chạy. Ba environment được tạo tay ở GitHub Settings → Environments (cần quyền admin repo).

![Trang Environments trước khi tạo gì — "There are no environments for this repository"](/images/workshop/runbook/img363.png)

![Tạo environment đầu tiên, tên "dev"](/images/workshop/runbook/img364.png)

![Configure dev — Required reviewers, quyền admin bypass và nhánh deploy trước khi cấu hình](/images/workshop/runbook/img365.png)

Với mỗi environment: **Required reviewers** đặt chủ repo làm người duyệt duy nhất; **"Allow administrators to bypass configured protection rules"** bỏ tick, vì chủ repo vừa là admin vừa là người duyệt và bypass sẽ bỏ qua đúng cú click duyệt mà cổng này tồn tại để bắt buộc; **Wait timer** để tắt, vì các workflow chạy tay và đã có cổng người duyệt.

![dev-infra đã cấu hình: trmizy là required reviewer, bỏ tick bypass](/images/workshop/runbook/img366.png)

![dev đã cấu hình và lưu: "only selected branches and tags can deploy"](/images/workshop/runbook/img367.png)

![dev-infra-plan đã cấu hình: cùng người duyệt và cùng cài đặt bypass](/images/workshop/runbook/img368.png)

Xác minh qua API: `total_count: 3`, `["dev", "dev-infra", "dev-infra-plan"]`.

#### Bước 3 — Giới hạn deploy ở nhánh `aws-deploy`

Cùng một quy tắc (`Ref type: Branch`, name pattern `aws-deploy`) được thêm vào cả ba environment.

![Hộp thoại Add deployment branch or tag rule — name pattern "aws-deploy"](/images/workshop/runbook/img369.png)

![Kết quả: "1 branch and 0 tags allowed" — aws-deploy được liệt kê rõ ràng](/images/workshop/runbook/img370.png)

Xác minh qua API (`GET /environments/{name}/deployment-branch-policies`): mỗi environment trả `total_count: 1`, `name: "aws-deploy"`.

#### Bước 4 — Kích hoạt Gate 1 (`dev-build.yml`)

Workflow được commit vào `.github/workflows/` trên `aws-deploy` và kích hoạt ngay khi push, đúng như thiết kế:

| Job | Kết quả |
|---|---|
| `impact` | success |
| `build` | **skipped** — chỉ có file workflow đổi, không có source service Lambda nào |

Không có lệnh gọi AWS nào: workflow không có quyền `id-token` và không bao giờ cấu hình AWS credential.

#### Bước 5 — Kích hoạt Gate 2 và 3 (`dev-deploy.yml`, `chat-deploy.yml`)

Cả hai workflow được commit vào `aws-deploy`, và cả `master`. GitHub yêu cầu một workflow `workflow_dispatch` phải tồn tại trên nhánh mặc định (`master`) của repo thì mới dispatch được, nên hai file được chép sang đó giống hệt từng byte. `dev-build.yml` chỉ ở `aws-deploy`, vì nó kích hoạt bằng `push`. Hai workflow khi đó hiện đúng tên hiển thị, `DEV Application Deploy (Lambda code)` và `DEV Chat Deploy (ECS)`.

#### Bước 6 — Kích hoạt Gate 4 và 5 (`infra-plan.yml`, `infra-deploy.yml`)

Cả hai workflow đã active trên `aws-deploy` và `master`, với các tính năng gia cố sau:

- Một job `gate` không đặc quyền đứng trước cả hai workflow, kiểm tra `github.ref == refs/heads/aws-deploy` và `APIGW_ADOPTION_COMPLETE == true` **trước khi cấu hình bất kỳ AWS credential nào**.
- `TemplateSemanticGuard.psm1` chạy sau `pnpm install`, nên phụ thuộc `js-yaml` luôn có sẵn.
- Việc tạo change set truyền tham số `ChatAlbDnsName` của template đang sống.
- `infra-deploy.yml` kiểm tra template gắn với change set được chỉ định, không phải file trên đĩa.
- `scripts/ci/infra-workflows.test.cjs` chạy logic cổng thật đã ship trong container dùng-một-lần cho ba kịch bản: thiếu adoption, sai nhánh, đúng.

#### Bước 7 — Chứng nhận adoption và drift mới

Trước khi chủ sở hữu set `APIGW_ADOPTION_COMPLETE`, stack API Gateway được kiểm tra trực tiếp với AWS, chỉ đọc:

- `aws cloudformation list-stack-resources`: **254/254** resource ở trạng thái `UPDATE_COMPLETE`.
- Một lệnh `detect-stack-drift` mới: `StackDriftStatus: IN_SYNC`, `DriftedStackResourceCount: 0`.
- `Test-ApiRouteParity.ps1`: 119/119 route sống khớp baseline source, 0 `MISMATCHED`, 0 `GATEWAY_ONLY`.

Sau đó chủ sở hữu set biến repository `APIGW_ADOPTION_COMPLETE=true`.

#### Bước 8 — `dev-deploy.yml` đang chạy

Chủ sở hữu chạy Actions → **DEV Application Deploy (Lambda code)** cho service `auth`.

![Hộp thoại Run workflow: "Use workflow from" = aws-deploy, services = "auth", dry_run được tick](/images/workshop/runbook/img371.png)

1. **Dry run (`dry_run: true`).** Thành công; các bước AWS credential, identity và scheduler-snapshot bị skip theo thiết kế, chỉ in ra kế hoạch.

   ![Kết quả dry run: Success, deploy summary hiện "services: auth | dry_run: true | result: success"](/images/workshop/runbook/img373.png)

2. **Deploy thật (`dry_run: false`).** Cổng người duyệt `environment: dev` yêu cầu chủ sở hữu phê duyệt.

   ![Hộp thoại Review pending deployments — "dev: Review needed from trmizy", nút Approve and deploy](/images/workshop/runbook/img372.png)

3. **Deploy hoàn tất.** Mọi bước, kể cả smoke check `/health` chỉ đọc, đều qua.

   ![Deploy thật: Success, job deploy xanh](/images/workshop/runbook/img374.png)

`aws lambda list-functions` cho thấy `fitness-assistant-dev-auth` có `LastModified` mới khớp với lần chạy, xác nhận code đã được deploy lại.

#### Bước 9 — `infra-plan.yml` và `infra-deploy.yml` đang chạy

1. **Plan.** `infra-plan.yml` chạy trên `aws-deploy` và tạo một change set. `Template semantic diff: NO_SEMANTIC_CHANGE`, `Changes: []`, và change set mang `ChatAlbDnsName` hiện tại của stack đang sống.
2. **Apply.** `infra-deploy.yml` được dispatch với change set đó và chờ cổng người duyệt `dev-infra`. Sau khi được duyệt, nó khoá change set với template đã duyệt, thực thi, rồi chạy các kiểm tra sau-apply chỉ đọc.
3. **Kết quả.** Stack kết thúc ở `UPDATE_COMPLETE`. Một lần chạy `infra-plan.yml` tiếp theo không thấy khác biệt nào, nên stack sống và template khớp nhau.

Role apply `GyminiDevInfraApplyRole` có `cloudformation:GetTemplate`, giới hạn trong ARN của đúng một stack API Gateway như mọi statement khác trong policy. Bước kiểm tra route sau-apply chạy với `-AllowKnownSourceOnly`: nó vẫn fail với mọi route `MISMATCHED`, và coi 10 route `SOURCE_ONLY` đã biết là một mục backlog theo dõi riêng, không phải lỗi thụt lùi của hạ tầng.

#### Bước 10 — Deploy Chat service

`chat-deploy.yml` build và deploy một image chat mới lên ECS Fargate qua cổng người duyệt `dev`, không đổi `desiredCount`. Task definition của chat service hiện ở revision 9.

#### Bước 11 — Cho web app và chat chạy qua HTTPS

Frontend được phục vụ từ CloudFront qua HTTPS, nên hai cài đặt trỏ về nó:

1. **CORS của API Gateway.** `AllowOrigins` liệt kê URL CloudFront (`https://d1ub83a48p566t.cloudfront.net`) cùng với origin S3, đặt bằng một lệnh `update-api --cors-configuration` mang tính cộng thêm. Cả preflight và `POST /auth/login` thật đều mang `access-control-allow-origin: https://d1ub83a48p566t.cloudfront.net`.
2. **Chat qua cùng origin.** Một CloudFront origin (`chat-alb-origin`, `OriginProtocolPolicy: http-only`) và một behavior (`/socket.io/*`, `CachingDisabled` + `AllViewer`) định tuyến traffic Socket.IO tới chat ALB, nên trình duyệt không bao giờ gửi request mixed-content. `runtime-config.json` đặt `chatWsUrl` là domain CloudFront. ECS chat service chạy với `desiredCount: 1`, và target qua health check.

Xác minh: `GET https://d1ub83a48p566t.cloudfront.net/socket.io/?EIO=4&transport=polling` trả `200 OK` kèm handshake Engine.IO thật (`sid`, `upgrades: ["websocket"]`).

#### Bước 12 — Quyền truy cập admin

Một đăng nhập ADMIN dùng được trên app đã deploy được cấp bằng một lần đặt lại mật khẩu có kiểm soát trên Lambda auth:

1. Lambda auth được chuyển tạm sang `NODE_ENV=development` với `SMTP_HOST` rỗng, để request đặt lại mật khẩu trả về liên kết phát triển thay vì gửi email.
2. Việc đặt lại được hoàn tất bằng cách gọi Lambda trực tiếp, vì `/auth/password-reset*` không được expose trên API Gateway.
3. Môi trường gốc của Lambda được khôi phục từ file backup và đọc lại: `NODE_ENV=production`, `SMTP_HOST=smtp.gmail.com`, đủ 10 biến.

Tài khoản đăng ký bằng email thật (`tranminhduy12a1@gmail.com`) được dùng làm đăng nhập ADMIN. Một truy vấn chỉ đọc qua RDS Data API, bật vài phút rồi tắt lại (`HttpEndpointEnabled: False`), xác nhận các dòng ADMIN đang có. Không dữ liệu nào bị sửa. Chủ sở hữu đổi mật khẩu tạm trong app sau lần đăng nhập đầu.

#### Kết quả

- Năm workflow CD đang active: `dev-build`, `dev-deploy`, `chat-deploy`, `infra-plan`, `infra-deploy`.
- Ba GitHub Environment (`dev`, `dev-infra`, `dev-infra-plan`) yêu cầu người duyệt, tắt admin bypass, và chỉ cho deploy từ `aws-deploy`.
- `dev-deploy.yml`, `chat-deploy.yml`, `infra-plan.yml` và `infra-deploy.yml` đều đã chạy trên tài khoản DEV thật qua cổng người duyệt. `dev-build.yml` tự chạy khi push, không có quyền AWS.
- Stack API Gateway khớp với template: 254/254 resource, không drift, 119/119 route khớp baseline.
- Web app đăng nhập được và chat kết nối qua HTTPS bằng CloudFront.
- Có một đăng nhập ADMIN trên app đã deploy.
