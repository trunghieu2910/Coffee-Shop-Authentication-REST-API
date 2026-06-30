# ☕ Coffee Shop API (RESTful & Stateless)

Dự án Hệ thống Backend API quản lý Cửa hàng Cà phê, được phát triển với kiến trúc **100% RESTful API**, bảo mật không trạng thái (Stateless) bằng **JWT (JSON Web Token)**, hỗ trợ xác thực 2 lớp qua Email (OTP) và đăng nhập nhanh bằng Google OAuth2.

## 🚀 Tính năng nổi bật (Features)

*   **Bảo mật Stateless (JWT):** Xóa bỏ hoàn toàn HttpSession truyền thống, mọi tương tác với hệ thống sau khi đăng nhập đều được bảo vệ bởi chuẩn mã hóa JWT.
*   **Authentication & Authorization:** 
    *   Đăng ký tài khoản (Bảo vệ bằng mã xác thực OTP gửi qua Email).
    *   Đăng nhập hệ thống (Trả về Bearer Token).
    *   Quên mật khẩu (Gửi OTP, giới hạn số lần gửi trong bộ nhớ Cache).
    *   Đăng xuất (Client-side token disposal).
*   **Google OAuth2 (Token Exchange):** Đăng nhập 1 chạm với Google. Khách hàng sử dụng Client SDK lấy `idToken` của Google, Backend tự động xác thực và cấp phát JWT nội bộ, tự động tạo tài khoản cho người dùng mới.
*   **Quản lý tài khoản cá nhân (Profile):** Xem thông tin, đổi mật khẩu, bổ sung thông tin (số điện thoại, mật khẩu) cho tài khoản Google, upload Avatar.
*   **Bộ đệm thông minh (Cache):** Sử dụng cấu trúc `ConcurrentHashMap` trên RAM để lưu trữ trạng thái người dùng (OTP, số lần gửi lại) trong mô hình Stateless.

## 🛠 Công nghệ sử dụng (Tech Stack)

*   **Ngôn ngữ:** Java 21
*   **Framework chính:** Spring Boot 3.5.x
*   **Bảo mật:** Spring Security 6, JJWT (io.jsonwebtoken), Google API Client
*   **Cơ sở dữ liệu:** Microsoft SQL Server
*   **ORM:** Spring Data JPA / Hibernate
*   **Build Tool:** Maven

## 💻 Hướng dẫn cài đặt (Installation & Setup)

### Yêu cầu hệ thống (Prerequisites)
*   [JDK 21](https://jdk.java.net/21/) trở lên.
*   [Maven](https://maven.apache.org/) (Nếu không dùng Wrapper).
*   Microsoft SQL Server đang chạy ở port `1433`.
*   Tài khoản Gmail hỗ trợ gửi SMTP (Mật khẩu ứng dụng).

### Các bước chạy dự án

1. **Clone mã nguồn về máy:**
   ```bash
   git clone https://github.com/your-username/your-repo-name.git
   cd your-repo-name
   ```

2. **Cấu hình Cơ sở dữ liệu & Email & Google:**
   Mở file `src/main/resources/application.properties` và cấu hình lại thông số SQL Server, Email và Google Client Credentials của bạn:
   ```properties
   spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=coffee_shop;encrypt=true;trustServerCertificate=true
   spring.datasource.username=sa
   spring.datasource.password=your_db_password

   # Cấu hình SMTP (Email)
   spring.mail.username=your_email@gmail.com
   spring.mail.password=your_app_password
   
   # Cấu hình Google OAuth2 (Lấy từ Google Cloud Console)
   GOOGLE_CLIENT_ID=your_google_client_id_here
   GOOGLE_CLIENT_SECRET=your_google_client_secret_here
   ```
   *Lưu ý: Để test tính năng Google Đăng nhập, Frontend/Client của bạn cần tích hợp Google SDK bằng `GOOGLE_CLIENT_ID` trên để lấy `idToken` truyền xuống Backend.*

3. **Biên dịch và chạy ứng dụng:**
   Bạn có thể chạy dự án thông qua Maven:
   ```bash
   mvn clean compile
   mvn spring-boot:run
   ```
   *Ứng dụng sẽ khởi chạy tại: `http://localhost:8080`*

## 📚 Tài liệu API (API Documentation)

Để việc kiểm thử (Testing) trở nên dễ dàng nhất cho đội ngũ Frontend, dự án đã đóng gói toàn bộ API thành một file **Postman Collection**.

*   File Collection: [`Project_API_Collection.json`](./Project_API_Collection.json)
*   **Cách dùng:** Mở Postman -> Chọn Import -> Kéo thả file JSON này vào. Toàn bộ các API từ Đăng nhập, Đăng ký, Cập nhật Avatar... sẽ xuất hiện với JSON Body mẫu được điền sẵn cực kì dễ hiểu.

## 🤝 Tác giả (Contributors)
*   **Nguyễn Trung Hiếu** - *Phát triển tính năng & Chuyển đổi kiến trúc REST API*

---
*If you find this project useful, please give it a ⭐ on GitHub!*