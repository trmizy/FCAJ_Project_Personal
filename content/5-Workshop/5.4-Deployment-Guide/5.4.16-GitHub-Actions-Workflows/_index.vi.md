---
title: "5.4.16 Workflow GitHub Actions"
date: 2026-10-23
weight: 16
chapter: false
pre: " <b> 5.4.16. </b> "
---

Bước này gom sáu workflow GitHub Actions của dự án vào một chỗ, kèm file để tải. [5.4.12](../5.4.12-CICD-Pipeline/) và [5.4.13](../5.4.13-CD-Pipeline-Activation/) cho thấy cách kích hoạt chúng; trang này cho thấy mỗi workflow làm gì và dùng ra sao.

#### 1. Các workflow

| Workflow (tải về) | Kích hoạt | Chạy với danh tính | Làm gì |
|---|---|---|---|
| [pr-validation.yml](../../../../files/workshop-files/pr-validation.yml) | Mọi pull request vào `master` hoặc `aws-deploy` | Không có quyền AWS | Cài đặt, lint, kiểm tra kiểu, unit test từng service, lint IaC, build Docker image chat và test helper PowerShell |
| [dev-build.yml](../../../../files/workshop-files/dev-build.yml) | Push lên `aws-deploy`, hoặc chạy tay | Không có quyền AWS | Build và băm từng Lambda zip đã đổi, lưu làm artifact của workflow |
| [dev-deploy.yml](../../../../files/workshop-files/dev-deploy.yml) | Chạy tay, cần người duyệt | `GyminiDevAppDeployRole` qua OIDC | Deploy code Lambda của các service được chọn từ một bản build, kiểm tra hash artifact trước, rồi smoke check `/health`; mặc định dry run |
| [chat-deploy.yml](../../../../files/workshop-files/chat-deploy.yml) | Chạy tay, cần người duyệt | `GyminiDevAppDeployRole` | Đăng ký revision task definition ECS mới cho Chat service mà không đổi desired count |
| [infra-plan.yml](../../../../files/workshop-files/infra-plan.yml) | Chạy tay | `GyminiDevInfraPlanRole` | Tạo change set CloudFormation cho stack API Gateway, quét nó, công bố digest các thay đổi; không thể thực thi gì |
| [infra-deploy.yml](../../../../files/workshop-files/infra-deploy.yml) | Chạy tay, cần người duyệt | `GyminiDevInfraApplyRole` | Thực thi một change set đã duyệt, chỉ khi digest khớp với bản plan đã in, rồi chạy các kiểm tra chỉ đọc |

{{% notice note %}}
Các bản đính kèm đã thay account ID bằng giá trị giữ chỗ `123456789012`. Hãy thay nó, cùng tên role và tên bucket, bằng giá trị của tài khoản bạn.
{{% /notice %}}

#### 2. An toàn được bảo đảm thế nào

- **Không lưu khoá.** Workflow chạm tới AWS dùng action `aws-actions/configure-aws-credentials` với `role-to-assume`. GitHub cấp token OIDC ngắn hạn, và mỗi IAM role chỉ tin cậy đúng một GitHub environment. Không có access key trong repository hay repository secret.
- **Con người duyệt mọi thay đổi.** Job thay đổi AWS khai báo một `environment` (`dev`, `dev-infra-plan`, `dev-infra`). Mỗi environment yêu cầu người duyệt, tắt quyền bỏ qua của administrator, và chỉ cho deploy từ nhánh `aws-deploy` ([5.4.13](../5.4.13-CD-Pipeline-Activation/)).
- **Plan và apply là hai role khác nhau.** Role plan có deny tường minh việc thực thi change set, nên dù file bị sửa cũng không áp dụng được gì. Role apply thực thi được nhưng không tạo được change set.
- **Thay đổi đã duyệt chính là thay đổi được áp dụng.** Workflow apply nhận digest mà plan đã in và từ chối chạy nếu change set không còn khớp.
- **Mặc định dry run.** Các workflow deploy bắt đầu với `dry_run: true`, nên lần chạy đầu chỉ in ra việc sẽ làm.

