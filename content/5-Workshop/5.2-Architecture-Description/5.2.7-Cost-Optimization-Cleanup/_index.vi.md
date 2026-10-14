---
title: "5.2.7 Tối ưu chi phí và dọn dẹp"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 5.2.7. </b> "
---

### Đòn bẩy chi phí đang dùng

- **Lambda thay vì EC2 cho sáu trong tám service.** Trả tiền theo lần gọi nghĩa là một môi trường DEV phần lớn thời gian idle không phải trả tiền cho một instance chạy suốt — đúng đánh đổi đã cân nhắc một lần ở [Tuần 8](../../../1-Worklog/1.8-Week8/) khi quyết định có nên self-host model AI trên EC2 hay không.
- **Aurora Serverless v2 với floor ACU thấp.** Cluster hiện giữ ở mức tối thiểu 0.5 ACU thay vì 0, cố ý: để nó tự auto-pause/auto-resume theo mỗi đợt tăng request sẽ làm smoke test lúc đang phát triển bị nhiễu (resume thêm độ trễ, trông giống lỗi nếu không lường trước). Floor này dự kiến giảm về 0 ACU khi giai đoạn phát triển tích cực ổn định lại, giúp chi phí database gần như về 0 trong lúc idle.
- **Một cluster Aurora với bảy logical database**, thay vì bảy cluster riêng — chỉ trả chi phí baseline của một cluster thay vì bảy.
- **S3 static website hosting cho frontend**, thay vì một Lambda, Fargate task, hay EC2 instance phục vụ file tĩnh — chi phí phát sinh gần như bằng 0 cho một build không đổi lúc request.
- **Một NAT Gateway duy nhất** (không phải một cho mỗi Availability Zone) cho traffic outbound của môi trường DEV — một điểm egress duy nhất có chủ đích thay vì trả thêm cho redundancy theo từng AZ mà DEV chưa cần.
- **Fargate task size theo đúng workload, không đoán:** dev sizing 0.5 vCPU / 1 GB của Chat Service được đặt dựa trên nhu cầu thật của một service Socket.IO dưới tải DEV nhẹ, không phải size mặc định/lớn nhất có sẵn.

### Đã lên kế hoạch, chưa triển khai

- **Chiến lược "sleep" cho môi trường DEV** — pause hoặc scale down resource ngoài giờ làm việc (Aurora về 0 ACU, Chat Fargate service về 0 task) là bước tiếp theo rõ ràng, chưa tự động hoá. Tới khi đó, DEV vẫn phát sinh một ít chi phí kể cả khi không ai đang test.
- **CloudFront đứng trước frontend S3** — frontend hiện đang phục vụ trực tiếp qua S3 website endpoint thay vì qua CloudFront với Origin Access Control. Đây vừa là khoảng trống bảo mật/hiệu năng vừa là khoảng trống chi phí (chưa có CDN cache), và bị chặn bởi việc CloudFront chưa dùng được trong môi trường này chứ không phải một quyết định chi phí có chủ đích.

### Dọn dẹp

Project này chưa có trang Workshop clean-up riêng với trình tự teardown đã verify (kế hoạch MVP ban đầu ở [5.16 Cleanup](../../5.16-Cleanup/) mô tả teardown dựa trên EC2 đã lỗi thời, cần viết lại cho đúng các resource serverless liệt kê ở [5.2.1](../5.2.1-Architecture-Overview/) — Lambda, cluster Aurora, service/cluster/ALB của Fargate, API Gateway, bucket S3, và networking VPC). Cho tới khi viết lại xong, coi [5.16 Cleanup](../../5.16-Cleanup/) là mô tả một kiến trúc trước đây, không phải kiến trúc này.
