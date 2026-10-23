---
title: "Worklog Tuần 9"
date: 2026-07-15
weight: 9
chapter: false
pre: " <b> 1.9. </b> "
draft: false
---

### Mục tiêu tuần 9:

- Nhìn lại quá trình triển khai Gymini lên AWS từ đầu đến giờ và viết thành một case study kỹ thuật
- Tìm hiểu AWS CloudFormation như một cách lấp khoảng trống "chưa có CI/CD" đã được ghi nhận trong Workshop

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Viết Blog 2, "Thách thức triển khai và tối ưu chi phí trên AWS: Bài học thực tế từ dự án Gymini", dưới dạng case study kỹ thuật, và đăng lên AWS Study Group VN Facebook group | 28-9-2026 | 03-10-2026 | [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) <br>[AWS Well-Architected Framework — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html) <br>[Bài đăng trên Facebook](https://www.facebook.com/share/p/19qBt1z5fU/) |

### Kết quả đạt được tuần 9:

**Tổng quan:**

Tuần này dành để nhìn lại quá trình triển khai AWS từ đầu đến giờ, viết thành Blog 2 và chia sẻ với AWS Study Group VN: vì sao triển khai nhiều service không phải việc một ngày, những sự cố gỡ lỗi cụ thể đã ghi trong Workshop (lỗi nhập sai kiểu giá trị secret của Chat service, cơ chế cache secret của Lambda), và vì sao nên cân nhắc AWS CloudFormation khi việc deploy hiện tại hoàn toàn làm tay.

**Kiến thức lý thuyết học được:**

- **Free Tier vs. credit khuyến mãi vs. pay-as-you-go:** ba thứ khác nhau, có credit không có nghĩa hạ tầng miễn phí — nó chỉ trì hoãn thời điểm phải trả tiền thật.
- **Resource tính phí cố định vs. tính theo mức dùng:** phần lớn service của dự án tính tiền theo mức dùng, nhưng vài resource (NAT Gateway, capacity tối thiểu của Aurora, Fargate task của Chat, ALB, VPC endpoint, IPv4 public) tính theo giờ bất kể lưu lượng — đúng với nhóm resource đã được ước tính trong ngân sách của Proposal.
- **AWS CloudFormation:** stack, template, parameter, output, Change Set, drift detection, và quan trọng không kém là những gì nó *không* đảm bảo (giảm chi phí tự động, hay xoá stack là xoá sạch mọi resource).
- **Technical Writing:** cấu trúc một case study tách bạch rõ điều đã xác nhận với điều chỉ là suy luận hợp lý, thay vì trình bày mọi thứ như nhau.

**Hands-on labs đã thực hiện:**

- Viết Blog 2 dưới dạng case study, lấy bằng chứng cụ thể từ các trang Workshop đã có sẵn (5.2.6, 5.2.7, 5.4.10, 5.5.5) thay vì viết lời khuyên chung chung, và đăng lên AWS Study Group VN Facebook group

**Áp dụng vào Fitness Assistant:**

Viết case study này hoá ra lại là một lần tự rà soát trung thực các khoảng trống vận hành của dự án:
- Chưa có pipeline CI/CD — mọi bước deploy ở [5.4](../../5-Workshop/5.4-Deployment-Guide/) đều làm tay qua console
- Chưa có CloudWatch alarm và chưa bật AWS Budgets alert ([5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/), [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/))
- Đã có thứ tự dọn dẹp nhưng chưa chạy thật ([5.7](../../5-Workshop/5.7-Cleanup/))
- CloudFormation (hoặc Terraform đã nhắc tới trong kiến trúc mục tiêu đề xuất) là bước tiếp theo hợp lý một khi dự án không còn deploy thủ công

### Liên kết Workshop tương ứng:

- [3.2 Blog 2](../../3-BlogsPosted/3.2-Blog2/) - Thách thức triển khai và tối ưu chi phí trên AWS
- [5.2.7 Tối ưu chi phí và dọn dẹp](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/) - Các khoản chi phí cố định thật mà case study này dựa vào
