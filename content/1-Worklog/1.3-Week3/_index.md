---
title: "Week 3 Worklog"
date: 2026-08-17
weight: 3
chapter: false
pre: " <b> 1.3. </b> "
---

### Week 3 Objectives:

- Learn AWS migration strategies (7Rs).
- Practice/research VM Import/Export and Database Migration.
- Analyze production Dockerfile for personal project.

### Tasks for This Week:

| Task | Start Date | Completion Date | Workshop / Reference Materials |
|------|------------|----------------|--------------------------------|
| - Research 7Rs migration strategies <br/> - Practice VM Import/Export <br/> - Research Database Migration with SCT and DMS <br/> - Analyze production Docker | 08-17-2026 | 08-22-2026 | Lab 14: https://000014.awsstudygroup.com/ <br/> Lab 43: https://000043.awsstudygroup.com/ <br/> AWS Docs: 7Rs Migration Strategies |

### Week 3 Results:

**Overview:**

This week focused on migration - learning strategies and tools to move workloads to AWS. Although the personal project is built from scratch on AWS, understanding migration strategies helps make appropriate architecture decisions. Also started analyzing how to package production containers in preparation for deployment.

**1. AWS Migration Strategies - 7Rs**

Researched AWS's 7 migration strategies:

- **Rehost (Lift and Shift):** Move workload to cloud almost as-is, without changing code or architecture. Suitable when need to migrate quickly or workload doesn't need immediate optimization.

- **Relocate:** Move infrastructure/workload (typically VMware-based) to AWS without significant architecture changes. Uses VMware Cloud on AWS to maintain vSphere environment.

- **Replatform (Lift and Reshape):** Partially optimize to leverage cloud services (e.g., migrate self-managed database to RDS, or use ELB instead of reverse proxy) but don't change core application. Balance between migration speed and cloud benefits.

- **Refactor/Re-architect:** Redesign application to leverage cloud-native architecture (containers, serverless, microservices, managed services). Most effort but most optimal for cost and scalability.

- **Repurchase:** Switch to different product/SaaS instead of self-hosting. Examples: migrate from on-premise CRM to Salesforce, or from custom email server to Microsoft 365.

- **Retire:** Remove systems no longer needed or used. Reduces maintenance costs and migration effort.

- **Retain:** Keep workload in current environment due to compliance, technical dependencies, or lack of business case to migrate.

For personal project, the suitable strategy is **Refactor** as this is a greenfield project that can be designed cloud-native from the start.

**2. VM Import/Export**

Through workshop lab 14, learned the process to import VMs from on-premise to AWS:

**Workflow:**
1. Export VM from virtualization environment (VMware/Hyper-V/VirtualBox) → obtain virtual disk files (VMDK, VHD, VHDX)
2. Upload virtual disk to S3 bucket
3. Use AWS VM Import/Export to create AMI from virtual disk
4. Launch EC2 instance from imported AMI

**Key points to note:**

- **IAM role and permissions:** Need to create IAM role named `vmimport` with trust policy allowing VM Import service and permissions to access S3 bucket containing disk images. This is mandatory requirement and often the cause of `InvalidParameter` error if missing or misconfigured.

- **Supported formats:** AWS supports VMDK, VHD, VHDX, OVA (containing VMDK). Virtual disk needs to be exported in compatible format.

- **S3 bucket:** Virtual disk file needs to be uploaded to S3 in same region as EC2 instance to be launched. File size can be large (VMs typically several GB to tens of GB).

- **Import process:** Use AWS CLI `aws ec2 import-image` with complete parameters (disk containers, description, role name). Import process can take from minutes to hours depending on disk size.

**Workshop doesn't go deep into complex network/storage config.** After getting AMI, launch EC2 instance following normal flow and verify instance works.

**3. Database Migration**

Through workshop lab 43, learned two main tools:

**AWS Schema Conversion Tool (SCT):**
- Converts database schema and code objects between different database engines (Oracle → PostgreSQL, SQL Server → MySQL, etc.)
- Analyzes source schema and automatically converts most objects: tables, views, stored procedures, functions, triggers
- Creates Assessment Report to identify:
  - Objects that can be auto-converted
  - Objects requiring manual action (marked "Action Required")
  - Estimated complexity and effort

For stored procedures or database objects that can't be automatically converted, need to evaluate case by case: rewrite for target engine or refactor logic to application layer if appropriate for architecture.

**AWS Database Migration Service (DMS):**

DMS helps migrate data with minimal downtime. **Migration types:**

- **Full load:** Migrate all existing data from source to target. Suitable when can afford downtime or is initial load.

- **Full load + CDC (Change Data Capture):** Migrate existing data first, then continuously replicate changes occurring at source. This is common approach to **reduce downtime** - application still writes to source DB, DMS syncs changes to target, then cutover.

