---
title: "Tuần 12"
date: 2026-07-15
weight: 12
chapter: false
pre: " <b> 1.12. </b> "
---

{{% notice note %}}
Các mốc thời gian trong trang này là placeholder (`[TODO_DATE]`) cho đến khi có lịch thực tập chính thức.
{{% /notice %}}

### Mục tiêu tuần

- Dọn dẹp toàn bộ tài nguyên AWS đã tạo để thử nghiệm nhằm tránh phát sinh chi phí.
- Thu thập và sắp xếp toàn bộ screenshot/bằng chứng thu thập trong quá trình thực tập.
- Hoàn thiện báo cáo song ngữ, viết phần tự đánh giá và reflection.

### Công việc đã thực hiện

- Thực hiện đúng trình tự clean-up ở [Workshop 5.16](../../5-Workshop/5.16-Cleanup/) theo thứ tự phụ thuộc (container → alarm/SNS → object S3 nếu có → image ECR → RDS → EC2/EIP → networking → IAM/Secrets).
- Thu thập và sắp xếp toàn bộ screenshot vào cấu trúc thư mục `static/images/`, khớp mỗi ảnh với đúng bước workshop mà nó minh họa.
- Rà soát từng trang báo cáo để tìm các đánh dấu `TODO` và xác nhận mục nào còn tồn đọng, mục nào đã giải quyết.
- Hoàn thiện mục [Self-evaluation](../../6-Self-evaluation/) và [Sharing and Feedback](../../7-Feedback/).
- Rà soát kiến trúc cuối cùng so với những gì thực sự đã triển khai, viết [Conclusion](../../5-Workshop/5.17-Conclusion/) so sánh trung thực giữa kế hoạch và kết quả (bao gồm cả những phần chưa hoàn thành).

### Kết quả đạt được

- Tài nguyên AWS đã được dọn dẹp (hoặc có lý do rõ ràng nếu cố tình giữ lại tài nguyên nào đó, ví dụ để chấm điểm/demo).
- Báo cáo song ngữ hoàn chỉnh với đầy đủ các mục.
- TODO: Có người thứ hai (mentor hoặc bạn học) đọc lại lần cuối trước khi nộp.

### Khó khăn

- Một số tài nguyên có ràng buộc phụ thuộc khiến việc xóa sai thứ tự bị chặn (ví dụ Security Group vẫn đang được một ENI tham chiếu, hoặc IAM Role vẫn gắn với instance profile đang sử dụng).

### Cách giải quyết

- Tuân theo checklist clean-up có thứ tự phụ thuộc rõ ràng ở [Workshop 5.16](../../5-Workshop/5.16-Cleanup/) thay vì xóa tùy tiện, và kiểm tra lại console Billing/Resource Explorer sau đó để xác nhận không còn tài nguyên nào chạy ngoài dự kiến.

### Kỹ năng / Dịch vụ AWS đã học

- Kỹ năng gỡ bỏ tài nguyên an toàn, có tính đến phụ thuộc.
- Sử dụng AWS Billing và Resource Explorer để xác minh tài khoản đã sạch sau khi dọn dẹp.

### Bằng chứng cần bổ sung

- TODO: Screenshot Billing dashboard cho thấy không còn tài nguyên chạy ngoài dự kiến sau clean-up.
- TODO: Danh sách cuối cùng các tài nguyên cố tình giữ lại, kèm lý do.

### Bảng theo ngày / task

| Ngày | Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- | --- |
| 1 | Dọn dẹp tài nguyên AWS theo đúng thứ tự phụ thuộc | [TODO_DATE] | [TODO_DATE] | [Workshop 5.16](../../5-Workshop/5.16-Cleanup/) |
| 2 | Sắp xếp screenshot và bằng chứng | [TODO_DATE] | [TODO_DATE] | `static/images/` |
| 3 | Hoàn thiện mục Self-evaluation và Feedback | [TODO_DATE] | [TODO_DATE] | [Self-evaluation](../../6-Self-evaluation/), [Feedback](../../7-Feedback/) |
| 4 | Rà soát cuối cùng và viết Conclusion | [TODO_DATE] | [TODO_DATE] | [Workshop 5.17](../../5-Workshop/5.17-Conclusion/) |

### Checklist hoàn thành

- [ ] Đã dọn dẹp tài nguyên AWS theo đúng thứ tự phụ thuộc
- [ ] Đã kiểm tra Billing dashboard để phát hiện tài nguyên còn sót
- [ ] Đã sắp xếp toàn bộ screenshot và liên kết vào báo cáo
- [ ] Đã hoàn thiện mục Self-evaluation và Feedback
- [ ] Đã viết Conclusion trung thực so với Proposal ban đầu

### Liên kết Workshop tương ứng

- [5.16 Cleanup](../../5-Workshop/5.16-Cleanup/)
- [5.17 Conclusion](../../5-Workshop/5.17-Conclusion/)
