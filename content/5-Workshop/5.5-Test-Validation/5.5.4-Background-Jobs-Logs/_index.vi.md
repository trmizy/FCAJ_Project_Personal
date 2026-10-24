---
title: "5.5.4 Background job, queue và log"
date: 2026-07-15
weight: 4
chapter: false
pre: " <b> 5.5.4. </b> "
---

#### Schedule

Mười ba schedule EventBridge Scheduler invoke các jobs Lambda. Mỗi schedule phải ở trạng thái **Enabled** và dùng đúng scheduler role của service đó.

| Service | Schedule | Tần suất | Target | Payload |
|---|---|---|---|---|
| User | `fitness-assistant-dev-user-session-settlement` | 5 phút | `user-jobs` | `{"job":"session-settlement"}` |
| User | `fitness-assistant-dev-user-session-auto-confirm` | 10 phút | `user-jobs` | `{"job":"session-auto-confirm"}` |
| User | `fitness-assistant-dev-user-reschedule-expiry` | 10 phút | `user-jobs` | `{"job":"reschedule-expiry"}` |
| Fitness | `fitness-assistant-dev-workout-upcoming-reminder` | 30 phút | `fitness-jobs` | `{"job":"workout-upcoming-reminder"}` |
| Fitness | `fitness-assistant-dev-workout-unfinished-reminder` | 30 phút | `fitness-jobs` | `{"job":"workout-unfinished-reminder"}` |
| Gym | `fitness-assistant-dev-gym-membership-payout` | 10 phút | `gym-jobs` | `{"job":"membership-payout-sweep"}` |
| Gym | `fitness-assistant-dev-gym-referral-settlement` | 10 phút | `gym-jobs` | `{"job":"referral-settlement-sweep"}` |
| Payment | `fitness-assistant-dev-payment-reconciliation` | 5 phút | `payment-jobs` | `{"job":"reconciliation"}` |
| AI | `fitness-assistant-dev-ai-autoaccept` | 15 phút | `ai-jobs` | `{"job":"personalized-service-autoaccept-sweep"}` |
| AI | `fitness-assistant-dev-ai-local-evidence` | hằng ngày 02:00 | `ai-jobs` | `{"job":"local-evidence-refresh"}` |
| AI | `fitness-assistant-dev-ai-pubmed` | hằng ngày 02:30 | `ai-jobs` | `{"job":"pubmed-refresh"}` |
| AI | `fitness-assistant-dev-ai-rss` | hằng ngày 03:00 | `ai-jobs` | `{"job":"rss-refresh"}` |
| AI | `fitness-assistant-dev-ai-web` | hằng ngày 03:30 | `ai-jobs` | `{"job":"web-refresh"}` |

**Cách xác nhận schedule thực sự chạy:** mở `/aws/lambda/fitness-assistant-dev-<service>-jobs` trong CloudWatch Logs — phải có lần gọi mới xuất hiện đúng theo tần suất của schedule, kết thúc mà không có `Task timed out` hay lỗi chưa xử lý. Schedule không bao giờ gọi được thường là do role của nó thiếu `lambda:InvokeFunction` trên đúng ARN của function.

#### SQS worker

| Kiểm tra | Mong đợi |
|---|---|
| Queue `fitness-assistant-dev-ai-tasks` | Visibility timeout 600 giây (dài hơn timeout 300 giây của Worker), DLQ `fitness-assistant-dev-ai-tasks-dlq`, maximum receives 2 |
| Trigger trên `fitness-assistant-dev-ai-worker` | SQS trigger **Enabled**, batch size 1, bật *Report batch item failures* |
| Sau một lần tạo kế hoạch (`POST /plans/workout/generate` rồi `GET /plans/job/{id}`) | Job hoàn tất, queue rỗng, DLQ vẫn 0 message |

![Chi tiết queue: đã bật dead-letter queue](/images/workshop/runbook/img191.jpg)

![SQS trigger đã gắn vào AI Worker](/images/workshop/runbook/img194.jpg)

Có message trong DLQ nghĩa là một job đã lỗi hai lần: đọc log của Worker cho message đó trước khi redrive.

#### CloudWatch Logs

Mỗi Lambda ghi vào `/aws/lambda/<function-name>` và Chat task ghi vào `/ecs/fitness-assistant-dev-chat`; migrator ghi vào `/ecs/fitness-assistant-dev-db-migrator`.

![CloudWatch log group của các function](/images/workshop/runbook/img271.jpg)

| Thông điệp trong log | Ý nghĩa |
|---|---|
| `PrismaClientInitializationError`, `P1001`, `Can't reach database` | Đường mạng tới Aurora (subnet, security group) hoặc credential cũ |
| `AccessDeniedException` | Role thiếu một quyền cụ thể (secret, invoke, Bedrock, `aoss:APIAccessAll`, SQS) |
| `403` từ OpenSearch | Thiếu quyền IAM hoặc data access policy — cần cả hai lớp |
| `Task timed out after …` | Việc lẽ ra phải đưa vào hàng đợi (AI) hoặc timeout của function đặt quá thấp |

{{% notice note %}}
Các CloudWatch alarm đã theo dõi các Lambda API, API Gateway 5xx, Aurora và NAT Gateway (xem [5.5.6](../5.5.6-Monitoring-Alerting/)). Alarm cho worker, các job, throttle và độ sâu DLQ vẫn còn mở, nên các kiểm tra đó vẫn làm thủ công.
{{% /notice %}}
