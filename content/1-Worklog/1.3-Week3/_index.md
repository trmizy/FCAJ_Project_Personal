---
title: "Week 3 Worklog"
date: 2026-08-17
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### Week 3 Objectives:

- Learn AWS migration strategies (7Rs).
- Practice VM Import/Export and Database Migration.
- Analyze production Dockerfile.

### Tasks for This Week:

| Task | Start Date | Completion Date | Workshop / Reference |
|------|------------|----------------|----------------------|
| - Research 7Rs migration <br/> - Practice VM Import/Export <br/> - Research Database Migration <br/> - Analyze Docker production <br/> - Complete blog 1 | 08-17-2026 | 08-22-2026 | Lab 14: https://000014.awsstudygroup.com/ <br/> Lab 43: https://000043.awsstudygroup.com/ <br/> Blog 1: https://www.facebook.com/share/p/1F8v6Qye3F/ |

### Week 3 Results:

**Overview:**

This week learned about migration - ways to move systems to AWS. Although my project is built new from scratch, understanding migration is still useful, especially DMS might be helpful later. Also started learning how to package Docker for production.

**Knowledge Learned:**

**1. AWS Migration - 7Rs**

AWS has 7 migration strategies:
- **Rehost:** Move as-is to cloud, fast but not optimized
- **Relocate:** Move VMware workload to VMware Cloud on AWS
- **Replatform:** Minor changes to use managed services (RDS...)
- **Refactor:** Rewrite app cloud-native (containers, serverless)
- **Repurchase:** Switch to SaaS instead of self-host
- **Retire:** Shut down unused apps
- **Retain:** Keep on-premise

My project uses Refactor from start since building new.

**2. VM Import/Export**

Through lab 14 learned VM import flow:
1. Export VM from VMware/Hyper-V → virtual disk (VMDK, VHD)
2. Upload disk to S3
3. Use `aws ec2 import-image` to create AMI
4. Launch EC2 from AMI

Key points:
- IAM role `vmimport` must have trust policy and S3 permissions, missing causes InvalidParameter error
- Disk format must be supported (VMDK, VHD, VHDX, OVA)
- S3 bucket same region as EC2

**3. Database Migration**

**AWS SCT:**
- Converts schema between DB engines (Oracle → PostgreSQL...)
- Assessment report shows what can be auto-converted vs manual
- Complex stored procedures usually need manual rewrite

**AWS DMS:**

DMS has 3 migration types:
- **Full load:** Migrate all data, use when have downtime
- **Full load + CDC:** Migrate data first, then sync changes continuously to reduce downtime
- **CDC only:** Only sync changes from a point in time

DMS components:
- Source/Target endpoints
- Replication instance (EC2 running DMS)
- Replication task

**Monitoring:**

Important metrics:
- **CDCLatencySource/Target:** Latency capturing/applying changes
- CPU/Memory/Disk I/O of replication instance
- Network throughput

If CDC latency high, need to check CPU, memory, I/O, network, source workload before deciding to scale instance.

**Multi-AZ:** Only for high availability, not performance fix.

**4. Docker Production**

**Multi-stage build:**

Pattern separating build and runtime:

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci && npm run build

# Runtime stage
FROM node:20-alpine
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]
```

Smaller image without dev deps and source code.

**Frontend static + Nginx:**

```dockerfile
FROM node:20-alpine AS builder
RUN npm ci && npm run build

FROM nginx:1.25-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

Runtime only needs Nginx, no Node.

**Base image:**
- **Alpine:** Small but uses musl libc, sometimes native modules fail
- **Debian slim:** Larger but better compatibility

**Node version:**
- Node 18 EOL (04/2025), don't use for production
- Node 20 LTS until 04/2026
- Should consider Node 22 LTS

**Notes:**
- Must have `.dockerignore`
- Run as non-root user
- Don't hardcode secrets in image

**5. Completed Blog 1**

Finished writing first blog post about AWS learning experience and shared on Facebook group. The post summarizes what was learned from weeks 1-3, labs completed, and some tips for AWS beginners.

Blog link: https://www.facebook.com/share/p/1F8v6Qye3F/

### Lessons Learned:

- Migration needs right strategy for each workload
- VM import most important is IAM role vmimport
- Database migration separates schema conversion and data migration
- CDC reduces downtime but needs monitoring
- Multi-AZ = availability, not performance
- Multi-stage build makes image smaller and more secure
- Base image needs balance between size and compatibility

### References:

- Lab 14 VM Import: https://000014.awsstudygroup.com/
- Lab 43 Database Migration: https://000043.awsstudygroup.com/
- AWS 7Rs: https://docs.aws.amazon.com/prescriptive-guidance/latest/large-migration-guide/migration-strategies.html
