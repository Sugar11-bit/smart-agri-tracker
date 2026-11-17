# Smart Agri Tracker — mobile / Mentor 59

Đã có đăng nhập, xác minh /auth/me, Secure Storage, My Plots theo phân công,
SQLite riêng theo userId, đồng bộ thủ công/tự động và đọc cache khi mất mạng.

## Chạy Android local trên Windows

1. Khởi động Backend cổng 8080 và Android emulator.
2. Tại thư mục mobile chạy `powershell -ExecutionPolicy Bypass -File scripts/run-local.ps1`.
3. Đăng nhập bằng tài khoản đã được cấp; không ghi mật khẩu vào mã nguồn.

Script kiểm tra Backend, thiết lập `adb reverse tcp:8080 tcp:8080`, rồi chạy app.
Chạy lại sau khi emulator hoặc adb khởi động lại. Có thể dùng `-CheckOnly` để
chỉ khôi phục kết nối, `-DeviceId` để chọn thiết bị, `-Flutter`/`-Adb` để đổi đường dẫn.
127.0.0.1 trong app là Android, nên cần adb reverse khi Backend chỉ nghe loopback.
Điện thoại thật cũng có thể dùng USB và adb reverse. Không đổi sang 10.0.2.2
nếu chưa kiểm tra địa chỉ Backend đang lắng nghe.

## Kiểm tra

Chạy tuần tự: `flutter analyze --no-pub`, `flutter test --no-pub`,
`flutter test --no-pub integration_test/sqlite_test.dart -d emulator-5554`.
Kiểm tra thực tế: đăng nhập và xem đúng khu đất; đóng/mở app; ngắt adb reverse
và đồng bộ để xem cache Offline; khôi phục và đồng bộ; đổi hai tài khoản;
Admin kết thúc phân công thử rồi xác nhận khu đất biến mất khi Online.

## Phạm vi

Đây là nền tảng Mentor 59: chưa có màn hình chi tiết đất và nhật ký canh tác.
Bản release cần API HTTPS qua API_BASE_URL và cấu hình phát hành.
HTTP local chỉ được cho phép ở bản debug; quyền INTERNET nằm trong manifest chính.
