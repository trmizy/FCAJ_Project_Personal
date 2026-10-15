---
title: "Blog 2: Thách thức triển khai và tối ưu chi phí trên AWS"
date: 2026-07-15
weight: 2
chapter: false
pre: " <b> 3.2. </b> "
draft: false
---

## Thách thức triển khai và tối ưu chi phí trên AWS: Bài học thực tế từ dự án Gymini

**Trạng thái:** Case study kỹ thuật, viết từ kinh nghiệm triển khai Gymini trong nội dung thực tập này.

**Chia sẻ trên Facebook:** https://www.facebook.com/share/p/19qBt1z5fU/

{{% notice note %}}
Bài viết bám theo những gì đã được xác nhận trong runbook triển khai và trong chính báo cáo này (link kèm theo từng mục). Phần nói về việc "credit AWS cạn nhanh hơn dự kiến" và việc "chuyển sang CloudFormation" được trình bày như một **case study minh hoạ**, dựa trên cấu trúc chi phí thật của kiến trúc đã deploy — không phải lịch sử chi tiêu billing đã xác nhận, và CloudFormation hiện **chưa** được dùng cho dự án này (toàn bộ hạ tầng được tạo tay qua AWS Console, xem [5.4](../../5-Workshop/5.4-Deployment-Guide/)). Mục "Bằng chứng và giới hạn" ở cuối bài liệt kê rõ phần nào đã xác nhận, phần nào là suy luận hợp lý, phần nào chỉ là đề xuất.
{{% /notice %}}

### 1. Vì sao triển khai một ứng dụng nhiều thành phần không phải việc một ngày

