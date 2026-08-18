---
title: "Blog 1: Từ Docker Local đến Amazon ECR"
date: 2026-08-15
weight: 1
chapter: false
pre: " <b> 3.1. </b> "
---

## TỪ DOCKER LOCAL ĐẾN AMAZON ECR – BƯỚC CHUẨN BỊ TRƯỚC KHI DEPLOY HỆ THỐNG LÊN ECS

**Ngày đăng:** 22/08/2026

**URL bài viết:** https://www.facebook.com/share/p/1F8v6Qye3F/

**Hashtags:** #FCAJ #AWS #Docker #AmazonECR #AmazonECS #CloudComputing #FitnessAssistant

---

### Giới thiệu

Trong quá trình tìm hiểu các hướng deploy cho project Fitness Assistant lên cloud, mình có đọc được một bài viết của AWS có tên **"Automated software delivery using Docker Compose and Amazon ECS"**.

Ban đầu mình tìm bài này vì muốn hiểu một hệ thống đang chạy bằng Docker trên máy local thì khi đưa lên AWS sẽ được triển khai như thế nào, đặc biệt là khi sử dụng Amazon ECS.

Lúc đầu mình nghĩ flow sẽ khá đơn giản: có Docker rồi thì chỉ cần đưa các container lên ECS chạy là được. Nhưng khi đọc kỹ hơn, mình nhận ra trước khi đi tới ECS còn có một bước khá quan trọng mà trước đây mình chưa thực sự để ý nhiều, đó là **quản lý Docker image**.

### Bài toán thực tế

Fitness Assistant hiện tại không chỉ có một ứng dụng duy nhất. Project đang được tách thành nhiều thành phần như:
- frontend
- gateway
- auth-service
- user-service
- fitness-service
- ai-service
- payment-service
- gym-service

Ở môi trường local, mình có thể chạy các service và kiểm tra chúng tương đối dễ dàng. Nhưng khi nghĩ đến việc đưa hệ thống lên AWS thì mình bắt đầu gặp một câu hỏi:

**Nếu các service đang nằm trên laptop của mình thì ECS sẽ lấy ứng dụng ở đâu để chạy?**

Một cách đơn giản là tạo EC2, SSH vào máy, clone source code về, cài Docker rồi build và chạy tất cả container trực tiếp trên đó. Cách này hoàn toàn có thể làm được.

Nhưng mình nhận ra nếu làm như vậy thì server production lại phải đảm nhiệm khá nhiều việc. Server vừa chứa source code, vừa phải build application, vừa lưu Docker image, vừa chạy container.

### Mục tiêu của phần thử nghiệm

Ở bước hiện tại, mục tiêu của mình chưa phải là deploy toàn bộ Fitness Assistant lên Amazon ECS. Mình muốn giải quyết một bước nhỏ hơn trước:

**Làm thế nào để mỗi service của project được đóng gói thành một Docker image hoàn chỉnh và lưu trên AWS?**

Flow mình đang thử nghiệm là:

```
Source code → Dockerfile → docker build → Local Docker Image 
→ docker tag → docker push → Amazon ECR
```

Qua phần này mình muốn kiểm tra một số vấn đề:
- Dockerfile của từng service có build được hay không?
- Image sau khi build có thực sự tồn tại trên local không?
- Kích thước của từng image là bao nhiêu?
- Image nên được đặt version như thế nào?
- Làm thế nào để đưa image từ máy local lên Amazon ECR?
- Sau khi push, làm thế nào để biết image trên ECR đúng là image mình vừa build?

### Tổng quan kiến trúc

Sau khi tách bài toán ra, mình bắt đầu nhìn rõ hơn vai trò của từng thành phần:

```
Developer
    ↓
Source Code
    ↓
Dockerfile
    ↓
Docker Build
    ↓
Docker Image
    ↓
Amazon ECR
    ↓
Amazon ECS
    ↓
Running Container
```

**Amazon ECR không phải nơi chạy ứng dụng.** ECR giống như một kho chứa các phiên bản của container image.

Ví dụ Fitness Assistant có thể có:
- `fitness-assistant/frontend:v1.0.0`
- `fitness-assistant/auth-service:v1.0.0`
- `fitness-assistant/user-service:v1.0.0`

Như vậy việc build application và việc chạy application được tách thành hai phần rõ ràng hơn.

### Flow thử nghiệm Docker và Amazon ECR

Đầu tiên mình chuẩn bị Dockerfile production cho từng service. Sau đó chạy:

```bash
docker build
```

để tạo image trên máy local. Sau khi build xong, mình sử dụng:

```bash
docker images
```

để kiểm tra image có thực sự được tạo ra hay không và kích thước của từng image là bao nhiêu.

Đây là lúc mình nhận ra một điều khá đơn giản nhưng trước đây mình ít để ý: **Dòng "build successful" chưa có nghĩa image đó đã phù hợp để đưa lên production.**

Ví dụ với frontend, một số biến môi trường của Vite được đưa vào ngay trong quá trình build. Nếu API URL lúc build vẫn là `localhost` thì Docker vẫn có thể build image thành công. Nhưng image đó rõ ràng chưa thể xem là image phù hợp để chạy ở môi trường AWS.

Sau khi kiểm tra image local, mình tạo Private Repository tương ứng trên Amazon ECR. Tiếp theo là:

```bash
docker login
```

để Docker có quyền truy cập ECR. Sau đó mình dùng:

```bash
docker tag
```

để gắn ECR Repository URI cho image. Cuối cùng:

```bash
docker push
```

