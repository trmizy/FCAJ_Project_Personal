---
title: "CD pipeline activation"
date: 2026-10-16
weight: 13
chapter: false
pre: " <b> 5.4.13. </b> "
---

[5.4.12](../5.4.12-CICD-Pipeline/) activated **CI only** (PR validation, no AWS credentials). This step adds the **CD** half: giving GitHub Actions the ability to deploy code and infrastructure to the DEV AWS account through five gated workflows — `dev-build`, `dev-deploy`, `chat-deploy`, `infra-plan`, `infra-deploy`.

#### Step 1 — Review the five CD workflows

Five workflows were designed in the planning phase under `ci/drafts/github-actions/`, each with the same safety discipline as the rest of this project:

- `dev-build.yml` — builds and hashes the Lambda zips with **zero AWS access** (no `id-token`, no credentials). Runs automatically on every push to `aws-deploy`.
- `dev-deploy.yml` — manual (`workflow_dispatch`), `dry_run: true` by default, verifies artifact hashes against the build manifest before any AWS call, snapshots the EventBridge Scheduler state before and after to guarantee it is unchanged, and scans every command's output for secret-shaped strings.
- `chat-deploy.yml` — manual; never changes the ECS service's `desiredCount` unless `force_on` is explicitly passed, so a code deploy can never power Chat on or off by accident.
- `infra-plan.yml` — manual; creates a CloudFormation change set only. Its IAM role (`GyminiDevInfraPlanRole`) has an explicit **Deny** on `cloudformation:ExecuteChangeSet`, so the workflow cannot apply anything.
- `infra-deploy.yml` — manual; re-scans the named change set and binds it by SHA-256 digest to exactly what `infra-plan.yml` printed, so a change set modified after review cannot be executed.

#### Step 2 — Create the three GitHub Environments

The AWS-touching workflows declare `environment: dev` / `dev-infra` / `dev-infra-plan`, GitHub's mechanism for requiring a human reviewer before a job runs. The three environments are created by hand in GitHub Settings → Environments (this needs repo-admin access).

![Environments page before anything exists — "There are no environments for this repository"](/images/workshop/runbook/img363.png)

![Creating the first environment, named "dev"](/images/workshop/runbook/img364.png)

![Configure dev — Required reviewers, administrator bypass and deployment branches before configuration](/images/workshop/runbook/img365.png)

For each environment: **Required reviewers** is set to the repo owner as the sole reviewer; **"Allow administrators to bypass configured protection rules"** is unchecked, because the owner is both administrator and reviewer and bypass would skip the approval click this gate exists for; **Wait timer** stays off, since the workflows are manual and reviewer-gated.

![dev-infra configured: trmizy added as required reviewer, bypass unchecked](/images/workshop/runbook/img366.png)

![dev configured and saved: "only selected branches and tags can deploy"](/images/workshop/runbook/img367.png)

![dev-infra-plan configured: same reviewer and bypass settings](/images/workshop/runbook/img368.png)

Verified through the API: `total_count: 3`, `["dev", "dev-infra", "dev-infra-plan"]`.

#### Step 3 — Restrict deployment to the `aws-deploy` branch

The same rule (`Ref type: Branch`, name pattern `aws-deploy`) is added to all three environments.

![Add deployment branch or tag rule dialog — name pattern "aws-deploy"](/images/workshop/runbook/img369.png)

![Result: "1 branch and 0 tags allowed" — aws-deploy listed explicitly](/images/workshop/runbook/img370.png)

Verified through the API (`GET /environments/{name}/deployment-branch-policies`): each environment returns `total_count: 1`, `name: "aws-deploy"`.

#### Step 4 — Activate Gate 1 (`dev-build.yml`)

The workflow is committed to `.github/workflows/` on `aws-deploy` and triggers on the push, as designed:

| Job | Result |
|---|---|
| `impact` | success |
| `build` | **skipped** — only a workflow file changed, no Lambda service source |

No AWS calls are made: the workflow has no `id-token` permission and never configures AWS credentials.

#### Step 5 — Activate Gates 2 and 3 (`dev-deploy.yml`, `chat-deploy.yml`)

Both workflows are committed to `aws-deploy`, and also to `master`. GitHub requires a `workflow_dispatch` workflow to exist on the repository's default branch (`master`) before it can be dispatched, so the two files are copied there byte-identical. `dev-build.yml` stays on `aws-deploy` only, because it triggers on `push`. Both workflows then appear under their display names, `DEV Application Deploy (Lambda code)` and `DEV Chat Deploy (ECS)`.

#### Step 6 — Activate Gates 4 and 5 (`infra-plan.yml`, `infra-deploy.yml`)

Both workflows are active on `aws-deploy` and `master`, with these hardening features:

- An unprivileged `gate` job in front of both workflows checks `github.ref == refs/heads/aws-deploy` and `APIGW_ADOPTION_COMPLETE == true` **before any AWS credential is configured**.
- `TemplateSemanticGuard.psm1` runs after `pnpm install`, so its `js-yaml` dependency is present.
- Change-set creation passes the live template's `ChatAlbDnsName` parameter.
- `infra-deploy.yml` validates the template bound to the named change set, not the file on disk.
- `scripts/ci/infra-workflows.test.cjs` runs the shipped gate logic in a disposable container for three scenarios: missing adoption, wrong branch, correct.

#### Step 7 — Fresh adoption and drift certification

Before the owner sets `APIGW_ADOPTION_COMPLETE`, the API Gateway stack is verified directly against AWS, read-only:

