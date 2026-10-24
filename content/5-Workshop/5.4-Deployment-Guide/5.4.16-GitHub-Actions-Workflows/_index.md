---
title: "GitHub Actions workflows"
date: 2026-10-23
weight: 16
chapter: false
pre: " <b> 5.4.16. </b> "
---

This step collects the six GitHub Actions workflows of the project in one place, with the files to download. [5.4.12](../5.4.12-CICD-Pipeline/) and [5.4.13](../5.4.13-CD-Pipeline-Activation/) show how they were activated; this page shows what each one does and how to use it.

#### 1. The workflows

| Workflow (download) | Trigger | Who it acts as | What it does |
|---|---|---|---|
| [pr-validation.yml](../../../files/workshop-files/pr-validation.yml) | Every pull request to `master` or `aws-deploy` | No AWS access | Install, lint, type-check, unit tests per service, IaC lint, Docker build of the chat image, and the PowerShell helper tests |
| [dev-build.yml](../../../files/workshop-files/dev-build.yml) | Push to `aws-deploy`, or manual | No AWS access | Builds and hashes each changed Lambda zip and stores it as a workflow artifact |
| [dev-deploy.yml](../../../files/workshop-files/dev-deploy.yml) | Manual, reviewer approval | `GyminiDevAppDeployRole` through OIDC | Deploys the Lambda code of the chosen services from a build, checks the artifact hashes first, then runs a `/health` smoke check; dry run by default |
| [chat-deploy.yml](../../../files/workshop-files/chat-deploy.yml) | Manual, reviewer approval | `GyminiDevAppDeployRole` | Registers a new ECS task definition revision for the Chat service without changing the desired count |
| [infra-plan.yml](../../../files/workshop-files/infra-plan.yml) | Manual | `GyminiDevInfraPlanRole` | Creates a CloudFormation change set for the API Gateway stack, scans it, publishes a digest of the changes; cannot execute anything |
| [infra-deploy.yml](../../../files/workshop-files/infra-deploy.yml) | Manual, reviewer approval | `GyminiDevInfraApplyRole` | Executes one reviewed change set, only if its digest matches what the plan printed, then runs read-only checks |

{{% notice note %}}
The attached copies replace the AWS account ID with the placeholder `123456789012`. Replace it, and the role names and bucket names, with the values of your own account.
{{% /notice %}}

#### 2. How the safety works

- **No stored keys.** The workflows that touch AWS use the `aws-actions/configure-aws-credentials` action with `role-to-assume`. GitHub issues a short-lived OIDC token, and each IAM role trusts exactly one GitHub environment. There is no access key in the repository or in the repository secrets.
- **A human approves every change.** Jobs that change AWS declare an `environment` (`dev`, `dev-infra-plan`, `dev-infra`). Each environment requires a reviewer, has administrator bypass turned off, and only allows deployment from the `aws-deploy` branch ([5.4.13](../5.4.13-CD-Pipeline-Activation/)).
- **Plan and apply are separate roles.** The plan role has an explicit deny on executing a change set, so it cannot apply anything even if the file is edited. The apply role can execute but cannot create change sets.
- **The reviewed change is the applied change.** The apply workflow takes the digest that the plan printed and refuses to run if the change set no longer matches it.
- **Dry run by default.** The deploy workflows start with `dry_run: true`, so a first run only prints what would happen.

#### 3. Use a workflow

1. Open the repository on GitHub, then **Actions**, and choose the workflow in the left list.
2. Click **Run workflow**, choose the branch `aws-deploy` and fill in the inputs.
3. For a deploy workflow, leave **dry_run** checked on the first run and read the summary. Run again with it unchecked for the real deploy.
4. When the job reaches the `environment` step it shows **Waiting**. Click **Review deployments**, tick the environment and click **Approve and deploy**.

Inputs used in practice:

| Workflow | Input | Example |
|---|---|---|
| `dev-deploy.yml` | `build_run_id` | the run ID of the `dev-build.yml` run to deploy |
| `dev-deploy.yml` | `services` | `auth` |
| `chat-deploy.yml` | `force_on` | unchecked, so the Chat service stays on or off as it is |
| `infra-deploy.yml` | `change_set_name`, `reviewed_digest` | both printed by `infra-plan.yml` |

#### 4. Check the result

In **Actions** every job of the run must be green. A deploy run ends with a summary that lists the services, whether it was a dry run and the result. After a real Lambda deploy, `LastModified` of the function changes and the smoke check calls `/health`:

```text
aws lambda get-function-configuration --function-name fitness-assistant-dev-auth --query LastModified
```

#### Screens of GitHub

1. Open the repository, then **Actions**. Choose a workflow in the left list (1); the runs appear on the right (2).

![The Actions page with the workflow list and the latest runs](/images/workshop/console/gha-1-workflows.jpg)
*The six workflows and the recent runs.*

2. Open a run. A successful run shows the **Success** status (1), every job green (2) and a job summary (3) with the commit, the services, the dry-run flag, the result and the previous code hash kept as a rollback reference.

![A successful DEV Application Deploy run with its job summary](/images/workshop/console/gha-2-green-run.jpg)
*A real deploy run of the Lambda code, finished with Success.*

3. To start a deploy, open the workflow and click **Run workflow**. Choose the branch **aws-deploy** (1), enter the run ID of the build (2) and the services (3), and leave **dry_run** ticked (4) for the first run. Then click **Run workflow** in the form.

![The Run workflow form of the deploy workflow](/images/workshop/console/gha-3-run-workflow-form.jpg)
*The inputs of the deploy workflow.*

4. The approval gate is a GitHub environment. In **Settings → Environments → dev**, **Required reviewers** is ticked with the reviewer (1), administrators cannot bypass the rules (2), and only the **aws-deploy** branch may deploy (3).

![The dev environment with its required reviewer and branch rule](/images/workshop/console/gha-4-environment-dev.jpg)
*The protection rules of the dev environment.*

#### 5. Requirements for a new repository

- The OIDC roles from [5.4.15](../5.4.15-CloudFormation-IaC/) exist, with the GitHub repository name set in the `GitHubRepository` parameter.
- The three GitHub environments exist, each with a required reviewer and the `aws-deploy` deployment branch rule.
- The repository variable `APIGW_ADOPTION_COMPLETE` is set to `true` only after the API Gateway stack has been verified as managed and free of drift.
- Manual workflows exist on the default branch too, because GitHub can only dispatch a workflow that is on the default branch.