để đưa image lên ECR.

Sau khi push xong, mình không chỉ dừng ở việc nhìn thấy terminal báo thành công mà tiếp tục kiểm tra trực tiếp trên AWS Console. Ở đó mình có thể xem được:
- Image tag
- Image digest
- Image size
- Thời gian image được push

### Tại sao không đưa source code thẳng lên EC2?

Đây cũng là câu hỏi mình đặt ra trong quá trình tìm hiểu. Nếu EC2 cũng là một máy chủ thì tại sao không đơn giản tạo một EC2 instance, cài Docker rồi chạy Fitness Assistant trực tiếp trên đó?

Theo mình hiểu thì cách này không sai. Với một project nhỏ, một server và lượng người dùng chưa lớn thì hoàn toàn có thể:

```
Source code → EC2 → Docker → Application
```

Nhưng với Fitness Assistant hiện đang có nhiều service thì mình muốn tách trách nhiệm rõ hơn. Nếu build trực tiếp trên EC2 thì EC2 vừa là nơi nhận source code, vừa build image và vừa chạy container.

Còn với hướng mình đang tìm hiểu:

```
Source code → Docker image → Amazon ECR → Amazon ECS
```

thì mỗi phần có nhiệm vụ riêng:
- Docker đóng gói application
- ECR lưu image
- ECS quản lý container

### Điều mình thấy hay nhất trong quá trình này

Điều mình thấy hay nhất không phải là câu lệnh `docker push`. Mà là cách mình bắt đầu nhìn Docker image khác đi.

Trước đây mình chủ yếu dùng Docker để:
- build image
- run container
- test application trên local

Nhưng khi đưa ECR vào flow, **Docker image bắt đầu giống một phiên bản đóng gói của application hơn**.

Ví dụ:
- `auth-service:v1.0.0`
- `auth-service:v1.0.1`

Hai phiên bản này có thể cùng tồn tại trên ECR. Điều đó giúp mình biết rõ hệ thống đang có những phiên bản nào thay vì mỗi lần update lại build đè lên image cũ.

### Một số lưu ý mình rút ra khi test

1. **Không nên xem một Docker image là hoàn thành chỉ vì `docker build` không báo lỗi.** Cần kiểm tra lại cấu hình bên trong image.

2. **Không nên đưa các file nhạy cảm vào image.** Những file như `.env`, credentials, API Key không nên xuất hiện bên trong Docker image. Vì vậy `.dockerignore` cần được kiểm tra.

3. **Version image.** Nếu tất cả image đều dùng `latest` thì sau một thời gian sẽ khá khó biết image nào tương ứng với phiên bản source code nào.

4. **Phải xác minh lại image sau khi push.** Không nên chỉ thấy `docker push` thành công rồi kết luận toàn bộ bài test đã PASS.

### Góc nhìn cá nhân

Trước khi đọc bài viết của AWS, mình nghĩ khá đơn giản rằng nếu đã container hóa được application thì bước tiếp theo chỉ là tìm một nơi trên AWS để chạy container.

Nhưng sau khi phân tích flow của bài viết, mình nhận ra **giữa source code và một container đang chạy trên cloud còn có một bước khá quan trọng là quản lý container image**.

Đây cũng là lý do mình chưa muốn đi thẳng tới ECS. Nếu triển khai ngay cả frontend, gateway và nhiều backend service lên ECS trong khi Dockerfile vẫn còn vấn đề thì lúc đó mình sẽ phải debug cùng lúc Docker, ECR, ECS, networking, load balancer và nhiều thành phần khác.

Thay vào đó mình chọn làm từng bước:
1. Đầu tiên đảm bảo: `Source code → Docker image` hoạt động đúng
2. Sau đó: `Docker image → Amazon ECR` hoạt động đúng
3. Khi hai phần này ổn định, mới tiếp tục: `Amazon ECR → Amazon ECS`

### Kết luận

Sau phần thử nghiệm này, điều mình hiểu rõ hơn không chỉ là cách sử dụng Amazon ECR. Quan trọng hơn là mình bắt đầu thấy rõ vai trò của Docker image trong quá trình đưa application từ local lên cloud.

- **Docker** giúp mình đóng gói application
- **Amazon ECR** giúp mình lưu trữ và quản lý các image đó
- **Amazon ECS** sẽ là bước tiếp theo để sử dụng những image này và vận hành các container trên AWS

Điều mình rút ra nhiều nhất từ quá trình này là **không nên cố triển khai toàn bộ kiến trúc ngay từ đầu**. Tách từng vấn đề ra, test từng bước và hiểu rõ vai trò của từng dịch vụ giúp mình dễ xác định lỗi hơn và cũng hiểu kiến trúc AWS rõ hơn.

Hiện tại mình đang tiếp tục hoàn thiện Docker image của các service trong Fitness Assistant và kiểm tra chúng trên Amazon ECR. Sau khi phần này ổn định, bước tiếp theo của mình sẽ là nghiên cứu cách các image trong ECR được sử dụng để triển khai các service lên Amazon ECS.

### Link bài viết tham khảo

- **AWS Containers Blog** – Automated software delivery using Docker Compose and Amazon ECS: https://aws.amazon.com/blogs/containers/automated-software-delivery-using-docker-compose-and-amazon-ecs
- **Amazon ECR Documentation**: https://docs.aws.amazon.com/ecr/
- **Amazon ECS Documentation**: https://docs.aws.amazon.com/ecs/

---

**Chia sẻ trên Facebook:** https://www.facebook.com/share/p/1F8v6Qye3F/