- `aws cloudformation list-stack-resources`: **254/254** resources `UPDATE_COMPLETE`.
- A new `detect-stack-drift` call: `StackDriftStatus: IN_SYNC`, `DriftedStackResourceCount: 0`.
- `Test-ApiRouteParity.ps1`: 119/119 live routes match the source baseline, 0 `MISMATCHED`, 0 `GATEWAY_ONLY`.

The owner then sets the repository variable `APIGW_ADOPTION_COMPLETE=true`.

#### Step 8 — `dev-deploy.yml` in use

The owner runs Actions → **DEV Application Deploy (Lambda code)** against the `auth` service.

![Run workflow dialog: "Use workflow from" = aws-deploy, services = "auth", dry_run checked](/images/workshop/runbook/img371.png)

1. **Dry run (`dry_run: true`).** Succeeds; the AWS credential, identity and scheduler-snapshot steps are skipped by design and only the plan is printed.

   ![Dry run result: Success, deploy summary shows "services: auth | dry_run: true | result: success"](/images/workshop/runbook/img373.png)

2. **Real deploy (`dry_run: false`).** The `environment: dev` reviewer gate asks the owner to approve.

   ![Review pending deployments modal — "dev: Review needed from trmizy", Approve and deploy button](/images/workshop/runbook/img372.png)

3. **Deploy completes.** Every step, including the read-only `/health` smoke check, passes.

   ![Real deploy: Success, deploy job green](/images/workshop/runbook/img374.png)

`aws lambda list-functions` shows `fitness-assistant-dev-auth` with a new `LastModified` timestamp matching the run, which confirms the code was redeployed.

#### Step 9 — `infra-plan.yml` and `infra-deploy.yml` in use

1. **Plan.** `infra-plan.yml` runs against `aws-deploy` and creates a change set. `Template semantic diff: NO_SEMANTIC_CHANGE`, `Changes: []`, and the change set carries the live stack's current `ChatAlbDnsName`.
2. **Apply.** `infra-deploy.yml` is dispatched with that change set and waits on the `dev-infra` reviewer gate. After approval, it binds the change set to the reviewed template, executes it, and runs the read-only post-apply checks.
3. **Result.** The stack finishes `UPDATE_COMPLETE`. A follow-up `infra-plan.yml` run finds no differences, so the live stack and the template are in sync.

The apply role `GyminiDevInfraApplyRole` carries `cloudformation:GetTemplate`, scoped to the single API Gateway stack ARN like every other statement in its policy. The post-apply route check runs with `-AllowKnownSourceOnly`: it still fails on any `MISMATCHED` route, and it treats the 10 known `SOURCE_ONLY` routes as a separately tracked backlog item, not an infrastructure regression.

#### Step 10 — Chat service deploy

`chat-deploy.yml` builds and deploys a new chat image to ECS Fargate through the `dev` reviewer gate, without changing `desiredCount`. The chat service's task definition is now at revision 9.

#### Step 11 — Make the live web app and chat work over HTTPS

The frontend is served from CloudFront over HTTPS, so two settings point at it:

1. **API Gateway CORS.** `AllowOrigins` lists the CloudFront URL (`https://d1ub83a48p566t.cloudfront.net`) alongside the S3 origin, set with one additive `update-api --cors-configuration` call. Both the preflight and the real `POST /auth/login` carry `access-control-allow-origin: https://d1ub83a48p566t.cloudfront.net`.
2. **Chat over the same origin.** A CloudFront origin (`chat-alb-origin`, `OriginProtocolPolicy: http-only`) and a behavior (`/socket.io/*`, `CachingDisabled` + `AllViewer`) route Socket.IO traffic to the chat ALB, so the browser never makes a mixed-content request. `runtime-config.json` sets `chatWsUrl` to the CloudFront domain. The ECS chat service runs with `desiredCount: 1`, and the target passes its health check.

Verification: `GET https://d1ub83a48p566t.cloudfront.net/socket.io/?EIO=4&transport=polling` returns `200 OK` with a genuine Engine.IO handshake (`sid`, `upgrades: ["websocket"]`).

#### Step 12 — Admin access

A working ADMIN login is provisioned on the deployed app through a one-time, controlled password reset on the auth Lambda:

1. The auth Lambda is switched briefly to `NODE_ENV=development` with an empty `SMTP_HOST`, so the password-reset request returns its development link instead of sending email.
2. The reset is completed by invoking the Lambda directly, because `/auth/password-reset*` is not exposed on API Gateway.
3. The Lambda's original environment is restored from a backup file and read back: `NODE_ENV=production`, `SMTP_HOST=smtp.gmail.com`, all 10 variables present.

The account registered with the real email address (`tranminhduy12a1@gmail.com`) is used as the ADMIN login. A read-only query through the RDS Data API, enabled for a few minutes and then disabled again (`HttpEndpointEnabled: False`), confirmed which ADMIN rows exist. No data was modified. The owner changes the temporary password in the app after the first login.

#### Result

- Five CD workflows are active: `dev-build`, `dev-deploy`, `chat-deploy`, `infra-plan`, `infra-deploy`.
- Three GitHub Environments (`dev`, `dev-infra`, `dev-infra-plan`) require a human reviewer, have administrator bypass off, and allow deployment from `aws-deploy` only.
- `dev-deploy.yml`, `chat-deploy.yml`, `infra-plan.yml` and `infra-deploy.yml` have each run against the real DEV account through the reviewer gate. `dev-build.yml` runs automatically on push with no AWS access.
- The API Gateway stack is in sync with its template: 254/254 resources, no drift, 119/119 routes matching the baseline.
- The web app signs in and chat connects over HTTPS through CloudFront.
- An ADMIN login is available on the deployed app.
