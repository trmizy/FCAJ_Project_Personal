---
title: "5.4.15 Hạ tầng dưới dạng code với CloudFormation"
date: 2026-10-23
weight: 15
chapter: false
pre: " <b> 5.4.15. </b> "
---

Phần lớn tài nguyên ở các bước trước lúc đầu được tạo tay trong console để giải thích được từng cấu hình. Những phần dễ mô tả nhưng rủi ro nếu bấm lại cũng được lưu thành **template CloudFormation**, để dựng lại, xem xét và thay đổi qua change set. Bước này liệt kê các stack, file để tải và cách deploy một stack.

#### 1. Các stack và file đính kèm

| Stack trong tài khoản | Template (tải về) | Tạo ra gì |
|---|---|---|
| `fitness-assistant-dev-app-monitoring` | [app-monitoring.yaml](../../../../files/cloudformation/app-monitoring.yaml) | 9 CloudWatch alarm và SNS topic `fitness-assistant-dev-app-alerts` ([5.5.6](../../5.5-Test-Validation/5.5.6-Monitoring-Alerting/)) |
| `fitness-assistant-dev-frontend-cdn` | [frontend-cdn.yaml](../../../../files/cloudformation/frontend-cdn.yaml) | CloudFront distribution và Origin Access Control cho bucket frontend |
| `gymini-dev-on-demand` | [dev-on-demand.yaml](../../../../files/cloudformation/dev-on-demand.yaml) | Các phần tính tiền theo giờ, bật tắt theo từng phiên: NAT Gateway, load balancer của Chat, listener, target group và VPC endpoint |
| `fitness-assistant-dev-cicd-iam` | [ci-cd-oidc.yaml](../../../../files/cloudformation/ci-cd-oidc.yaml) | Năm IAM role đặc quyền tối thiểu mà GitHub Actions assume qua OIDC |
| `fitness-assistant-dev-api-gateway` | do các workflow hạ tầng quản lý | HTTP API với 254 resource (route, integration, stage); quá lớn để đính kèm, chỉ thay đổi qua change set đã duyệt ([5.4.16](../5.4.16-GitHub-Actions-Workflows/)) |

{{% notice note %}}
Các bản đính kèm đã thay account ID và subnet ID bằng giá trị giữ chỗ (`123456789012`, `subnet-0123456789abcdef0`). Hãy thay bằng giá trị của bạn trước khi deploy. Không template nào chứa mật khẩu, khoá hay địa chỉ email.
{{% /notice %}}

#### 2. Template có và không có gì

- **Tham số thay vì giá trị cố định.** Template tham chiếu tài nguyên đã có (VPC, subnet, Aurora cluster, API ID, tên bucket) qua tham số, nên cùng một template dùng được ở tài khoản khác sau khi đổi giá trị.
- **Không có thông tin đăng nhập.** Template giám sát tạo SNS topic nhưng không tạo subscription. Email được đăng ký sau bằng lệnh trong output của stack, nên không địa chỉ nào bị commit.
- **Đặc quyền tối thiểu ngay từ thiết kế.** Trong template OIDC, mỗi role chỉ tin cậy đúng một GitHub environment (`dev`, `dev-infra`, `dev-infra-plan`) và role plan có deny tường minh việc thực thi change set. Không có access key tĩnh, không có quyền administrator.
- **Tách vòng đời.** Stack on-demand chỉ chứa phần tốn tiền khi rảnh. VPC, subnet, Aurora, Lambda và secret nằm ngoài, nên tắt môi trường không đụng tới chúng.

#### 3. Deploy một stack

Ví dụ với template giám sát. Thay các giá trị giữ chỗ, rồi deploy qua change set để xem xét kết quả trước khi áp dụng:

```text
aws cloudformation deploy \
  --region ap-southeast-1 \
  --stack-name fitness-assistant-dev-app-monitoring \
  --template-file app-monitoring.yaml \
  --parameter-overrides ApiId=<your-api-id> AuroraClusterIdentifier=<your-aurora-cluster> \
  --no-execute-changeset
```

Xem change set trong console (**CloudFormation → Stacks → stack → Change sets**), rồi thực thi. Sau khi stack được tạo, đăng ký email của bạn vào topic bằng lệnh ở tab **Outputs** (`SubscribeCommand`) và xác nhận email nhận được.

Template OIDC tạo IAM role có tên cố định, nên cần cờ capability:

```text
aws cloudformation deploy --template-file ci-cd-oidc.yaml --stack-name fitness-assistant-dev-cicd-iam --capabilities CAPABILITY_NAMED_IAM --no-execute-changeset
```

#### 4. Kiểm tra kết quả

Mở **CloudFormation → Stacks**. Mỗi stack phải ở trạng thái `CREATE_COMPLETE` hoặc `UPDATE_COMPLETE`. Mở một stack và xem ba tab: **Resources** (mọi resource ở `CREATE_COMPLETE`), **Outputs** (các ID và ARN mà bước khác dùng) và **Events** (lịch sử sạch, không rollback).

Để so stack đang chạy với template, dùng **Stack actions → Detect drift**. Stack ở trạng thái `IN_SYNC` nghĩa là không có thay đổi nào làm ngoài CloudFormation. Stack API Gateway được kiểm tra như vậy trước mỗi thay đổi hạ tầng ([5.4.13](../5.4.13-CD-Pipeline-Activation/)).

#### Các màn hình trong console

Các màn hình dưới đây được chụp trong tài khoản. Wizard Create stack chỉ được mở để cho thấy bước đầu rồi bấm Cancel, nên không có stack nào được tạo.

1. Mở **CloudFormation → Stacks** và bấm tên stack (1).

![Danh sách stack CloudFormation với stack giám sát được đánh dấu](/images/workshop/console/cfn-1-stack-list.jpg)
*Tài khoản có 5 stack của dự án, đều ở CREATE_COMPLETE hoặc UPDATE_COMPLETE.*

2. Mở tab **Resources** (1). Mọi resource phải hiện **CREATE_COMPLETE** (2).

![Tab Resources của stack giám sát](/images/workshop/console/cfn-2-resources.jpg)
*10 resource của stack giám sát: 9 alarm và SNS topic.*

3. Mở tab **Outputs** (1) để đọc các giá trị mà bước khác dùng, gồm cả lệnh đăng ký email.

![Tab Outputs của stack giám sát](/images/workshop/console/cfn-3-outputs.jpg)
*Outputs của stack giám sát (đã che account ID).*

4. Để tạo stack từ file template, bấm **Create stack** và chọn **With new resources (standard)** (1).

![Menu Create stack với tuỳ chọn standard được đánh dấu](/images/workshop/console/cfn-4-create-menu.jpg)
*Menu Create stack.*

5. Ở bước 1 chọn **Upload a template file** (1), chọn file YAML đã tải ở trên, rồi **Next** (2) qua các bước tham số, tuỳ chọn và xem lại. Ở đây wizard được dừng bằng **Cancel** (3) thay vì tạo stack.

![Bước 1 của wizard Create stack với Upload a template file được chọn](/images/workshop/console/cfn-5-create-wizard.jpg)
*Bước 1 của wizard.*

#### 5. Dọn dẹp

Xoá stack bằng **Delete**, hoặc chạy `aws cloudformation delete-stack --stack-name <name>`. Khi tắt toàn bộ, xoá stack on-demand trước, vì các stack khác không phụ thuộc vào nó. Thứ tự cho cả môi trường nằm ở [5.7](../../5.7-Cleanup/).
