---
title: "5.10 S3 Storage"
date: 2026-07-15
weight: 10
chapter: false
pre: " <b> 5.10. </b> "
---

{{% notice warning %}}
**Trạng thái: Planned, chưa Implemented.** Source code `fitness-assistant` hiện lưu file người dùng tải lên (ảnh InBody, ảnh hồ sơ, tài liệu đăng ký PT) trên local disk qua `multer`, trong một Docker volume (`user_uploads`) khi phát triển local. Hiện chưa có S3 client (`aws-sdk` / `@aws-sdk/*`) nào trong source code. Toàn bộ nội dung mục này mô tả một tích hợp **dự kiến (planned)**, cần thay đổi code thực sự trong `user-service` trước khi có thể đánh dấu là Implemented.
{{% /notice %}}

### Vì sao mục này tồn tại

Dù S3 chưa được tích hợp vào ứng dụng, việc ghi lại thiết kế dự kiến ở đây giúp khoảng trống này rõ ràng, đồng thời tạo điểm khởi đầu cụ thể để triển khai sau này, thay vì để lưu trữ file như một rủi ro chưa được xử lý.

### Hành vi hiện tại (đã xác minh)

- `backend/services/user-service/src/routes/inbody.routes.ts`, `profile.routes.ts`, và `pt_application.routes.ts` dùng `multer` để ghi file tải lên vào thư mục `uploads/` local.
- Dockerfile production nhúng cứng `mkdir -p uploads/pt-applications` vào image; trên EC2, điều này có nghĩa file tải lên chỉ tồn tại trên filesystem của container (hoặc mount trên host), không phải lưu trữ bền vững, có nhân bản.
- Khi phát triển local, một Docker named volume (`user_uploads`) giữ file qua các lần restart container; trên một EC2 duy nhất, cách tiếp cận tương tự chỉ tồn tại chừng nào host đó còn tồn tại.

### Bucket dự kiến

```bash
aws s3api create-bucket \
  --bucket <YOUR_BUCKET_NAME> \
  --region <YOUR_AWS_REGION>
```

### Block Public Access

```bash
aws s3api put-public-access-block \
  --bucket <YOUR_BUCKET_NAME> \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Encryption

```bash
aws s3api put-bucket-encryption \
  --bucket <YOUR_BUCKET_NAME> \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### Versioning

Khuyến nghị nếu lo ngại việc ghi đè nhầm ảnh InBody hoặc tài liệu PT; sẽ phát sinh thêm chi phí lưu trữ, cần cân nhắc so với ước tính chi phí ở [Proposal](../../2-Proposal/#21-ước-tính-chi-phí).

### CORS (nếu frontend upload trực tiếp)

Chỉ cần thiết nếu frontend được thay đổi để upload trực tiếp lên S3 (ví dụ qua presigned URL) thay vì qua `user-service`. TODO: quyết định và ghi lại luồng upload thực tế trước khi cấu hình CORS.

### IAM Role cho truy cập S3

Xem [`/files/policies/s3-access-policy.example.json`](/files/policies/s3-access-policy.example.json) để có ví dụ policy least-privilege giới hạn ở một ARN bucket cụ thể, để gắn cho identity thực thi của container `user-service` sau khi triển khai.

### Luồng upload / download dự kiến

1. `user-service` nhận file upload qua `multer` (như hiện tại).
2. Thay vì ghi vào local disk, `user-service` sẽ upload buffer lên S3 bằng AWS SDK, sau đó lưu object key của S3 vào database thay vì đường dẫn file local.
3. Download/xem trước sẽ hoặc proxy qua `user-service` hoặc dùng presigned URL — TODO: quyết định khi triển khai thực tế.

### Presigned URL

TODO: chưa được thiết kế. Sẽ áp dụng cho upload trực tiếp từ trình duyệt hoặc link download có giới hạn thời gian, nếu được áp dụng.

### Testing

Không áp dụng — tính năng này chưa tồn tại trong ứng dụng đã triển khai. Không đánh dấu bất kỳ test case liên quan đến S3 nào là `PASS` ở [5.13 Testing and Validation](../5.13-Testing-Validation/).

### Clean-up

Nếu tạo bucket để kiểm thử thiết kế này, xóa toàn bộ object và bucket trong bước [5.16 Cleanup](../5.16-Cleanup/) nếu không có kế hoạch sử dụng tiếp.
