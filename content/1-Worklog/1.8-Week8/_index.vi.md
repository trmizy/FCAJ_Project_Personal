---
title: "Tuần 8"
date: 2026-07-15
weight: 8
chapter: false
pre: " <b> 1.8. </b> "
draft: false
---

# WORKLOG TUẦN 8

### Mục tiêu tuần 8:

- Hoàn thành Module 7: AI/ML service on AWS
- Trải nghiệm AWS SageMaker thông qua workshop Immersion Day
- Tiếp tục tích hợp vào môi trường công ty

### Công việc thực hiện tuần này:

| Công việc | Ngày bắt đầu | Ngày hoàn thành | Tài liệu tham khảo |
| --- | --- | --- | --- |
| Học và hoàn thành Module 7: AI/ML service on AWS | 07-8-2026 | 13-8-2026 | Lab 200: https://000200.awsstudygroup.com/ |

### Kết quả đạt được tuần 8:

**Tổng quan:**

Trong tuần này, mình shift focus sang Artificial Intelligence và Machine Learning trên AWS bằng cách hoàn thành Module 7. Mình gain practical exposure với AWS SageMaker thông qua hands-on workshop. In addition, mình continue engage với team và professional community.

**Kiến thức lý thuyết học được:**

- **AI/ML on AWS:** Hiểu fundamentals của Machine Learning workflows trên cloud, các service chính của AWS cho ML lifecycle.

- **AWS SageMaker:** Học cách build, train, và deploy machine learning models nhanh chóng sử dụng SageMaker's fully managed infrastructure.

**Hands-on labs đã thực hiện:**

- Successfully completed SageMaker Immersion Day workshop (Lab 200), getting hands-on experience với deploying và testing ML models
- Thử nghiệm các tính năng của SageMaker: notebook instances, training jobs, model deployment, real-time inference endpoints

**Áp dụng vào Fitness Assistant:**

**ML Use Cases cho Fitness Assistant:**

Sau khi học về AWS ML services, mình identify potential ML applications:

**1. Workout Recommendations (AI Service đã có - Enhancement):**
- Current: Ollama self-hosted LLM cho workout recommendations
- Enhancement opportunity: Evaluate Amazon Bedrock vs self-hosted
- Trade-off analysis: Cost (per-request vs fixed EC2), Control (full vs managed), Latency

**2. Exercise Form Analysis (Future Enhancement):**
- Use case: Analyze workout videos/photos để check form correctness
- AWS Service: Amazon Rekognition Custom Labels hoặc SageMaker custom model
- Training data: Labeled videos của correct vs incorrect exercise forms
- Deployment: Real-time inference endpoint hoặc batch processing

**3. Personalized Nutrition Recommendations:**
- Use case: Recommend meals based on user preferences, goals, dietary restrictions
- Approach: SageMaker model trained trên user nutrition data và outcomes
- Features: User demographics, fitness goals, past meal ratings, macro targets
- Output: Personalized meal suggestions

**4. Workout Progress Prediction:**
- Use case: Predict user's future performance based on historical data
- ML Model: Time-series forecasting với SageMaker built-in algorithms
- Features: Past workout performance, consistency, nutrition adherence
- Value: Help users set realistic goals

**5. Churn Prediction:**
- Use case: Identify users at risk of stopping app usage
- Model: Binary classification (churn/not churn)
- Features: Login frequency, workout completion rate, feature usage patterns
- Action: Trigger retention campaigns for at-risk users

**SageMaker vs Self-Hosted Decision:**

**For AI Service (LLM-based recommendations):**
- **Current:** Self-hosted Ollama trên EC2
- **Pros:** Fixed cost, full control, no per-request charges
- **Cons:** Require larger EC2 instance, manual scaling, maintenance overhead
- **Consideration:** Evaluate Amazon Bedrock for managed alternative

**For Computer Vision (Exercise Form):**
- **Recommendation:** Use SageMaker hoặc Rekognition
- **Reason:** Model training infrastructure costly để self-host, managed services cost-effective for this use case

**Implementation Roadmap:**

**Phase 1 - Current State:**
- Self-hosted Ollama LLM cho text-based recommendations
- Continue current approach, document sizing requirements

**Phase 2 - Enhancement (3-6 months):**
- Pilot Amazon Bedrock integration (parallel với Ollama)
- A/B test quality và cost của both approaches
- Collect data cho future ML models (exercise form images, user interactions)

**Phase 3 - Advanced ML (6-12 months):**
- Train custom SageMaker model cho exercise form analysis
- Implement personalized nutrition recommendation system
- Build churn prediction model

### Khó khăn gặp phải:

- **SageMaker Learning Curve:** SageMaker console có nhiều components (notebook instance, training job, model registry, endpoint), overwhelming lúc đầu.

- **Cost Understanding:** SageMaker pricing model phức tạp (instance hours, training costs, inference costs, storage). Khó estimate costs cho production workloads.

- **Model Selection:** AWS có nhiều ML services (SageMaker, Bedrock, Rekognition, Comprehend, Personalize). Confusing về khi nào dùng service nào.

- **Integration Planning:** Unclear về cách integrate SageMaker endpoints với existing Fitness Assistant architecture.

### Cách giải quyết:

- **Learning:** Complete full Immersion Day workshop end-to-end thay vì skim. Take notes về key concepts và best practices.

- **Cost Analysis:** Use AWS Pricing Calculator để estimate costs. So sánh SageMaker costs với current self-hosted approach cho Fitness Assistant use case.

- **Service Selection:** Create decision matrix: 
  - Bedrock: Pre-trained foundation models (LLM, text generation)
  - SageMaker: Custom model training và deployment
  - Rekognition: Pre-trained computer vision (object/face detection)
  - Use SageMaker khi need custom model, use managed services (Bedrock/Rekognition) khi pre-trained sufficient.

- **Integration:** Design architecture diagram cho SageMaker endpoint integration với API Gateway → Lambda → SageMaker pattern.

### Kỹ năng / Dịch vụ AWS đã học:

**Services:**
- Amazon SageMaker (notebook instances, training jobs, model deployment, endpoints)
- SageMaker Built-in Algorithms
- SageMaker Studio
- Amazon Bedrock (overview, comparison với SageMaker)
- Amazon Rekognition (overview)

**Skills:**
- ML workflow trên AWS cloud
- Model training và deployment best practices
- Managed vs self-hosted ML infrastructure trade-offs
- Cost optimization cho ML workloads
- Real-time inference endpoint design
- Batch prediction strategies

### Liên kết với Fitness Assistant Architecture:

**Immediate Applications:**
- Document current AI service architecture
- Cost analysis: Self-hosted vs managed alternatives
- Plan data collection strategy cho future ML models

**Future Enhancements:**
- Exercise form analysis với computer vision
- Personalized recommendations với custom ML models
- Churn prediction và user engagement optimization

### Liên kết Workshop tương ứng:

- [5.9 EC2 Deployment](../../5-Workshop/5.9-EC2-Deployment/) - AI service deployment strategies
