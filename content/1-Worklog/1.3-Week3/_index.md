---
title: "Week 3 Worklog"
date: 2026-08-17
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### Week 3 Objectives:

- Learn and practice migration labs: VM Import/Export and Database Migration.
- Research AWS migration strategies (Rehost, Replatform, Refactor).
- Continue analyzing personal project source code, prepare to write production Dockerfile.

### Tasks for This Week:

| Task | Start Date | Completion Date | Workshop / Reference Materials |
|------|------------|----------------|--------------------------------|
| - Learn labs on VM Import/Export and Database Migration <br/> - Research migration strategies <br/> - Analyze existing Dockerfile in project | 08-17-2026 | 08-22-2026 | 14: https://000014.awsstudygroup.com/ <br/> 43: https://000043.awsstudygroup.com/ |

### Week 3 Results:

**Overview:**

This week learned about migration - ways to move systems from on-premise or other clouds to AWS. Although the personal project is built from scratch on AWS, understanding migration is still important, especially the Database Migration Service (DMS) which can be used for data sync later. Also started learning about Dockerfile to prepare for containerizing the app.

**Knowledge Learned:**

- **VM Import/Export:** How to import virtual machines (VMware, Hyper-V, VirtualBox) to AWS EC2. Understood OVA/OVF formats and conditions for successful import. In reality, my project is new build so no need to import VMs, but knowing this concept helps understand how AWS handles virtualization.

- **AWS Schema Conversion Tool (SCT):** Tool to convert database schema from one engine to another (e.g., Oracle → PostgreSQL, SQL Server → MySQL). SCT analyzes code and reports what can be auto-converted and what needs manual fixes. Very useful when migrating databases between platforms.

- **AWS Database Migration Service (DMS):** Service to migrate data between databases with minimal downtime. Has 2 modes: full load (migrate everything) and CDC (change data capture - continuous sync). DMS supports many sources/targets: MySQL, PostgreSQL, Oracle, MongoDB, S3...

- **Migration Strategies (6R):** Learned about 6 common migration strategies:
  - **Rehost (Lift and Shift):** Move as-is to cloud, fast but not optimized
  - **Replatform (Lift and Reshape):** Minor changes (RDS instead of self-managed DB) but don't change core
  - **Refactor/Re-architect:** Rewrite to leverage cloud-native (serverless, containers)
  - **Repurchase:** Switch to SaaS instead of self-hosting
  - **Retire:** Shut down unused apps
  - **Retain:** Keep on-premise for specific reasons

**Hands-on Practice:**

- Did VM Import/Export lab (lab 14) - practiced importing VM image to EC2, configuring network and storage.
- Did Database Migration lab (lab 43) - used DMS to migrate data from source DB to target DB on RDS. Set up replication instance, created endpoints, monitored migration task.
- Read existing Dockerfile in personal project (if any) to understand how app is containerized. Noted base image, dependencies, exposed port, entrypoint.
- Researched multi-stage Docker build to reduce production image size. Dev images are usually large with many build tools, production only needs runtime.

**Difficulties Encountered:**

1. **VM Import troubleshooting:** VM import to EC2 failed with "InvalidParameter" error because OVA file was wrong format. Had to use VMware/VirtualBox to re-export to correct OVF 1.0 or 2.0 standard.

2. **DMS replication lag:** When setting up CDC (continuous replication), target DB lagged behind source. CloudWatch metrics monitoring showed CDCLatencySource increasing. Had to tune replication instance size.

3. **Schema conversion complexity:** SCT couldn't auto-convert some complex stored procedures. Assessment report showed "Action Required", had to rewrite manually. Time-consuming if DB has lots of logic.

4. **Docker multi-stage build:** First time writing multi-stage Dockerfile was confusing about how to copy artifacts from one stage to another. Build stage needs build tools (npm, webpack) but production stage only needs runtime (node).

5. **Dockerfile base image choice:** Which base image to choose for Node.js? `node:18`, `node:18-alpine`, or `node:18-slim`? Alpine is smallest (50MB) but uses musl instead of glibc, sometimes has compatibility issues.

**Solutions:**

- **VM Import:** Read AWS docs about VM Import requirements. Export VM in correct format, disable unsupported virtual hardware features (USB controller, audio). Use `aws ec2 import-image` with full parameters.

- **DMS lag:** Increased replication instance size from `dms.t3.micro` to `dms.t3.small`. Enable Multi-AZ if need high availability. Monitor CloudWatch metrics regularly.

- **Schema conversion:** Run SCT assessment before migrating to understand workload. For complex stored procedures, can refactor logic to application layer instead of keeping in DB. Modern practice is thin database, thick application.

- **Multi-stage build:** Learned pattern: stage 1 (builder) install dev deps + build, stage 2 (production) only copy artifacts from builder. Example:
  ```dockerfile
  FROM node:18 AS builder
  COPY package*.json ./
  RUN npm ci
  COPY . .
  RUN npm run build
  
  FROM node:18-slim
  COPY --from=builder /app/dist ./dist
  CMD ["node", "dist/index.js"]
  ```

- **Base image:** For personal project, use `node:18-slim` as good balance: smaller than full image, more stable than alpine. Use Alpine later after thorough testing, as may encounter issues with native modules.
