---
title: "5.4.12 Kích hoạt pipeline CI/CD"
date: 2026-10-16
weight: 12
chapter: false
pre: " <b> 5.4.12. </b> "
---

Tài khoản DEV đã có sẵn 5 role GitHub OIDC least-privilege (`GyminiDevCiReadRole`, `GyminiDevAppDeployRole`, `GyminiDevInfraPlanRole`, `GyminiDevInfraApplyRole`, `GyminiDevCfnExecutionRole`) được tạo bằng CloudFormation từ trước — không có static AWS key nào. Bước này kích hoạt workflow GitHub Actions thật đầu tiên: **chỉ kiểm tra PR** (install/lint/typecheck/unit test/lint IaC/build Docker + các bộ test PowerShell CI-helper của repo), cộng một job tạm thời, phạm vi hẹp, chứng minh liên kết OIDC → STS → `GyminiDevCiReadRole` hoạt động trước khi gỡ nó. Không deploy ứng dụng, không deploy hạ tầng, và không thay đổi AWS nào ngoài một lệnh gọi chỉ đọc trong bước này.

#### Bước 1 — Push branch kích hoạt

Workflow vĩnh viễn (`.github/workflows/pr-validation.yml`, hoàn toàn không có quyền AWS: không `id-token`, không assume role, không static key, không lệnh deploy) và workflow OIDC smoke tạm thời (`.github/workflows/pr-validation-oidc-smoke.yml`, gỡ lại trước khi merge) được commit trên một branch riêng, tạo từ đầu thật của `origin/aws-deploy`, rồi push:

```powershell
git push -u origin <activation-branch>
```

![git push thành công, branch kích hoạt được tạo trên origin](/images/workshop/runbook/img359.png)

#### Bước 2 — Mở pull request

Base `aws-deploy`, compare branch kích hoạt, title `CI: activate PR validation`.

![Form tạo pull request đã điền đầy đủ: title và description](/images/workshop/runbook/img360.png)

So sánh với `aws-deploy` thật cho đúng phạm vi mong muốn: `ahead_by: 1, behind_by: 0, files changed: 26`.

![So sánh PR: 1 commit, 26 file thay đổi so với aws-deploy thật](/images/workshop/runbook/img362.png)

#### Bước 3 — Bằng chứng OIDC smoke

Xác nhận qua GitHub Actions API trên branch kích hoạt: job `oidc-smoke` hoàn tất với `conclusion: success` từ đầu đến cuối. Điều này chứng minh liên kết GitHub OIDC → STS → `GyminiDevCiReadRole` (`AssumeRoleWithWebIdentity`) được nối đúng.

| Check | Kết quả |
|---|---|
| `impact` | success |
| `chat-image` | success |
| `oidc-smoke` | **success** |

#### Bước 4 — Gỡ workflow OIDC tạm thời

`.github/workflows/pr-validation-oidc-smoke.yml` được gỡ bằng một plumbing commit (`git read-tree` / `update-index --force-remove` / `write-tree` / `commit-tree`, không checkout working tree — cây của branch chứa các đường dẫn fixture đánh giá AI lồng sâu vượt `MAX_PATH` của Windows, nên plumbing chỉ thao tác trên object database).

#### Bước 5 — Lần chạy kiểm tra cuối

Mọi check thật đều qua trên commit dọn dẹp: `unit` (fitness/auth/payment/user/ai/gym), `quality`, `ci-helper-tests`, `chat-image`, `fast-docker-test`, `Critical DB Integration Tests` — đều `success`; `iac` được `skipped` đúng (không có file hạ tầng nào đổi trong commit đó).

#### Bước 6 — Merge

Merge vào `aws-deploy` bằng fast-forward push (đầu `aws-deploy` là tổ tiên trực tiếp của đầu branch kích hoạt, nên không cần merge commit): `003545c6..aba97ce7`. `pr-validation.yml` và các cập nhật `docker-test.yml` giờ đã nằm trên `aws-deploy`; `pr-validation-oidc-smoke.yml` đã được gỡ, đúng như dự định.

#### Kết quả

- Branch kích hoạt được push từ đầu thật của `aws-deploy` và pull request mở với đúng phạm vi mong muốn (1 commit, 26 file).
- Liên kết GitHub OIDC → STS → `GyminiDevCiReadRole` được chứng minh hoạt động (`oidc-smoke: success`) — mục tiêu bảo mật cốt lõi của bước này.
- Workflow OIDC smoke tạm thời đã gỡ; lần chạy kiểm tra cuối xanh hoàn toàn; merge vào `aws-deploy` bằng fast-forward sạch.
- Giai đoạn tiếp theo: `dev-deploy`, `chat-deploy`, `infra-plan` và `infra-deploy` được kích hoạt ở [5.4.13](../5.4.13-CD-Pipeline-Activation/).
