---
title: "5.4.3 Frontend trên Amazon S3"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.4.3. </b> "
---

Frontend React (Vite) là một bản build tĩnh, nên được phục vụ trực tiếp từ S3 website endpoint: `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com`.

{{% notice warning %}}
Đây là cấu hình DEV tạm thời vì lúc đó Amazon CloudFront chưa dùng được trong account. Bucket được cho phép **đọc** công khai (chỉ object) để website endpoint phục vụ được. Khi CloudFront dùng được, bucket sẽ trở về private phía sau Origin Access Control và site chuyển sang HTTPS.
{{% /notice %}}

#### Bước 1 — Bật static website hosting

**S3 → Buckets → `fitness-assistant-frontend-dev-<account-id>` → Properties → Static website hosting → Edit**:

| Thiết lập | Giá trị |
|---|---|
| Static website hosting | Enable |
| Hosting type | Host a static website |
| Index document | `index.html` |
| Error document | `index.html` |

Dùng `index.html` làm error document là rất quan trọng: frontend dùng React Router (`createBrowserRouter`), nên khi refresh `/login`, `/register` hay `/client/dashboard` phải trả về app thay vì lỗi 404 của S3.

![Bật static website hosting với index.html làm index và error document](/images/workshop/runbook/img013.jpg)

#### Bước 2 — Cho phép đọc công khai chỉ với bucket này

**Permissions → Block public access (bucket settings) → Edit**, bỏ chọn **Block all public access** và xác nhận cảnh báo.

![Tắt Block public access cho bucket frontend](/images/workshop/runbook/img014.jpg)

Sau đó **Bucket policy → Edit** với policy chỉ cho phép `s3:GetObject` trên object của bucket này:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::fitness-assistant-frontend-dev-<account-id>/*"
    }
  ]
}
```

![Bucket policy chỉ cho phép s3:GetObject công khai](/images/workshop/runbook/img015.jpg)

Người ngoài có thể `GET index.html` và `assets/*`; không thể `PutObject`, `DeleteObject` hay `ListBucket`.

#### Bước 3 — Upload bản build

Upload nội dung của `frontend/web/dist/` (`index.html` và `assets/`).

![Upload bản build frontend (7 file, 14.8 MB) thành công](/images/workshop/runbook/img016.jpg)

**Verification:** `/login` tải được trực tiếp từ website endpoint, xác nhận bản build React, S3 static hosting và SPA fallback hoạt động. Lời gọi API từ trang chỉ chạy sau bước CORS ở [5.4.2](../5.4.2-Auth-Service-API-Gateway/#cors).

#### Quy trình deploy lại {#redeploy}

Dùng mỗi khi một backend endpoint mà frontend phụ thuộc thay đổi — ví dụ sau khi tạo Chat ALB ở [5.4.10](../5.4.10-Chat-Service-ECS/). Chạy trong `frontend/web`:

**1. Build và kiểm tra bundle trỏ đúng backend.**

```powershell
npm run build
Select-String -Path ".\dist\assets\*.js" -Pattern "<api-id>.execute-api.ap-southeast-1.amazonaws.com"
Select-String -Path ".\dist\assets\*.js" -Pattern "fitness-assistant-dev-chat-alb"
```

Cả hai lệnh tìm kiếm phải trả về ít nhất một kết quả.

![Bundle sau build có chứa URL của API Gateway](/images/workshop/runbook/img334.jpg)

**2. Backup site hiện tại trước khi ghi đè.**

```powershell
$backup = "..\..\backups\frontend-s3-before-chat-20260922"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
aws s3 sync s3://fitness-assistant-frontend-dev-<account-id> $backup
Get-ChildItem $backup
```

![Bản backup của frontend đang chạy (index.html, assets, bg-gym.jpg)](/images/workshop/runbook/img335.jpg)

**3. Publish bản build mới và không cho trình duyệt cache `index.html` cũ.**

```powershell
aws s3 sync .\dist s3://fitness-assistant-frontend-dev-<account-id> --delete
aws s3 cp .\dist\index.html s3://fitness-assistant-frontend-dev-<account-id>/index.html `
  --content-type "text/html" `
  --cache-control "no-cache, no-store, must-revalidate"
```

`--delete` xoá các bundle có hash cũ không còn trong `dist/`; bản backup giúp rollback an toàn. Cuối cùng hard refresh (`Ctrl + Shift + R`) trên website endpoint.
