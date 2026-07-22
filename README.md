# Cloud-Native AI Fitness Assistant on AWS — Internship Report

Bilingual (English/Vietnamese) Hugo report documenting the design and deployment of the [Fitness Assistant](https://github.com/trmizy/fitness-assistant) application on AWS, produced for the First Cloud AI Journey (FCAJ) internship program.

- **Project (English):** Cloud-Native AI Fitness Assistant on AWS
- **Project (Vietnamese):** Xây dựng và triển khai Trợ lý Thể hình AI trên AWS
- **Application source code:** https://github.com/trmizy/fitness-assistant (credited, not written by this report's author — see the Workshop and Proposal sections for what was actually built versus what already existed in source)
- **Report template source:** https://github.com/thienluhoan/fcj-workshop-template (Hugo + [hugo-theme-learn](https://github.com/matcornic/hugo-theme-learn), used as-is for structure/theme; content is original)
- **FCAJ project rules:** https://hcm-rules.awsfcaj.com/3-project/

## Requirements

- [Hugo Extended](https://gohugo.io/installation/) v0.134+ (the CI workflow pins `0.134.3`)
- Git

## Clone (with the theme submodule)

```bash
git clone --recurse-submodules <REPORT_REPOSITORY_URL>
cd <REPORT_REPOSITORY_NAME>
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## Run Locally

```bash
hugo server -D
```

Open the URL printed in the terminal (typically `http://localhost:1313/`). Draft content (`-D`) is included so `TODO` pages are visible while editing.

Because `config.toml` sets a GitHub Pages `baseURL` placeholder, the local server prints a URL containing the literal `<YOUR_REPOSITORY>` placeholder until that value is filled in. To browse locally without editing the config, override the base URL for the session instead:

```bash
hugo server -D -b http://localhost:1313/
```

## Build for Production

```bash
hugo --minify
```

Output is written to `public/` (git-ignored; this is a build artifact, not source).

## Project Structure

```
content/            Site content (Markdown), English (_index.md) + Vietnamese (_index.vi.md)
  1-Worklog/         Weeks 1–12
  2-Proposal/
  3-BlogsPosted/
  4-EventParticipated/
  5-Workshop/         5.1–5.17, the main technical workshop
  6-Self-evaluation/
  7-Feedback/
layouts/            Small template customizations on top of hugo-theme-learn
static/
  images/            Screenshots, organized by section — see each folder's README.md
  files/             Downloadable examples: Dockerfiles, compose files, IAM policies, scripts
themes/hugo-theme-learn/   Git submodule — do not edit directly
config.toml         Site config (bilingual menu, theme variant, etc.)
```

## Adding English Content

Add or edit the `_index.md` file inside the relevant `content/` subfolder. Front matter requires at least `title`, `date`, `weight`, and `chapter: false`; add `pre: " <b> X.Y. </b> "` to match the existing numbering style.

## Adding Vietnamese Content

Add or edit the matching `_index.vi.md` file in the same folder. Every English page in this report has a Vietnamese counterpart — keep both in sync when editing either one.

## Adding Screenshots

1. Save the image under the matching `static/images/<section>/...` folder (see that folder's `README.md` for the expected filenames).
2. Reference it in Markdown with an absolute path and descriptive alt text: `![Description of what the screenshot shows](/images/workshop/ec2/01-ec2-instance-details.png)`.
3. Do not add a screenshot of something that was not actually done — see the root `TODO` policy below.

## Adding the draw.io Architecture Diagram

1. Replace `static/files/architecture/fitness-assistant-aws-architecture.drawio` with the real diagram source.
2. Export a PNG and replace `static/images/workshop/architecture/fitness-assistant-aws-architecture.png`.
3. Both files are currently placeholders — see each folder's `README.md`.

## Checking for Broken Internal Links

Hugo does not fail the build on a broken relative link by default. Before submitting:

```bash
hugo --minify --printPathWarnings
```

Review the warnings, and manually click through the built site's navigation (`hugo server -D`) to confirm every "Content"/"Related Workshop Section" link resolves.

## Deploying to GitHub Pages

`.github/workflows/hugo.yml` builds with `hugo --minify` and deploys `public/` to the `gh-pages` branch on every push to `main` (or via manual `workflow_dispatch`). It checks out submodules recursively so the theme is present in CI. No secrets are hard-coded in the workflow; it uses the default `GITHUB_TOKEN`.

## TODO Policy

This report intentionally contains `[TODO_...]` placeholders and `TODO:` notes wherever real evidence (screenshots, dates, personal information, cost figures, test results) has not yet been produced. **Do not replace a TODO with invented data.** Replace it only with a real value once the corresponding work has actually been done. See each section's `{{% notice warning %}}` callouts for what must not be claimed without evidence.

## Pre-Submission Checklist

- [ ] All `[TODO_FULL_NAME]`, `[TODO_PHONE]`, `[TODO_EMAIL]`, etc. placeholders replaced with real (but appropriately private) information
- [ ] Real profile photo replaces `static/images/profile/avatar-placeholder.png`
- [ ] Real architecture diagram replaces both placeholder files (see above)
- [ ] `hugo server -D` runs without error and every page's navigation works
- [ ] `hugo --minify` builds without error
- [ ] No AWS access keys, passwords, or other secrets anywhere in the repository (`git grep` for suspicious strings before committing)
- [ ] Every claim of "Implemented" is backed by a screenshot or command output in the relevant Workshop section
- [ ] Remaining `TODO`s reviewed and either resolved or consciously left for a later update

## Attribution

- Report template: [thienluhoan/fcj-workshop-template](https://github.com/thienluhoan/fcj-workshop-template), built on [hugo-theme-learn](https://github.com/matcornic/hugo-theme-learn) by matcornic.
- Application under study: [trmizy/fitness-assistant](https://github.com/trmizy/fitness-assistant). This repository's author did not write that application; this report documents deploying it to AWS. No `LICENSE` file exists in the `fitness-assistant` source repository as of this writing — do not assume a specific license when reusing its code.