- **CDC only:** Only replicate changes from specific time/log position, doesn't load initial data. Used when target already has data or combined with separate backup/restore.

**DMS components:**
- **Source endpoint:** Connection to source database (on-premise, EC2, RDS)
- **Target endpoint:** Connection to target database (RDS, Aurora, Redshift, S3, DynamoDB...)
- **Replication instance:** EC2 instance running DMS software, performs data extract and load
- **Replication task:** Defines migration type, table mappings, transformation rules

**Monitoring:**

Important DMS metrics to monitor via CloudWatch:
- **CDCLatencySource:** Time delay reading/capturing changes from source. High value indicates capture process is lagging.
- **CDCLatencyTarget:** Time delay applying changes to target.
- **CPU/Memory/Storage:** Of replication instance.
- **Network throughput:** Between source, replication instance, target.

When CDC latency increases, need to troubleshoot:
- Check CPU, memory, swap usage of replication instance
- Check disk I/O
- Check network bandwidth
- Review workload/transaction volume at source
- Review replication task settings
- Check target database processing capability

After identifying bottleneck, can scale up replication instance size if needed.

**Multi-AZ:**

Multi-AZ for DMS replication instance primarily serves **high availability and failover**, not a direct solution to improve performance or reduce latency. Enable Multi-AZ when need:
- Increased reliability for long-running migrations
- Disaster recovery capability
- Production migrations requiring high uptime

**4. Docker Production Analysis**

For personal project, need to analyze how to package production containers.

**Multi-stage Docker build:**

Multi-stage build helps separate build environment from runtime environment:

```dockerfile
# Stage 1: Builder - install dependencies and build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Runtime - only copy necessary artifacts
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

**Benefits:**
- Smaller image size (doesn't contain dev dependencies, source code, build tools)
- Reduced attack surface (fewer packages and tools in production image)
- Clear separation between build and runtime concerns

**Frontend static with Nginx:**

For frontend built into static files (React/Vue/Angular), common pattern:

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
# Output: /app/dist

# Runtime stage
FROM nginx:1.25-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Runtime image is just Nginx serving static files, no Node.js runtime needed.

**Base image considerations:**

**Alpine Linux:**
- Advantages: small image (typically < 100MB), fewer default packages, reduced attack surface
- Limitations: uses musl libc instead of glibc, some native modules may have compatibility issues

**Debian-based (slim variants):**
- Advantages: uses glibc, better compatibility, easier to debug native dependencies
- Limitations: larger image than Alpine

Need to choose based on trade-off between size and compatibility.

**Node.js version lifecycle:**

When choosing Node.js base image for production in 08/2026, should prioritize versions still in LTS (Long Term Support) or at least Active support. Check [Node.js release schedule](https://nodejs.org/en/about/previous-releases) to ensure version in use still receives security updates.

Node 18 reached End-of-Life in 04/2025, should not use for new production. Node 20 LTS has support until 04/2026. If project uses Node 20, need to evaluate upgrading to Node 22 LTS (active until 2027) after testing compatibility.

**Potential issues and notes:**

- **.dockerignore:** Need to have to avoid copying `node_modules`, `.env`, `.git`, build artifacts into build context. Reduces build time and avoids leaking sensitive data.

- **Non-root user:** Should run application with non-root user in container to increase security. Add `USER node` (or create custom user) before CMD.

- **Health checks:** Add HEALTHCHECK instruction so container orchestrator (ECS, Kubernetes) knows container status.

- **Secrets management:** Don't hardcode credentials into Dockerfile or image. Use environment variables or AWS Secrets Manager when deploying.

### Lessons Learned:

- Migration isn't just moving data but requires choosing appropriate strategy for each workload.
- VM migration requires attention to IAM permissions, disk formats and proper S3 setup.
- Database migration needs to separate schema conversion (SCT) and data migration (DMS).
- CDC helps reduce downtime but needs monitoring to ensure no lag.
- Multi-AZ serves availability, not performance scaling.
- Multi-stage Docker build helps optimize production images.
- Base image selection needs balance between size, compatibility and security lifecycle.
- Analyzing production container requirements helps better preparation for deployment phase.

### References:

- VM Import/Export Workshop: https://000014.awsstudygroup.com/
- Database Migration Workshop: https://000043.awsstudygroup.com/
- AWS Migration Strategies (7Rs): https://docs.aws.amazon.com/prescriptive-guidance/latest/large-migration-guide/migration-strategies.html
- AWS VM Import/Export: https://docs.aws.amazon.com/vm-import/latest/userguide/what-is-vmimport.html
- AWS DMS: https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html
- AWS SCT: https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html
