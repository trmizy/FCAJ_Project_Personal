---
title: "Week 7"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 1.7. </b> "
draft: false
---

# WEEK 7 WORKLOG

### Week 7 Objectives:

- Complete Module 6: Data & Analytics
- Learn the architecture, deployment, and operational best practices for building an enterprise Data Lake
- Master the full data analytics lifecycle, from ingestion to processing and advanced visualization on AWS

### Tasks to be carried out this week:

| Task | Start Date | Completion Date | Reference Materials |
| --- | --- | --- | --- |
| Study and complete Module 6: Data & Analytics | 31-7-2026 | 06-8-2026 | 70: https://000070.awsstudygroup.com/ <br>72: https://000072.awsstudygroup.com/ <br>73: https://000073.awsstudygroup.com/ |

### Week 7 Achievements:

**Overview:**

During this week, my primary focus shifted toward big data processing and business intelligence by completing Module 6 (Data & Analytics). The coursework involved designing scalable Data Lake infrastructures, executing complex analytics pipelines, and rendering actionable insights using AWS native visualization tools.

**Note:** The execution phase of Lab 70 (Building a Datalake with Your Data) required an AWS Cloud9 environment. Since AWS Cloud9 is currently inaccessible in my environment, I skipped the hands-on execution for this specific lab, though I thoroughly analyzed the architectural principles and theoretical concepts provided.

**Learned theory:**

- **Data Lake Foundation:** Grasped the architectural blueprints for building highly scalable, secure, and cost-effective Data Lakes using Amazon S3 to store both structured and unstructured data.

- **Analytics Pipeline:** Mastered the end-to-end data processing workflow, spanning data ingestion mechanisms, robust ETL (Extract, Transform, Load) operations, and high-performance querying logic.

- **Data Visualization:** Learned how to translate raw data feeds and analytical query results into interactive, dynamic dashboards and comprehensive business intelligence reports utilizing Amazon QuickSight.

**Hands-on labs:**

- Engineered a conceptual Data Lake infrastructure designed to securely ingest, catalog, and query organizational datasets
- Executed the comprehensive Analytics on AWS workshop, gaining practical experience in integrating various AWS analytics services to process and analyze large-scale data sets
- Successfully configured Amazon QuickSight, established secure connections with backend data sources, curated datasets, and published visual dashboards to drive business insights
- Skipped the active execution of Lab 70 due to the dependency on AWS Cloud9, focusing entirely on mastering the theoretical deployment framework instead

**Applied to Fitness Assistant:**

Designed Data Lake strategy for Fitness Assistant analytics:
- Data sources: workout logs, nutrition tracking, InBody measurements, user behavior, AI interactions
- Architecture: S3 (raw data) → Glue Crawler → Data Catalog → Athena/QuickSight
- Use cases: workout analytics, nutrition patterns, user engagement metrics, AI performance monitoring
- Implementation: S3 bucket structure, partitioning strategy, QuickSight dashboards

### Difficulties Encountered:

- **Cloud9 Limitation:** Unable to access AWS Cloud9, resulting in skipped hands-on for Lab 70
- **Data Schema Design:** Balancing normalization vs denormalization for analytics
- **Partitioning Strategy:** Deciding optimal partition granularity
- **QuickSight Learning Curve:** Many visualization options overwhelming initially

### How It Was Resolved:

- **Cloud9:** Focused on architectural patterns from documentation
- **Schema Design:** Started simple, iterate based on query patterns
- **Partitioning:** Follow best practice (date-based, 128MB-1GB per partition)
- **QuickSight:** Started with simple visualizations, gradually explored advanced features

### AWS Skills / Services Learned:

**Services:**
- Amazon S3 (Data Lake storage)
- AWS Glue (ETL, Data Catalog, Crawlers)
- Amazon Athena (serverless SQL queries)
- Amazon QuickSight (business intelligence)
- AWS Lake Formation
- Amazon Kinesis

**Skills:**
- Data Lake architecture design
- ETL pipeline development
- Serverless SQL querying
- BI dashboard creation
- Data partitioning strategies
- Analytics cost optimization

### Connection to Fitness Assistant Architecture:

**Immediate Applications:**
- Design S3 structure for application logs
- Plan data schema for analytics
- Identify key metrics to track

**Future Enhancements:**
- Implement Data Lake for user behavior analytics
- Build QuickSight dashboards for business insights

### Related Workshop Sections:

- [5.8 ECR](../../5-Workshop/5.8-ECR/) - Containerization for data processing jobs