#### 3. Dùng một workflow

1. Mở repository trên GitHub, vào **Actions**, chọn workflow ở danh sách bên trái.
2. Bấm **Run workflow**, chọn nhánh `aws-deploy` và điền các input.
3. Với workflow deploy, giữ **dry_run** được tick ở lần chạy đầu và đọc phần tổng kết. Chạy lại với ô đó bỏ tick để deploy thật.
4. Khi job tới bước `environment`, nó hiện **Waiting**. Bấm **Review deployments**, tick environment và bấm **Approve and deploy**.

Các input dùng trong thực tế:

| Workflow | Input | Ví dụ |
|---|---|---|
| `dev-deploy.yml` | `build_run_id` | run ID của lần chạy `dev-build.yml` cần deploy |
| `dev-deploy.yml` | `services` | `auth` |
| `chat-deploy.yml` | `force_on` | bỏ tick, nên Chat service giữ nguyên bật hoặc tắt |
| `infra-deploy.yml` | `change_set_name`, `reviewed_digest` | cả hai do `infra-plan.yml` in ra |

#### 4. Kiểm tra kết quả

Trong **Actions**, mọi job của lần chạy phải màu xanh. Lần chạy deploy kết thúc bằng phần tổng kết liệt kê các service, có phải dry run hay không và kết quả. Sau một lần deploy Lambda thật, `LastModified` của function đổi và smoke check gọi `/health`:

```text
aws lambda get-function-configuration --function-name fitness-assistant-dev-auth --query LastModified
```

#### Các màn hình trên GitHub

1. Mở repository, rồi **Actions**. Chọn một workflow ở danh sách bên trái (1); các lần chạy hiện ở bên phải (2).

![Trang Actions với danh sách workflow và các lần chạy gần nhất](/images/workshop/console/gha-1-workflows.jpg)
*Sáu workflow và các lần chạy gần đây.*

2. Mở một lần chạy. Lần chạy thành công hiện trạng thái **Success** (1), mọi job màu xanh (2) và phần tổng kết job (3) gồm commit, các service, cờ dry-run, kết quả và mã hash code trước đó được giữ làm tham chiếu rollback.

![Một lần chạy DEV Application Deploy thành công cùng phần tổng kết job](/images/workshop/console/gha-2-green-run.jpg)
*Một lần deploy code Lambda thật, kết thúc với Success.*

3. Để bắt đầu một lần deploy, mở workflow và bấm **Run workflow**. Chọn nhánh **aws-deploy** (1), nhập run ID của bản build (2) và các service (3), giữ **dry_run** được tick (4) ở lần chạy đầu. Sau đó bấm **Run workflow** trong form.

![Form Run workflow của workflow deploy](/images/workshop/console/gha-3-run-workflow-form.jpg)
*Các input của workflow deploy.*

4. Cổng phê duyệt là một GitHub environment. Trong **Settings → Environments → dev**, **Required reviewers** được tick với người duyệt (1), administrator không bỏ qua được các quy tắc (2), và chỉ nhánh **aws-deploy** được phép deploy (3).

![Environment dev với người duyệt bắt buộc và quy tắc nhánh](/images/workshop/console/gha-4-environment-dev.jpg)
*Các quy tắc bảo vệ của environment dev.*

#### 5. Yêu cầu cho repository mới

- Các OIDC role từ [5.4.15](../5.4.15-CloudFormation-IaC/) đã tồn tại, với tên GitHub repository đặt trong tham số `GitHubRepository`.
- Ba GitHub environment đã tồn tại, mỗi cái có người duyệt bắt buộc và quy tắc nhánh deploy `aws-deploy`.
- Biến repository `APIGW_ADOPTION_COMPLETE` chỉ đặt là `true` sau khi stack API Gateway đã được xác minh là được quản lý và không có drift.
- Workflow chạy tay cũng phải có trên nhánh mặc định, vì GitHub chỉ dispatch được workflow nằm trên nhánh mặc định.
