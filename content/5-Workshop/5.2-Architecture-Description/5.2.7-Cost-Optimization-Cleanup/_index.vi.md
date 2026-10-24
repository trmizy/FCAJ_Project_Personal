---
title: "Tối ưu chi phí và dọn dẹp"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.2.7. </b> "
---

### Ước tính chi phí bằng AWS Pricing Calculator

Chi phí hàng tháng của môi trường DEV được ước tính bằng **AWS Pricing Calculator** cho Region Singapore (`ap-southeast-1`), giả định mọi thứ chạy 24×7. Bản ước tính được chia sẻ ở đây: [Gymini DEV ap-southeast-1 estimate](https://calculator.aws/#/estimate?id=0ad0dd36cae8f89d2b9a5dbf13cea7af8e8ee21b) (calculator giữ link chia sẻ trong một năm).

![Các dịch vụ trong bản ước tính cùng chi phí hàng tháng](/images/workshop/console/calc-3-services-table.jpg)
*Bản ước tính liệt kê năm dịch vụ cùng chi phí hàng tháng.*

| Dịch vụ | Cấu hình đã dùng | Chi phí hàng tháng (USD) |
|---|---|---|
| Amazon Aurora PostgreSQL Serverless v2 | Writer và Reader ở mức sàn 0,5 ACU (tổng 1 ACU), 730 giờ, 10 GB lưu trữ | 75,28 |
| AWS PrivateLink (interface VPC endpoint) | 2 endpoint (Secrets Manager, OpenSearch) ở 2 Availability Zone, 10 GB mỗi tháng | 38,06 |
| AWS Fargate (Chat service) | 1 task chạy 24 giờ mỗi ngày, 0,5 vCPU, 1 GB bộ nhớ, 20 GB ephemeral storage | 22,50 |
| Elastic Load Balancing | 1 Application Load Balancer, lưu lượng nhẹ | 18,98 |
| AWS Secrets Manager | 9 secret, 100.000 lần gọi API mỗi tháng | 4,10 |
| **Tổng của bản ước tính** | | **158,92 mỗi tháng (1.907,04 cho 12 tháng)** |

**Không có trong bản ước tính được chia sẻ, tính riêng:**

- **NAT Gateway**: calculator bắt buộc thêm mục "Regional NAT Gateway" bên cạnh mục NAT thường, làm chi phí bị tính dư, nên mục này được bỏ ra. Một gateway trong 730 giờ cộng 20 GB dữ liệu vào khoảng **44 USD mỗi tháng** (calculator cho 44,25 USD với cấu hình đó khi form còn mở, trước khi bị bỏ). Cộng vào, tổng chạy liên tục khoảng **203 USD mỗi tháng**, nằm trong khoảng 190–230 USD của proposal.
- **Các mục tính theo mức dùng, với khối lượng DEV rất nhỏ**: Lambda, API Gateway, S3, CloudWatch, SQS, EventBridge, OpenSearch Serverless (về 0 khi rảnh) và Amazon Bedrock (tính theo token).

**Cách đọc con số.** Đây là chi phí khi để mọi thứ bật trọn một tháng. Quy trình ngủ ([5.7](../../5.7-Cleanup/#pause)) xoá NAT Gateway, dừng Aurora và đưa Chat service về 0 ngoài các buổi kiểm thử, nên chi tiêu thực tế chỉ là một phần nhỏ của con số này.

#### Cách dựng bản ước tính

1. Mở calculator, bấm **Add service**, giữ **Search by location type**, chọn Region **Asia Pacific (Singapore)** và gõ tên dịch vụ ở **Find Service**.

![Trang Add service với Region và ô tìm dịch vụ được đánh dấu](/images/workshop/console/calc-1-add-service.jpg)
*Bước 1: chọn Region (1) và tìm dịch vụ (2).*

2. Bấm **Configure** trên thẻ dịch vụ và điền form. Với Chat service trên Fargate: **Number of tasks** 1 per day (1), **Average duration** 1 day (2), **Amount of vCPU** 0.5 (3), **Amount of memory** 1 GB. Sau đó bấm **Save and add service**.

![Form Fargate với số task, thời lượng và vCPU được đánh dấu](/images/workshop/console/calc-2-fargate-form.jpg)
*Bước 2: form Fargate (hiện giá trị mặc định trước khi được đổi).*

3. Lặp lại cho Aurora PostgreSQL (chọn bản **Serverless**, 1 ACU, 10 GB), form VPC với **AWS PrivateLink** (2 endpoint, 2 Availability Zone), Elastic Load Balancing (1 Application Load Balancer, một ít dữ liệu xử lý) và Secrets Manager (9 secret).
4. Mở trang tổng kết. Bấm **Edit** cạnh tên để đổi tên bản ước tính, rồi bấm **Share** (2) và **Agree and continue**. Dùng **Add service** (1) để thêm dịch vụ bất cứ lúc nào.

![Trang tổng kết với Add service, Share và tổng chi phí](/images/workshop/console/calc-4-summary.jpg)
*Bước 4: trang tổng kết cho thấy 158,92 USD mỗi tháng.*

5. Calculator lưu bản ước tính trên máy chủ công khai của AWS và hiện một link công khai. Bấm **Copy public link** (1) để sao chép. Ai có link đều mở được bản ước tính.

![Hộp thoại Save estimate với link chia sẻ công khai và nút Copy public link](/images/workshop/console/calc-5-share.jpg)
*Bước 5: link chia sẻ của bản ước tính.*

### Đòn bẩy chi phí đang dùng

- **Lambda cho sáu trong bảy service** — trả tiền theo lần gọi thay vì một instance chạy cả ngày; lưu lượng DEV và các job theo lịch phần lớn nằm trong free tier của Lambda.
- **Aurora Serverless v2 với floor thấp** — 0.5 ACU khi đang deploy các service (tránh auto-pause làm nhiễu smoke test), thiết kế để về 0 ACU khi môi trường idle.
- **Một cluster Aurora với bảy logical database** thay vì bảy cluster.
- **OpenSearch Serverless NextGen ở 0–2 OCU** — scale về 0 khi idle thay vì mức tối đa mặc định 96 OCU.
- **Bedrock theo nhu cầu** — không tốn chi phí host model; throttling theo route cho các route AI ngăn client hoặc bug frontend tạo lượng token mất kiểm soát.
- **CloudFront và S3 cho frontend** — chi phí gần như bằng 0 cho một bản build không đổi lúc request, có cache và HTTPS.
- **Một NAT Gateway** cho cả VPC DEV thay vì mỗi Availability Zone một cái.
- **Fargate task đúng kích thước** — 0.5 vCPU / 1 GB cho Chat Service; task migrator (1 vCPU / 2 GB) chỉ tồn tại khi đang chạy.
- **Interface VPC endpoint** cho Secrets Manager và OpenSearch giữ traffic đó khỏi phí xử lý theo GB của NAT Gateway.

### Chi phí cố định nằm ở đâu

Khi gần như mọi thứ tính theo mức dùng, các khoản tính theo giờ vẫn chạy kể cả khi không ai dùng là **NAT Gateway**, **Chat ALB**, **Fargate task**, **capacity tối thiểu của Aurora**, **interface VPC endpoint** và **địa chỉ IPv4 public** (Elastic IP của NAT và các địa chỉ của ALB). [Phần ngân sách trong Proposal](../../../2-Proposal/#budget) ước tính các khoản này; chúng là mục tiêu của chế độ "sleep" bên dưới.

### Tạm dừng giữa các phiên

- **Chế độ sleep cho DEV** — Aurora về 0 ACU, Chat service về 0 task ngoài giờ, và xoá NAT Gateway giữa các phiên kiểm thử (xem [5.7](../../5.7-Cleanup/#pause)).

### Dọn dẹp

Quy trình xoá toàn bộ resource của kiến trúc này theo đúng thứ tự phụ thuộc nằm ở [5.7 Dọn dẹp tài nguyên](../../5.7-Cleanup/).
