# Chạy và kiểm tra Smart Agri-Tracker

## Build khác với chạy ứng dụng

`mvnw.cmd package` biên dịch, kiểm thử và tạo file JAR rồi kết thúc. Đây là hành vi bình thường.
Để mở web, chạy `SmatBackendApplication` trong IntelliJ, `mvnw.cmd spring-boot:run`,
hoặc `java -jar target/smat-backend-0.0.1-SNAPSHOT.jar`.
Ứng dụng chạy thành công sẽ ghi `Started SmatBackendApplication` và tiếp tục giữ tiến trình.

## Môi trường

- Project dùng Java 17 và Spring Boot 4.1.1. Đặt Project SDK, Maven Runner JRE và Run Configuration JRE cùng Java 17.
- PostgreSQL phải đang chạy; database hiện được cấu hình là `smat_dev`, tài khoản `smat_app`, cổng 5432.
- Biến môi trường trong IntelliJ không tự truyền sang cửa sổ PowerShell khác. Khi chạy bằng terminal, phải thiết lập chúng cho terminal đó.
- `SPRING_PROFILES_ACTIVE=dev` mở giao diện và API phục vụ phát triển. Trong profile này, server chỉ lắng nghe `127.0.0.1` vì các API `/api/v1/dev/**` chưa yêu cầu đăng nhập.
- `SMAT_DB_PASSWORD`: mật khẩu thật của tài khoản PostgreSQL, không phải mật khẩu Admin web.
- `SMAT_JWT_SECRET`: chuỗi Base64 giải mã ra ít nhất 32 byte ngẫu nhiên; không đặt khóa vào ô profile.
- `SMAT_BOOTSTRAP_ENABLED=false` cho những lần chạy thông thường.

Không ghi mật khẩu/khóa vào mã nguồn, ảnh chụp, log hoặc tài liệu. Run Configuration chứa thông tin cục bộ nhạy cảm; không chia sẻ `.idea/workspace.xml`.
Giữ ổn định khóa JWT giữa các lần chạy. Đổi khóa sẽ làm token đã cấp trước đó không còn hợp lệ.

## Trình tự chạy

1. Mở project `F:\SMAT\backend\smat-backend` và chờ Maven nạp xong.
2. Chọn đúng Run Configuration cho `com.smat.backend.SmatBackendApplication` và kiểm tra các biến trên.
3. Dừng phiên backend cũ nếu đang dùng cổng 8080; chỉ chạy một phiên trên cổng này.
4. Chạy ứng dụng, chờ dòng `Started SmatBackendApplication`.
5. Mở `http://127.0.0.1:8080/admin-smat.html`. Có thể cần tải lại trang để bỏ JavaScript cũ trong bộ nhớ đệm.

## Bootstrap Admin lần đầu

Bootstrap chỉ chạy trong profile `dev` khi bật `SMAT_BOOTSTRAP_ENABLED=true`.
Cần thiết lập thêm:

- `SMAT_BOOTSTRAP_USERNAME`: tên đăng nhập mới, tối đa 60 ký tự, không chỉ gồm khoảng trắng.
- `SMAT_BOOTSTRAP_PASSWORD`: mật khẩu riêng, ít nhất 12 ký tự; BCrypt có giới hạn 72 byte UTF-8.
- `SMAT_BOOTSTRAP_ORGANIZATION_ID`: ID của tổ chức đang `ACTIVE` đã tồn tại trong database.

Bootstrap tạo user với BCrypt và một membership `ADMIN` trong cùng transaction.
Nó không tự tạo organization. Nếu username đã tồn tại, nó chủ động báo lỗi, không ghi đè tài khoản.
Sau khi tạo thành công, đặt `SMAT_BOOTSTRAP_ENABLED=false` và bỏ các biến mật khẩu bootstrap trước khi chạy lại.
Đợt kiểm tra chương trình không tự tạo Admin hay thay đổi dữ liệu thật.

## API xác thực

- `POST /api/v1/auth/login`: JSON gồm `username`, `password`; thành công trả Bearer token.
- `GET /api/v1/auth/me`: gửi header `Authorization: Bearer <token>`; trả hồ sơ và membership còn hoạt động trong tổ chức đang hoạt động, không trả password hash.
- `GET /api/v1/admin/access-test?organizationId=<id>`: cần user còn hoạt động, organization còn hoạt động và membership `ADMIN` còn hoạt động đúng organization đó.
- `400`: request sai định dạng/thiếu trường. `401`: thiếu/sai token hoặc sai thông tin đăng nhập. `403`: đã xác thực nhưng không đủ quyền.

Trang Admin hiện dùng các API phát triển; nó chưa phải giao diện đăng nhập dành cho production.
Không bật profile `dev` trên máy chủ công khai và không đổi địa chỉ lắng nghe để công khai các API phát triển.

## Kiểm thử

Từ thư mục backend, dùng Java 17:

```powershell
.\mvnw.cmd package
node --test src/test/js/admin.test.cjs
```

Maven chạy toàn bộ test trước khi tạo JAR. Các test Spring dùng H2 trong bộ nhớ,
được cấu hình riêng tại src/test/resources/application.properties; không cần
SMAT_DB_PASSWORD hoặc PostgreSQL thật cho các test này. H2 chỉ có scope test.
Flyway và bootstrap tắt trong test; Hibernate tạo/xóa schema của database tạm.
Khóa JWT trong test resources chỉ là dữ liệu thử công khai, không dùng cho Backend thật.
Các test HTTP vẫn kiểm tra profile dev/production như trước.

Các test này không xác nhận migration PostgreSQL hoặc toàn bộ flow Mentor 60.
Khi chạy Backend thật trong IntelliJ hoặc spring-boot:run, vẫn cần PostgreSQL,
SMAT_DB_PASSWORD và SMAT_JWT_SECRET đúng. Biến môi trường IntelliJ không tự
truyền sang terminal khác. Không dùng -DskipTests để che lỗi build.

## Nếu ứng dụng tắt ngay

Đọc lỗi đầu tiên và `Caused by`, không chỉ dòng cuối `Process finished`:

- `Invalid profile property value`: ô profile sai; dùng `dev`.
- `SCRAM-based authentication, but no password was provided`: thiếu mật khẩu database trong chính cấu hình đang chạy.
- `Unable to determine Dialect`: kiểm tra lỗi kết nối PostgreSQL xuất hiện phía trước; không tự thêm dialect để che lỗi kết nối.
- Lỗi bean `jwtSecretKey`: kiểm tra biến khóa JWT, Base64 và độ dài giải mã.
- `Port 8080 was already in use`: backend cũ hoặc ứng dụng khác đang chiếm cổng.
- `Bootstrap username already exists`: tắt bootstrap và kiểm tra tài khoản hiện có.

Không sửa Flyway V1 đã áp dụng, không dùng `clean` của Flyway và không xóa dữ liệu để xử lý lỗi khởi động.

