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

In every screenshot below, the **red rectangles** mark what to fill in or click for the sub-step written just above it.

#### Step 1 — Enable static website hosting

**1.1 — Open the hosting settings.** Open **S3 → Buckets → `fitness-assistant-frontend-dev-<account-id>` → Properties**, scroll to **Static website hosting** and click **Edit**.

**1.2 — Fill in the hosting settings,** then click **Save changes** at the bottom of the page:

| Setting | Value |
|---|---|
| Static website hosting | Enable |
| Hosting type | Host a static website |
| Index document | `index.html` |
| Error document | `index.html` |

![Edit static website hosting: Enable, Host a static website, index document and error document index.html](/images/workshop/runbook/img013.jpg)

Using `index.html` as the error document matters: the frontend uses React Router (`createBrowserRouter`), so refreshing `/login`, `/register` or `/client/dashboard` must return the app instead of an S3 404.

#### Step 2 — Allow public reads for this bucket only

**2.1 — Turn off Block all public access.** Open **Permissions → Block public access (bucket settings) → Edit**, untick **Block all public access**, click **Save changes** and confirm the warning.

![Edit Block public access: Block all public access unticked, Save changes](/images/workshop/runbook/img014.jpg)

**2.2 — Add the bucket policy.** Open **Permissions → Bucket policy → Edit**, paste a policy that allows nothing but `s3:GetObject` on this bucket's objects, then click **Save changes**:

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

![Edit bucket policy: the policy allowing only s3:GetObject](/images/workshop/runbook/img015.jpg)

The public can `GET index.html` and `assets/*`; it cannot `PutObject`, `DeleteObject` or `ListBucket`.

#### Step 3 — Upload the build

**3.1 — Upload the files.** Open the bucket's **Objects** tab, click **Upload**, add the contents of `frontend/web/dist/` (`index.html` and the `assets/` folder), and click **Upload**. When it finishes, the status page reports **Upload succeeded**; click **Close**.

![Upload status: Upload succeeded, 7 files 14.8 MB, Close](/images/workshop/runbook/img016.jpg)

**Verification:** `/login` loads directly from the website endpoint, which confirms the React build, S3 static hosting and the SPA fallback. API calls from the page only work after the CORS step in [5.4.2](../5.4.2-Auth-Service-API-Gateway/#cors).

#### Redeploy procedure {#redeploy}

Used every time a backend endpoint the frontend depends on changes — for example after the Chat ALB was created in [5.4.10](../5.4.10-Chat-Service-ECS/). Run from `frontend/web`:

**1. Build and check that the bundle points at the right backends.**

```powershell
npm run build
Select-String -Path ".\dist\assets\*.js" -Pattern "<api-id>.execute-api.ap-southeast-1.amazonaws.com"
Select-String -Path ".\dist\assets\*.js" -Pattern "fitness-assistant-dev-chat-alb"
```

Both searches must return at least one match. In the screenshot, the first `Select-String` command and the matching part of the bundle are boxed.

![The built bundle contains the API Gateway URL](/images/workshop/runbook/img334.jpg)

**2. Back up the current site before overwriting it.**

```powershell
$backup = "..\..\backups\frontend-s3-before-chat-20260922"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
aws s3 sync s3://fitness-assistant-frontend-dev-<account-id> $backup
Get-ChildItem $backup
```

The last command lists the backup: `assets`, `bg-gym.jpg` and `index.html` must all be there.

![Backup of the live frontend (index.html, assets, bg-gym.jpg)](/images/workshop/runbook/img335.jpg)

**3. Publish the new build and stop browsers from caching the old `index.html`.**

```powershell
aws s3 sync .\dist s3://fitness-assistant-frontend-dev-<account-id> --delete
aws s3 cp .\dist\index.html s3://fitness-assistant-frontend-dev-<account-id>/index.html `
  --content-type "text/html" `
  --cache-control "no-cache, no-store, must-revalidate"
```

`--delete` removes old hashed bundles that are no longer in `dist/`; the backup makes that safe to roll back. Finish with a hard refresh (`Ctrl + Shift + R`) on the website endpoint.
