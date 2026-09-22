---
title: "Worklog Tuần 7"
date: 2026-07-15
weight: 7
chapter: false
pre: " <b> 1.7. </b> "
draft: false
---

# WORKLOG TUẦN 7

### Mục tiêu tuần 7:

- Hoàn thành Module 6: Data & Analytics
- Học architecture, deployment, và operational best practices để xây dựng enterprise Data Lake
- Nắm vững full data analytics lifecycle, từ ingestion đến processing và advanced visualization trên AWS

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Học và hoàn thành Module 6: Data & Analytics | 31-7-2026 | 06-8-2026 | 70: https://000070.awsstudygroup.com/ <br>72: https://000072.awsstudygroup.com/ <br>73: https://000073.awsstudygroup.com/ |

### Kết quả đạt được tuần 7:

**Tổng quan:**

Trong tuần này, focus chính của mình chuyển sang big data processing và business intelligence bằng cách hoàn thành Module 6 (Data & Analytics). Coursework bao gồm designing scalable Data Lake infrastructures, executing complex analytics pipelines, và rendering actionable insights sử dụng AWS native visualization tools.

**Lưu ý:** Execution phase của Lab 70 (Building a Datalake with Your Data) yêu cầu AWS Cloud9 environment. Do AWS Cloud9 hiện không accessible trong environment của mình, mình skip hands-on execution cho lab này, nhưng thoroughly analyzed architectural principles và theoretical concepts được cung cấp.

**Kiến thức lý thuyết học được:**

- **Data Lake Foundation:** Nắm architectural blueprints để build highly scalable, secure, và cost-effective Data Lakes sử dụng Amazon S3 để store cả structured và unstructured data.

- **Analytics Pipeline:** Master end-to-end data processing workflow, spanning data ingestion mechanisms, robust ETL (Extract, Transform, Load) operations, và high-performance querying logic.

- **Data Visualization:** Học cách translate raw data feeds và analytical query results thành interactive, dynamic dashboards và comprehensive business intelligence reports sử dụng Amazon QuickSight.

**Hands-on labs đã thực hiện:**

- Engineer conceptual Data Lake infrastructure designed để securely ingest, catalog, và query organizational datasets
- Execute comprehensive Analytics on AWS workshop, gain practical experience trong việc integrate các AWS analytics services để process và analyze large-scale data sets
- Successfully configure Amazon QuickSight, establish secure connections với backend data sources, curate datasets, và publish visual dashboards để drive business insights
- Skip active execution của Lab 70 do dependency on AWS Cloud9, focus entirely vào mastering theoretical deployment framework

**Áp dụng vào Fitness Assistant:**

**Data Lake Strategy cho Fitness Assistant:**

Fitness Assistant generate nhiều loại data có thể benefit từ Data Lake architecture:

**1. Data Sources cần collect:**
- **User workout logs:** Exercise records, sets, reps, weights, duration
- **Nutrition tracking:** Meals, calories, macros, meal photos
- **InBody measurements:** Weekly/monthly body composition data
- **User behavior analytics:** App usage patterns, feature adoption, user flows
- **AI interaction logs:** Chatbot conversations, AI recommendations, feedback
- **System metrics:** API latency, error rates, service health

**2. Data Lake Architecture Design:**

```
Data Sources → Amazon S3 (Raw Data Lake)
                ↓
           AWS Glue Crawler (Auto-discover schema)
                ↓
           AWS Glue Data Catalog
                ↓
      ┌─────────┴─────────┐
      ↓                   ↓
Amazon Athena      Amazon QuickSight
(Ad-hoc queries)   (Dashboards/BI)
```

**3. Use Cases cho Data Analytics:**

**Workout Analytics:**
- Most popular exercises by demographics
- Average workout duration trends
- Equipment usage patterns
- Progress tracking aggregations
- Workout completion rates

**Nutrition Analytics:**
- Common dietary patterns
- Macro distribution trends
- Meal timing analysis
- Calorie intake vs fitness goals correlation

