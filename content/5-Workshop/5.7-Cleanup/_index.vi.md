---
title: "Dọn dẹp tài nguyên"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.7. </b> "
---

{{% notice warning %}}
Môi trường DEV vẫn đang được dùng để kiểm thử end-to-end, nên quy trình xoá này **chưa** được chạy. Trang liệt kê mọi resource đã tạo ở [5.4](../5.4-Deployment-Guide/) theo thứ tự tránh lỗi phụ thuộc. Xoá Aurora, S3 bucket và secret là không thể hoàn tác — hãy export những gì cần giữ trước.
{{% /notice %}}

Mọi tên resource đều bắt đầu bằng `fitness-assistant-dev-` (hoặc `fitness-assistant/dev/` với secret), và tất cả nằm ở `ap-southeast-1`. Dùng **Resource Groups & Tag Editor** với prefix đó để kiểm tra lại không còn sót gì.

#### Tạm dừng thay vì xoá {#pause}

Nếu môi trường chỉ idle một thời gian, các bước sau bỏ được phần lớn chi phí mà không mất gì:

| Resource | Thao tác tạm dừng | Tác dụng |
|---|---|---|
| Aurora Serverless v2 | Đặt minimum capacity về **0 ACU** (auto-pause) | Không tính tiền compute khi idle; storage được giữ lại |
| Chat ECS service | Update service → desired tasks **0** | Không tốn phí Fargate |
| NAT Gateway | Xoá và release Elastic IP; tạo lại trước phiên kiểm thử tiếp theo | Bỏ được khoản phí cố định theo giờ lớn nhất; trong thời gian đó Lambda không ra được internet |
| OpenSearch Serverless | Đã tự scale về 0 OCU khi idle (group 0–2 OCU) | Không cần làm gì |

#### Thứ tự xoá toàn bộ

1. **EventBridge Scheduler** — xoá 13 schedule (`fitness-assistant-dev-user-*`, `-workout-*`, `-gym-*`, `-payment-reconciliation`, `-ai-*`), rồi xoá 5 scheduler role.
2. **API Gateway** — xoá HTTP API `fitness-assistant-dev-api` (mọi route, integration, cấu hình CORS và throttling bị xoá theo).
3. **Chat trên ECS**
   1. Update `fitness-assistant-dev-chat-service` về 0 task, rồi xoá service.
   2. Xoá ALB `fitness-assistant-dev-chat-alb`, rồi target group `fitness-assistant-dev-chat-tg`.
   3. Deregister và xoá task definition `fitness-assistant-dev-chat` và `fitness-assistant-dev-db-migrator` (mọi revision).
   4. Xoá cluster `fitness-assistant-dev-cluster`.
4. **Lambda**
   1. Gỡ SQS trigger (event source mapping) khỏi `fitness-assistant-dev-ai-worker` — xoá function không tự xoá event source mapping của nó.
   2. Xoá mọi function: `auth`, `user`, `user-jobs`, `fitness`, `fitness-jobs`, `gym`, `gym-jobs`, `payment`, `payment-jobs`, `ai`, `ai-worker`, `ai-jobs`, và các function `*-migrate` còn lại.
5. **SQS** — xoá `fitness-assistant-dev-ai-tasks` và `fitness-assistant-dev-ai-tasks-dlq`.
6. **OpenSearch Serverless** — xoá collection `fitness-assistant-dev-ai-vectors`, các data access / network / encryption policy của nó, OpenSearch application và workspace, OpenSearch VPC endpoint và collection group `fitness-assistant-dev-ai`.
7. **Aurora** — có thể tạo final snapshot, tắt deletion protection nếu đang bật, xoá instance, rồi xoá cluster `fitness-assistant-dev-aurora`.
8. **Secrets Manager** — xoá mọi secret `fitness-assistant/dev/*` (database secret, `chat-database-url`, `internal-service-secret`). Việc xoá được lên lịch với recovery window 7–30 ngày trừ khi force delete.
9. **ECR** — xoá `fitness-assistant-dev-chat`, `fitness-assistant-dev-db-migrator` và các repository `fitness-assistant/*` từ giai đoạn container trước.
10. **S3** — làm trống rồi xoá: bucket frontend, bucket upload, bucket deployments và bucket data-migration (có versioning: xoá cả mọi version của object).
11. **CloudWatch Logs** — xoá `/aws/lambda/fitness-assistant-dev-*`, `/ecs/fitness-assistant-dev-chat` và `/ecs/fitness-assistant-dev-db-migrator`.
12. **Network**
    1. Xoá NAT Gateway `fitness-assistant-dev-nat-a`, chờ tới *Deleted*, rồi release Elastic IP.
    2. Xoá các interface VPC endpoint (Secrets Manager, OpenSearch).
    3. Xoá security group: `chat-alb-sg`, `chat-sg`, `vpce-sg`, `lambda-sg`, `aurora-sg` (gỡ các tham chiếu chéo trước).
    4. Xoá subnet, route table (`public-rt`, `private-app-rt`, `private-db-rt`), detach và xoá Internet Gateway, rồi xoá `fitness-assistant-dev-vpc`.
13. **IAM** — xoá các role `fitness-assistant-dev-*` (Lambda, ECS task/execution, migrator, scheduler) và inline policy của chúng.
14. **Bedrock** — không có gì để xoá (không có resource được cấp phát); có thể huỷ subscription Marketplace của Cohere.

#### Xác nhận

- **Billing → Bills** và **Cost Explorer** (lọc theo service, region `ap-southeast-1`) không còn phát sinh phí mới cho NAT Gateway, Aurora, Fargate, ALB, OpenSearch hay địa chỉ IPv4 public từ ngày hôm sau.
- **Resource Groups & Tag Editor** với prefix `fitness-assistant-dev` không trả về kết quả nào.