Gymini không phải một ứng dụng CRUD đơn giản. Đây là một pnpm monorepo với bảy service Node.js/TypeScript (Auth, User, Fitness, Gym, Payment, AI, Chat) cộng với một frontend React, trước đây chỉ chạy bằng Docker Compose trên một máy — không endpoint công khai, không backup, không cô lập giữa các thành phần (xem [Proposal mục 2](../../2-Proposal/#problem)).

Khoảng cách giữa "chạy được trên máy mình" và "vận hành được trên cloud" nằm ở những việc mà `docker compose up` không bao giờ phải làm: cấp phát VPC và subnet, viết IAM role cho từng service, quản lý secret thay vì file `.env`, nối các service lại với nhau khi không còn hostname chung, đặt health check, gom log, và kiểm thử lại từng phần sau khi deploy. Số lượng container trong một ứng dụng không nói lên được thời gian triển khai thật — vì phần lớn thời gian không nằm ở việc build image, mà nằm ở việc nối các thành phần managed lại với nhau cho đúng và kiểm tra lại từng bước.

### 2. Kỳ vọng ban đầu so với thực tế triển khai

Kỳ vọng ban đầu khá đơn giản: code xong → build Docker → deploy lên AWS → ứng dụng chạy, có thể trong một ngày. Thực tế triển khai Gymini đi theo một vòng lặp khác hẳn: cấp phát hạ tầng → cấu hình → deploy → kiểm thử → gỡ lỗi → deploy lại → xác nhận — lặp lại cho từng service một, trải dài từ 26/08 đến 23/09/2026 (xem [Worklog tuần 4–8](../../1-Worklog/)), tức khoảng bốn tuần, không phải một ngày.

| Khía cạnh | Kỳ vọng ban đầu | Thực tế |
|---|---|---|
| Thời gian triển khai | Khoảng một ngày | Nhiều vòng cấu hình, kiểm thử và sửa lỗi, trải dài khoảng bốn tuần |
| Hạ tầng | Cấp phát cơ bản | Nhiều thành phần phụ thuộc lẫn nhau (VPC, IAM, Secrets Manager, Aurora, SQS, EventBridge...) |
| Cấu hình | Một lần | Điều chỉnh nhiều lần, có revision phải sửa lại |
| Kiểm thử | Sau khi deploy xong | Kiểm thử liên tục theo từng service ([5.5](../../5-Workshop/5.5-Test-Validation/)) |
| Chi phí | Nằm trong credit, không nghĩ tới | Một số resource tính tiền theo giờ bất kể có dùng hay không |

"Một ngày" ở đây là kỳ vọng cá nhân lúc bắt đầu, không phải chuẩn chung cho mọi dự án.

### 3. Thách thức kỹ thuật thực tế gặp phải

**Mạng và bảo mật.** Mỗi lần thêm một service là một lần phải nối đúng security group: `lambda-sg` và `chat-sg` được phép vào `aurora-sg` ở cổng 5432, `vpce-sg` cho phép `lambda-sg` ở cổng 443 để gọi Secrets Manager và OpenSearch qua VPC endpoint, còn DB subnet không có đường ra internet ([5.2.5](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/)). Sai một chiều security group là Lambda không gọi được database mà log không nói rõ lý do.

**Triển khai container.** Chat service là nơi phát sinh lỗi cụ thể nhất: ở revision 1 của task definition, hai secret (`CHAT_DATABASE_URL`, `INTERNAL_API_SECRET`) được nhập nhầm theo kiểu **Value** thay vì **ValueFrom**, nên container nhận được *tên* secret thay vì *giá trị* kết nối, và Prisma báo lỗi `URL must start with postgresql://`. Phải tạo một revision mới dùng ValueFrom kèm đúng ARN và hậu tố JSON key (`...:CHAT_DATABASE_URL::`), rồi *Force new deployment* mới chạy được ([5.4.10](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)).

**Tích hợp database.** Bảy service dùng chung một cluster Aurora nhưng mỗi service một logical database và một secret riêng. Lambda cache secret database theo execution environment đang "ấm", nên sau khi đổi mật khẩu Aurora, cách buộc Lambda đọc credential mới không phải là đợi, mà là sửa một biến môi trường vô hại (`DEPLOY_REVISION`) chỉ để ép AWS tạo execution environment mới ([5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/)).

**Cấu hình môi trường.** Mỗi service có bộ biến môi trường và secret riêng, các migration Lambda được tạo ra dùng một lần rồi xoá sau khi chạy xong, và mỗi lần sửa cấu hình là một revision mới của task definition hoặc một lần cập nhật environment variables của function.

**Gỡ lỗi và deploy lại.** Khuôn mẫu lặp lại nhiều nhất là: đọc *Stopped reason* và *Events* của service thay vì tạo lại service, cập nhật task definition, rồi *Force new deployment* — xác nhận lại trạng thái *Running 1/1*, *Healthy* trước khi coi là xong ([5.4.10, bước 23](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)).

### 4. Credit AWS tiêu hao nhanh hơn dự kiến

Free Tier, credit khuyến mãi và pay-as-you-go là ba thứ khác nhau: Free Tier là hạn mức miễn phí cố định theo dịch vụ; credit khuyến mãi là một khoản tiền ảo trừ dần vào hoá đơn, có hạn sử dụng; còn pay-as-you-go là cách AWS tính tiền mặc định cho mọi thứ vượt ra ngoài hai khoản trên. Có credit không có nghĩa là hạ tầng miễn phí — nó chỉ trì hoãn thời điểm phải trả tiền thật, và một khi cạn thì hoá đơn tính theo giá niêm yết.

Điều dễ bị bỏ qua khi đang mải cấu hình và sửa lỗi: phần lớn các resource trong kiến trúc này tính tiền theo mức dùng (Lambda, API Gateway, SQS, Bedrock theo token), nhưng một số lại tính theo **giờ chạy**, bất kể có request nào hay không. Theo ước tính kiến trúc ở [Proposal mục 8](../../2-Proposal/#budget), các khoản cố định đó gồm: NAT Gateway (~43 USD/tháng), Aurora ở mức capacity tối thiểu (~45–60 USD/tháng), Fargate task của Chat (~22 USD/tháng), Application Load Balancer (~20 USD/tháng), hai interface VPC endpoint (~30–40 USD/tháng) và các địa chỉ IPv4 public (~11 USD/tháng) — tổng khoảng **190–230 USD/tháng nếu để chạy 24/7**, hoặc **60–90 USD/tháng nếu áp dụng "chế độ ngủ"** (xem thêm [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)). Đây là số liệu kiến trúc đã công bố trong báo cáo, không phải một dòng billing đã xác nhận.

Từ con số đó có thể suy ra một cơ chế hoàn toàn hợp lý về mặt kỹ thuật: nếu các resource cố định này bị để chạy liên tục suốt nhiều tuần trong lúc vẫn đang deploy từng service, debug, deploy lại — như đúng nhịp độ triển khai thật của Gymini ở mục 2 — thì riêng phần chi phí "chạy không" đó cũng đủ cộng dồn nhanh hơn trực giác ban đầu, nhất là khi chưa có cảnh báo chi tiêu nào được bật. Đây là một **yếu tố có khả năng góp phần** (possible contributing factor), không phải một sự cố đã xảy ra và được xác nhận bằng số liệu billing cụ thể trong dự án này.

### 5. Phân tích nguyên nhân gốc rễ

| Vấn đề | Nguyên nhân có thể | Tác động | Bằng chứng | Cải thiện đề xuất |
|---|---|---|---|---|
| Triển khai hoàn toàn thủ công qua Console | Chưa xây dựng CI/CD | Mỗi thay đổi tốn thao tác tay, khó lặp lại giống hệt lần trước | [5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/) ghi "No CI/CD yet" | Infrastructure as Code (CloudFormation hoặc Terraform) + pipeline CI/CD |
| Hạ tầng cố định chạy 24/7 | Chưa có lịch tạm dừng tự động ngoài giờ dùng | Tốn chi phí cả khi không ai dùng hệ thống | [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/) ghi "DEV sleep strategy — Planned, not yet automated" | Tự động đưa Aurora về 0 ACU, Chat service về 0 task, xoá NAT Gateway ngoài giờ test |
| Chưa có cảnh báo chi tiêu | Chưa cấu hình AWS Budgets | Phát hiện chi tiêu bất thường chậm, dễ bị động | [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/) ghi "AWS Budgets alert — Planned" | Bật AWS Budgets kèm thông báo qua email/SNS |
| Chưa có CloudWatch Alarm | Chưa cấu hình | Lỗi, throttle, DLQ đầy không được báo chủ động | [5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/) ghi "No CloudWatch alarms yet" | Alarm cho lỗi/throttle Lambda, độ sâu DLQ, capacity Aurora, health của Chat target |
| Secret nhập sai kiểu giá trị trong task definition | Thao tác trên console dễ nhầm, không có bước review trước khi áp dụng | Container chạy lỗi runtime, phải tạo revision mới để sửa | [5.4.10 — Lesson learned](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/) | Review thay đổi hạ tầng qua Change Set (CloudFormation) hoặc pull request (Terraform) trước khi áp dụng |

Bảng trên cố tình tách nguyên nhân thao tác/vận hành (chưa tự động hoá, chưa có cảnh báo) ra khỏi chi phí vận hành bình thường của các dịch vụ AWS — không phải lỗi deploy nào cũng đồng nghĩa với việc phát sinh thêm chi phí, và không phải khoản chi phí cố định nào cũng là một "lỗi".

### 6. AWS CloudFormation như một giải pháp đề xuất

Infrastructure as Code (IaC) giải quyết đúng loại vấn đề đã gặp ở trên: thay vì nhớ và lặp lại hàng chục bước trên console, hạ tầng được mô tả bằng file, có thể xem lại, review trước khi áp dụng, và tạo lại giống hệt ở môi trường khác.

[AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) quản lý hạ tầng theo **stack**: một template (YAML/JSON) mô tả resource cần tạo, nhận **parameter** để tái dùng cho nhiều môi trường, trả về **output** để các stack khác tham chiếu, và hỗ trợ **Change Set** — xem trước chính xác resource nào sẽ được tạo, sửa hay xoá trước khi áp dụng thật ([tài liệu Change Set](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)). CloudFormation cũng hỗ trợ drift detection để phát hiện khi ai đó sửa resource trực tiếp ngoài stack.

**Làm rõ về mặt kỹ thuật:** CloudFormation **không** tự động giảm chi phí — nó chỉ giúp quản lý hạ tầng dưới dạng code và giúp việc dọn dẹp các resource do stack quản lý dễ và nhất quán hơn. Xoá một stack ([tài liệu xoá stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-delete-stack.html)) cũng **không đảm bảo** mọi resource liên quan biến mất — retention policy, snapshot, resource tạo ngoài stack, hoặc một lần xoá thất bại đều có thể để lại thứ cần dọn thủ công.

Cấu trúc thư mục minh hoạ cho hướng này:

```text
infrastructure/
├── cloudformation/
│   ├── network.yaml
│   ├── security.yaml
│   ├── database.yaml
│   ├── application.yaml
│   └── monitoring.yaml
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── README.md
```

Thư mục trên chỉ mang tính minh hoạ — repo hiện tại chưa có thư mục `infrastructure/`, vì toàn bộ hạ tầng được tạo tay qua console như mô tả ở [5.4](../../5-Workshop/5.4-Deployment-Guide/). Sơ đồ kiến trúc mục tiêu gần nhất của dự án ([Proposal mục 3](../../2-Proposal/#architecture)) thật ra nhắc tới Terraform như một lựa chọn IaC; CloudFormation là một lựa chọn tương đương, gắn trực tiếp với AWS mà không cần công cụ ngoài.

{{< mermaid >}}
graph LR
    GIT["Git repository"] --> TPL["CloudFormation templates"]
    TPL --> CS["Change sets<br/>review before apply"]
    CS --> CF["AWS CloudFormation"]
    CF --> DEV["Stack: Development"]
    CF --> STG["Stack: Staging"]
    CF --> PRD["Stack: Production"]
{{< /mermaid >}}

*Hình 3 — Vòng đời quản lý hạ tầng bằng CloudFormation: thay đổi được review qua Change Set trước khi áp dụng, và mỗi môi trường là một stack riêng.*

### 7. Tách môi trường Dev / Staging / Production

Hiện tại dự án chỉ có **một** môi trường DEV duy nhất ([5.5.5](../../5-Workshop/5.5-Test-Validation/5.5.5-Status-Open-Items/)), nên phần này là đề xuất, chưa phải hiện trạng.

- **Development** — hạ tầng tối thiểu khi kỹ thuật cho phép, cấu hình tiết kiệm chi phí, resource tạm thời và được dọn dẹp có kiểm soát.
- **Staging** — kiểm thử tích hợp, xác nhận quy trình deploy, cấu hình gần giống production khi cần, nhưng vẫn kiểm soát để tránh phát sinh chi phí không cần thiết.
- **Production** — ưu tiên độ tin cậy, bảo mật, khả năng mở rộng, giám sát và bảo vệ dữ liệu.

Ba môi trường giống hệt nhau về cấu hình sẽ tốn kém không cần thiết, nhưng hạ giá cấu hình đến mức ảnh hưởng chức năng, bảo mật hay độ tin cậy của việc kiểm thử cũng không phải là tối ưu — đánh đổi cần có chủ đích, không phải cắt giảm tuỳ tiện.

### 8. Chiến lược tối ưu chi phí

- **Khả năng quan sát chi phí** — AWS Cost Explorer, AWS Budgets kèm cảnh báo, cost allocation tag theo service (cả hai hiện đều là việc còn mở, xem mục 5).
- **Vòng đời hạ tầng** — quy ước đặt tên nhất quán đã có sẵn (`fitness-assistant-dev-<service>-...`) giúp lọc resource theo chủ sở hữu; cần thêm quy trình xoá theo stack và bước xác nhận đã dọn sạch, như thứ tự dọn dẹp đầy đủ ở [5.7](../../5-Workshop/5.7-Cleanup/).
- **Right-sizing** — các lựa chọn đã áp dụng: Aurora Serverless v2 với sàn 0.5 ACU, Lambda 1024 MB, OpenSearch Serverless 0–2 OCU, Fargate 0.5 vCPU / 1 GB cho Chat ([5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)).
- **Tự động hoá** — tích hợp IaC vào CI/CD (chưa có), tự tắt resource DEV ngoài giờ khi kỹ thuật hỗ trợ, quy trình dọn dẹp khi một lần deploy thất bại.
- **Quản trị (governance)** — ghi rõ ai sở hữu chi phí nào, checklist trước khi deploy, quy ước đặt tên theo môi trường, ngưỡng cảnh báo ngân sách, rà soát billing định kỳ.

Cảnh báo chi phí (budget alert) không tức thời tuyệt đối — nên xem đó là một tín hiệu để kiểm tra sớm, không phải một giới hạn chi tiêu cứng không thể vượt qua.

### 9. So sánh hiện trạng và mục tiêu đề xuất

| Tiêu chí | Hiện trạng (đã xác nhận) | Mục tiêu đề xuất |
|---|---|---|
| Cấp phát hạ tầng | Thủ công qua AWS Console ([5.4](../../5-Workshop/5.4-Deployment-Guide/)) | Infrastructure as Code |
| Cấu hình môi trường | Từng bước ghi lại, không tham số hoá | Cấu hình theo tham số, tái dùng được giữa các môi trường |
| Theo dõi resource | Kiểm tra thủ công theo quy ước đặt tên | Theo dõi theo stack, kèm resource tag |
| Deploy lại | Force new deployment, gỡ lỗi lặp lại ([5.4.10](../../5-Workshop/5.4-Deployment-Guide/5.4.10-Chat-Service-ECS/)) | Cập nhật có kiểm soát qua Change Set |
| Giám sát chi phí | Chưa có Budgets hay Alarm ([5.2.6](../../5-Workshop/5.2-Architecture-Description/5.2.6-Scalability-Operations/), [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)) | Cảnh báo chủ động và rà soát định kỳ |
| Dọn dẹp | Có checklist dọn dẹp, chưa chạy thật ([5.7](../../5-Workshop/5.7-Cleanup/)) | Dọn dẹp theo stack, có bước xác nhận |
| Khả năng lặp lại | Giới hạn, phụ thuộc người thao tác | Hạ tầng được quản lý bằng version control |

Đây là so sánh giữa **hiện trạng đã xác nhận** và **mục tiêu đề xuất**, không phải kết quả đo được của một lần chuyển đổi đã hoàn tất.

### 10. Bài học rút ra

1. Triển khai lên cloud là một quá trình kỹ thuật, không phải bước cuối cùng sau khi viết xong code.
2. Chi phí hạ tầng cần được ước tính trước khi cấp phát, không phải phát hiện sau khi hoá đơn tới — bảng ngân sách ở Proposal mục 8 nên có từ đầu, không phải viết lại sau.
3. Môi trường development nên được thiết kế đúng theo nhu cầu vận hành thật của nó, không nhất thiết phải giống production.
4. Quản lý hạ tầng tự động giúp giảm sai lệch cấu hình — lỗi secret Value/ValueFrom ở Chat service là ví dụ cụ thể cho việc thao tác tay dễ sai ở đâu.
5. Quản lý vòng đời resource quan trọng không kém việc cấp phát ban đầu — có resource mà không có kế hoạch dọn dẹp thì sớm muộn cũng tốn thêm chi phí.
6. Credit miễn phí cần được tính toán như một ngân sách có giới hạn, không phải một khoản vô hạn.
7. Sẵn sàng triển khai bao gồm cả khả năng quan sát vận hành và chi phí, không chỉ ứng dụng chạy được.
8. Infrastructure as Code góp phần vào khả năng bảo trì và khả năng lặp lại của hệ thống về lâu dài.

### 11. Lộ trình cải tiến

**Giai đoạn 1 — Rà soát hạ tầng** *(một phần đã có)*: kiểm kê resource theo quy ước đặt tên hiện có, ước tính chi phí đã công bố ở Proposal mục 8, rà soát các gap bảo mật đã ghi nhận ở [5.2.5](../../5-Workshop/5.2-Architecture-Description/5.2.5-Security-IAM/) — còn thiếu: rà soát billing thực tế theo thời gian.

**Giai đoạn 2 — Áp dụng CloudFormation** *(chưa bắt đầu)*: viết template cho từng nhóm resource (network, security, database, application, monitoring), tham số hoá theo môi trường, kiểm thử deploy và xoá stack.

**Giai đoạn 3 — Quản trị chi phí** *(chưa bắt đầu, có nền tảng)*: bật AWS Budgets, đưa resource tag vào quy ước đặt tên sẵn có, viết chính sách vòng đời cho môi trường non-production, rà soát chi phí định kỳ.

**Giai đoạn 4 — Tự động hoá triển khai** *(chưa bắt đầu)*: đưa IaC vào CI/CD, dùng Change Set để review hạ tầng trước khi áp dụng, thêm bước xác nhận sau deploy, xây quy trình rollback và dọn dẹp khi deploy thất bại.

### Sơ đồ minh hoạ

{{< mermaid >}}
graph LR
    A["Application code"] --> B["Docker build"]
    B --> C["Deploy to AWS"]
    C --> D{"Health check"}
    D -- fail --> E["Debug"]
    E --> F["Fix configuration"]
    F --> G["Redeploy"]
    G --> D
    D -- pass --> H["Monitor"]
{{< /mermaid >}}

*Hình 1 — Vòng lặp gỡ lỗi khi triển khai: mỗi lần health check thất bại kéo theo một vòng debug, sửa cấu hình và deploy lại, và mỗi vòng đều tốn thời gian kỹ sư lẫn thời gian resource đang chạy.*

{{< mermaid >}}
graph LR
    subgraph AlwaysOn ["Hạ tầng chạy 24/7, không phụ thuộc lưu lượng — minh hoạ khái niệm"]
        NAT["NAT Gateway"]
        ALB["Chat ALB"]
        FG["Fargate task"]
        AU["Aurora, capacity tối thiểu"]
        VE["VPC interface endpoints"]
        IP["Địa chỉ IPv4 public"]
    end
    NAT --> SUM["Chi phí hằng tháng<br/>xem Proposal mục 8"]
    ALB --> SUM
    FG --> SUM
    AU --> SUM
    VE --> SUM
    IP --> SUM
    SUM -. nếu chạy liên tục nhiều tuần .-> CREDIT["Credit miễn phí/khuyến mãi<br/>có thể cạn nhanh hơn dự kiến"]
{{< /mermaid >}}

*Hình 2 — Sơ đồ khái niệm (không phải biểu đồ billing thật) cho thấy vì sao các resource tính phí theo giờ có thể cộng dồn nhanh nếu bị để chạy liên tục trong lúc vẫn đang cấu hình và kiểm thử.*

### Bằng chứng và giới hạn

- **Đã xác nhận trong báo cáo:** kiến trúc 7 service + AI + Chat; triển khai thủ công qua console, trải dài 26/08–23/09/2026; lỗi secret Value/ValueFrom của Chat service và cách sửa; cơ chế cache secret của Lambda và biến `DEPLOY_REVISION`; CI/CD và CloudWatch Alarm chưa có; ước tính ngân sách ~190–230 USD/tháng (24/7) hoặc ~60–90 USD/tháng (chế độ ngủ); thứ tự dọn dẹp đầy đủ ở 5.7 chưa được chạy thật.
- **Kinh nghiệm được trình bày (không có log/billing kèm theo trong báo cáo này):** nhịp độ chung "deploy — kiểm thử — sửa lỗi — deploy lại" qua từng tuần.
- **Yếu tố có khả năng góp phần, chưa xác nhận bằng số liệu billing:** việc hạ tầng cố định chạy liên tục trong lúc debug làm credit cạn nhanh hơn dự kiến.
- **Cải tiến đã đề xuất, chưa triển khai:** toàn bộ phần CloudFormation, tách môi trường Dev/Staging/Production, AWS Budgets, CloudWatch Alarm, lịch tự tắt hạ tầng ngoài giờ.
- **Cải tiến đã áp dụng thật (không liên quan CloudFormation):** Lambda trả tiền theo lượt gọi, Aurora Serverless v2 với sàn capacity thấp, OpenSearch Serverless 0–2 OCU, một NAT Gateway dùng chung, Fargate right-size cho Chat — xem [5.2.7](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/).

### Tài liệu tham khảo

- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)
- [Change sets trong CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets.html)
- [Xoá stack trong CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-delete-stack.html)
- [AWS Well-Architected Framework — Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
- [AWS Cost Management documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/what-is-costmanagement.html)
- [Proposal mục 8 — Ước tính ngân sách](../../2-Proposal/#budget)
- [Workshop 5.2.7 — Cost Optimization and Clean-up](../../5-Workshop/5.2-Architecture-Description/5.2.7-Cost-Optimization-Cleanup/)
- [Workshop 5.7 — Clean-up](../../5-Workshop/5.7-Cleanup/)
