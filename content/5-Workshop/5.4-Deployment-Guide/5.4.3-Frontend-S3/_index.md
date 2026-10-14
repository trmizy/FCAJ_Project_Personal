---
title: "5.4.3 Frontend on Amazon S3"
date: 2026-07-15
weight: 3
chapter: false
pre: " <b> 5.4.3. </b> "
---

The React (Vite) frontend is a static build, so it is served straight from an S3 website endpoint: `http://fitness-assistant-frontend-dev-<account-id>.s3-website-ap-southeast-1.amazonaws.com`.

{{% notice warning %}}
This is a temporary DEV setup because Amazon CloudFront was not usable in this account at the time. The bucket is made publicly **readable** (objects only) so the website endpoint can serve it. Once CloudFront is available, the bucket goes back to private behind an Origin Access Control and the site moves to HTTPS.
{{% /notice %}}

#### Step 1 — Enable static website hosting

**S3 → Buckets → `fitness-assistant-frontend-dev-<account-id>` → Properties → Static website hosting → Edit**:

| Setting | Value |
|---|---|
| Static website hosting | Enable |
| Hosting type | Host a static website |
| Index document | `index.html` |
| Error document | `index.html` |

Using `index.html` as the error document matters: the frontend uses React Router (`createBrowserRouter`), so refreshing `/login`, `/register` or `/client/dashboard` must return the app instead of an S3 404.

![Static website hosting enabled with index.html as index and error document](/images/workshop/runbook/img013.jpg)

#### Step 2 — Allow public reads for this bucket only

**Permissions → Block public access (bucket settings) → Edit**, untick **Block all public access**, and confirm the warning.

![Block public access turned off for the frontend bucket](/images/workshop/runbook/img014.jpg)

Then **Bucket policy → Edit** with a policy that allows nothing but `s3:GetObject` on this bucket's objects:

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

![Bucket policy allowing public s3:GetObject only](/images/workshop/runbook/img015.jpg)

The public can `GET index.html` and `assets/*`; it cannot `PutObject`, `DeleteObject` or `ListBucket`.

#### Step 3 — Upload the build

Upload the contents of `frontend/web/dist/` (`index.html` and `assets/`).

![Upload of the frontend build (7 files, 14.8 MB) succeeded](/images/workshop/runbook/img016.jpg)

**Verification:** `/login` loads directly from the website endpoint, which confirms the React build, S3 static hosting and the SPA fallback. API calls from the page only work after the CORS step in [5.4.2](../5.4.2-Auth-Service-API-Gateway/#cors).

#### Redeploy procedure {#redeploy}

Used every time a backend endpoint the frontend depends on changes — for example after the Chat ALB was created in [5.4.10](../5.4.10-Chat-Service-ECS/). Run from `frontend/web`:

**1. Build and check that the bundle points at the right backends.**

```powershell
npm run build
Select-String -Path ".\dist\assets\*.js" -Pattern "<api-id>.execute-api.ap-southeast-1.amazonaws.com"
Select-String -Path ".\dist\assets\*.js" -Pattern "fitness-assistant-dev-chat-alb"
```

Both searches must return at least one match.

![The built bundle contains the API Gateway URL](/images/workshop/runbook/img334.jpg)

**2. Back up the current site before overwriting it.**

```powershell
$backup = "..\..\backups\frontend-s3-before-chat-20260922"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
aws s3 sync s3://fitness-assistant-frontend-dev-<account-id> $backup
Get-ChildItem $backup
```

![Backup of the live frontend (index.html, assets, bg-gym.jpg)](/images/workshop/runbook/img335.jpg)

**3. Publish the new build and stop browsers from caching the old `index.html`.**

```powershell
aws s3 sync .\dist s3://fitness-assistant-frontend-dev-<account-id> --delete
aws s3 cp .\dist\index.html s3://fitness-assistant-frontend-dev-<account-id>/index.html `
  --content-type "text/html" `
  --cache-control "no-cache, no-store, must-revalidate"
```

`--delete` removes old hashed bundles that are no longer in `dist/`; the backup makes that safe to roll back. Finish with a hard refresh (`Ctrl + Shift + R`) on the website endpoint.
