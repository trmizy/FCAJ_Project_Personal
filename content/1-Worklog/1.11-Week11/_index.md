---
title: "Week 11 Worklog"
date: 2026-07-15
weight: 11
chapter: false
pre: " <b> 1.11. </b> "
draft: false
---

### Week 11 Objectives:

- Refine and improve the frontend of my personal project (Gymini Fitness Assistant)
- Ensure a smooth user experience and fix visual or functional issues on every screen

### Work Completed This Week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Reviewed the personal project's web app screen by screen (Roadmap, Workout, Nutrition, Chat, Admin) and fixed visual and functional issues | 12-10-2026 | 17-10-2026 | |
| Checked every touched screen at phone widths (360, 375, 390 and 412 px) and kept the existing light and dark theme colors | 12-10-2026 | 17-10-2026 | |
| Made the Admin user-management actions work (view profile, change role, lock and unlock) with confirmation dialogs and notifications | 12-10-2026 | 17-10-2026 | |
| Built the web app and published it to the S3 bucket behind CloudFront | 12-10-2026 | 17-10-2026 | |

### Week 11 Results:

**Overview:**

This week was dedicated to polishing the frontend of my personal project. I worked through the screens one by one, fixed what was broken or confusing, and checked each change on a phone-sized screen before publishing it.

**Theoretical Knowledge Gained:**

- **UI/UX Principles:** Deepened my understanding of interface design by resolving practical usability issues, such as buttons that did nothing and layouts that did not fit a phone.

- **Iterative improvement:** Learned to review my own work against a checklist, fix one issue at a time and verify it before moving on.

**Hands-on Labs Completed:**

- Fixed existing bugs and improved the responsiveness and design of the main screens of the web app
- Connected the Admin user-management menu to the existing role, enable and disable APIs, and blocked actions on the signed-in account
- Published the new build to S3 and checked it through the CloudFront address

**Application to Fitness Assistant:**

**UI/UX improvements applied:**
- Responsive design checked at four phone widths
- One theme for light and dark mode, with no one-off colors
- Clear confirmation and result messages for risky actions

**Next for Fitness Assistant:**
- Keep the web app and the deployed environment in step with each release
- Continue the deployment of the backend services on AWS
