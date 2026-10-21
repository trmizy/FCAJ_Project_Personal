---
title: "5.4.12 CI/CD pipeline activation"
date: 2026-10-16
weight: 12
chapter: false
pre: " <b> 5.4.12. </b> "
---

The DEV account already had five least-privilege GitHub OIDC roles (`GyminiDevCiReadRole`, `GyminiDevAppDeployRole`, `GyminiDevInfraPlanRole`, `GyminiDevInfraApplyRole`, `GyminiDevCfnExecutionRole`) provisioned by CloudFormation ahead of time — no static AWS keys anywhere. This step activates the first real GitHub Actions workflow: **PR validation only** (install/lint/typecheck/unit tests/IaC lint/Docker build + the repo's own PowerShell CI-helper test suites), plus a temporary, tightly-scoped job that proves the OIDC → STS → `GyminiDevCiReadRole` federation works before it is removed. No application deployment, no infrastructure deployment, and no AWS mutation beyond one read-only call happen in this step.

#### Step 1 — Push the activation branch

The permanent workflow (`.github/workflows/pr-validation.yml`, AWS-credential-free: no `id-token` permission, no role assumption, no static keys, no deploy command) and a temporary OIDC smoke workflow (`.github/workflows/pr-validation-oidc-smoke.yml`, removed again before merge) are committed on a dedicated branch cut from the real `origin/aws-deploy` tip, then pushed:

```powershell
git push -u origin <activation-branch>
```

![git push succeeds, the activation branch is created on origin](/images/workshop/runbook/img359.png)

#### Step 2 — Open the pull request

Base `aws-deploy`, compare the activation branch, title `CI: activate PR validation`.

![Pull request form filled in: title and description](/images/workshop/runbook/img360.png)

The comparison against the real `aws-deploy` shows exactly the expected scope: `ahead_by: 1, behind_by: 0, files changed: 26`.

![PR comparison: 1 commit, 26 files changed against the real aws-deploy](/images/workshop/runbook/img362.png)

#### Step 3 — OIDC smoke evidence

Confirmed via the GitHub Actions API on the activation branch: the `oidc-smoke` job completes with `conclusion: success` end to end. This proves real GitHub OIDC → STS → `GyminiDevCiReadRole` federation (`AssumeRoleWithWebIdentity`) is correctly wired.

| Check | Result |
|---|---|
| `impact` | success |
| `chat-image` | success |
| `oidc-smoke` | **success** |

#### Step 4 — Remove the temporary OIDC workflow

`.github/workflows/pr-validation-oidc-smoke.yml` is removed via a plumbing commit (`git read-tree` / `update-index --force-remove` / `write-tree` / `commit-tree`, no working-tree checkout — the branch's tree contains deeply-nested AI-evaluation fixture paths that exceed Windows' `MAX_PATH`, so plumbing operates on the object database only).

#### Step 5 — Final validation run

All real checks pass on the cleanup commit: `unit` (fitness/auth/payment/user/ai/gym), `quality`, `ci-helper-tests`, `chat-image`, `fast-docker-test`, `Critical DB Integration Tests` — all `success`; `iac` correctly `skipped` (no infra file changed in that commit).

#### Step 6 — Merge

Merged into `aws-deploy` as a fast-forward push (`aws-deploy`'s tip was a direct ancestor of the activation branch's tip, so no merge commit was needed): `003545c6..aba97ce7`. `pr-validation.yml` and the `docker-test.yml` updates are now on `aws-deploy`; `pr-validation-oidc-smoke.yml` is gone, as intended.

#### Result

- Activation branch pushed from the real `aws-deploy` tip and pull request opened with exactly the intended scope (1 commit, 26 files).
- Real OIDC → STS → `GyminiDevCiReadRole` federation proven to work (`oidc-smoke: success`) — the core security goal of this step.
- Temporary OIDC smoke workflow removed; final validation run fully green; merged into `aws-deploy` via a clean fast-forward.
- Next phase: `dev-deploy`, `chat-deploy`, `infra-plan` and `infra-deploy` are activated in [5.4.13](../5.4.13-CD-Pipeline-Activation/).
