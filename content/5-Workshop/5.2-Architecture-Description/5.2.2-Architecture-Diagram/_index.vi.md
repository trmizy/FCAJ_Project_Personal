---
title: "5.2.2 Sơ đồ kiến trúc"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 5.2.2. </b> "
---

Sơ đồ dưới đây là ảnh kiến trúc được cung cấp cho dự án. Khác với các bản trước của trang này, mọi node ở đây đều đã được đối chiếu trực tiếp với trạng thái AWS thật (không chép lại từ bản nháp cũ) — [5.4 Hướng dẫn triển khai](../../5.4-Deployment-Guide/) và [5.5.5 Trạng thái kiểm thử và việc còn mở](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) có đầy đủ bằng chứng từng bước đằng sau mỗi khẳng định, còn [5.2.1](../5.2.1-Architecture-Overview/) nói về cách quá trình triển khai đi đến trạng thái hiện tại.

{{% notice note %}}
2 chỗ sửa khi rà soát lại trang này ngày 21/10/2026, đối chiếu trực tiếp với AWS thật, không suy đoán:
- **API Gateway là HTTP API, không phải REST API** — dự án này dùng `apigatewayv2`, đã xác nhận qua mọi lệnh route/CORS/stage gọi tới nó xuyên suốt dự án. Bản trước của sơ đồ này ghi "REST API" — sai.
- **Aurora Serverless v2 reader replica đã được triển khai thật**, không còn là mục "đã thiết kế nhưng chưa xây" nữa: `aws rds describe-db-clusters` liệt kê 2 cluster member thật (`fitness-assistant-dev-aurora-instance-1`, writer; `fitness-assistant-dev-aurora-instance-2`, reader, `PromotionTier: 1`), xác nhận lại trực tiếp đúng ngày viết ghi chú này.
{{% /notice %}}

### Sơ đồ thành phần

![Kiến trúc AWS serverless của Fitness Assistant](/images/workshop/architecture/architecture.png)

{{% notice note %}}
Mọi thành phần trong sơ đồ thành phần, ngoại trừ nhóm Edge và DevOps, đều chạy trong một VPC trải trên nhiều Availability Zone. Chat service là ngoại lệ duy nhất có chủ đích của "không EC2 instance hay container nào trong thiết kế này": đây là traffic WebSocket có trạng thái (stateful), không hợp với mô hình request/response của Lambda, nên chạy dưới dạng ECS Fargate task sau Application Load Balancer riêng — cả hai đều on-demand (bật/tắt theo phiên làm việc cùng NAT Gateway và VPC endpoint của OpenSearch/Secrets Manager, qua `dev-start.ps1`/`dev-stop.ps1`), không chạy thường trực.

Thành phần AI là mô hình 2 nhà cung cấp, không phải 1 LLM duy nhất: **Ollama chạy model Qwen3-4B self-hosted là mặc định cho việc local/dev** (không tốn phí theo token, không phụ thuộc AWS), còn **Lambda thật đã deploy trên AWS gọi Amazon Bedrock's Nova Pro** — không qua quota Bedrock của chính tài khoản DEV (đang ở mức 0 cấp tài khoản và không tự nâng được), mà qua một IAM role cross-account riêng ở một tài khoản AWS khác, assume qua STS cho mỗi lần gọi Bedrock. Việc này đã được chạy thật, không chỉ cấu hình suông: CloudWatch cho thấy 1 dòng log `llm_call` thành công với `provider":"bedrock"` và phản hồi thật từ `apac.amazon.nova-pro-v1:0`.

Về infrastructure-as-code: **CloudFormation, không phải Terraform, mới là thứ thật sự tạo và quản lý hạ tầng AWS thật của dự án này** (API Gateway, các IAM role CI/CD OIDC, stack mạng on-demand, CDN frontend, monitoring) — xác nhận bằng cách liệt kê mọi stack `CREATE_COMPLETE`/`UPDATE_COMPLETE` đang sống trong tài khoản. Repo có chứa 1 module Terraform, nhưng nó chỉ nối với 1 API "hello world" bootstrap riêng biệt, không liên quan, không có `.tfstate` sống nào cho môi trường này — không phải con đường IaC thật của dự án, dù có mặt trong codebase.

[5.5.5](../../5.5-Test-Validation/5.5.5-Status-Open-Items/) là trang để xem đầy đủ, chi tiết từng mục trạng thái xây dựng/xác nhận của mọi thành phần ở đây.
{{% /notice %}}