**User Engagement:**
- Daily/Weekly/Monthly Active Users (DAU/WAU/MAU)
- Feature adoption rates
- User retention cohorts
- Churn prediction indicators

**AI Performance:**
- AI recommendation accuracy
- User satisfaction với AI responses
- Common AI query patterns
- AI response time analysis

**4. Implementation Plan:**

**Phase 1 - Data Collection Setup:**
- Setup S3 bucket với proper folder structure (year/month/day partitions)
- Implement application logging để stream data to S3
- Configure lifecycle policies cho data retention

**Phase 2 - Data Cataloging:**
- Run AWS Glue Crawler để auto-discover schemas
- Create Glue Data Catalog tables
- Setup partitioning strategy

**Phase 3 - Analytics & Visualization:**
- Write Athena queries cho common analytics
- Build QuickSight dashboards cho:
  - User engagement metrics
  - Workout trends analysis
  - Nutrition patterns overview
  - AI performance monitoring
  - Business KPIs tracking

**5. Cost Optimization:**
- Use S3 Intelligent-Tiering cho automatic cost optimization
- Partition data properly để reduce Athena scan costs
- Use QuickSight SPICE để cache frequent queries
- Implement data retention policies (keep detailed logs for 90 days, aggregated data for longer)

### Khó khăn gặp phải:

- **Cloud9 Limitation:** Không access được AWS Cloud9 (region restrictions / account limitations), resulting in skipped hands-on cho Lab 70. However, conceptual understanding vẫn được maintain through documentation study.

- **Data Schema Design:** Designing optimal data schema cho analytics challenging - balance giữa normalization (storage efficiency) và denormalization (query performance).

- **Partitioning Strategy:** Decide partition keys phức tạp - partition too granular = too many small files (performance hit), partition too coarse = scan unnecessary data (cost issue).

- **QuickSight Learning Curve:** QuickSight có nhiều visualization options và configuration settings, overwhelming lúc đầu.

### Cách giải quyết:

- **Cloud9 Workaround:** Focus vào architectural patterns và best practices từ lab documentation. Study AWS documentation và video tutorials để understand Data Lake implementation.

- **Schema Design:** Research common analytics patterns trong fitness/health domain. Start với simple schema, iterate based on actual query patterns. Consider using semi-structured data (JSON in S3) cho flexibility.

- **Partitioning Strategy:** Follow best practice: partition by date (year/month/day) cho time-series data. Aim for partition size ~128MB-1GB. Use Glue Crawler partition projection cho automatic partition discovery.

- **QuickSight Learning:** Start với simple visualizations (line charts, bar charts), gradually explore advanced features. Use QuickSight tutorials và sample datasets để practice.

### Kỹ năng / Dịch vụ AWS đã học:

**Services:**
- Amazon S3 (Data Lake storage)
- AWS Glue (ETL, Data Catalog, Crawlers)
- AWS Glue DataBrew (data preparation)
- Amazon Athena (serverless SQL queries)
- Amazon QuickSight (business intelligence, visualization)
- AWS Lake Formation (data lake governance)
- Amazon Kinesis (real-time data streaming)
- AWS Glue Streaming ETL

**Skills:**
- Data Lake architecture design
- ETL pipeline development
- Data cataloging và metadata management
- Serverless SQL querying với Athena
- Business intelligence dashboard creation
- Data partitioning strategies
- Cost optimization cho analytics workloads
- Data governance và access control

### Liên kết với Fitness Assistant Architecture:

**Immediate Applications:**
- Design S3 bucket structure cho application logs
- Plan data schema cho workout/nutrition analytics
- Identify key metrics to track

**Future Enhancements:**
- Implement Data Lake cho user behavior analytics
- Build QuickSight dashboards cho business insights
- Setup real-time analytics với Kinesis (optional)
- Create ML pipelines sử dụng data lake (advanced)

### Liên kết Workshop tương ứng:

- [5.8 ECR](../../5-Workshop/5.8-ECR/) - Containerization cho data processing jobs
