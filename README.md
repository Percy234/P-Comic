# 📖 P-Comic - Ứng dụng Đọc Truyện Tranh Thông Minh

**P-Comic** là ứng dụng đọc truyện tranh đa nền tảng (Android, Web) được xây dựng trên nền tảng **Flutter**. Ứng dụng tích hợp các công nghệ hiện đại như hệ sinh thái **Firebase**, cơ sở dữ liệu local **Hive** và đặc biệt là trợ lý tìm kiếm truyện thông minh bằng trí tuệ nhân tạo **Gemini AI**.

---

## ✨ Các Tính Năng Nổi Bật

### 1. 🤖 Tìm Truyện Bằng AI Gemini (AI Semantic Search)
- Cho phép tìm kiếm truyện bằng mô tả ngôn ngữ tự nhiên (ví dụ: *"tìm truyện main đi diệt quỷ cứu em gái"* hoặc *"truyện nam chính cày cấp trong ngục tối"*).
- Tích hợp công nghệ **Multi-model Fallback & Auto-Retry** (luân chuyển mô hình tự động giữa `gemini-1.5-flash-lite`, `gemini-1.5-flash` và `gemini-2.0-flash` trên endpoint `v1beta`) đảm bảo tính ổn định cao và vượt qua giới hạn quota của tài khoản miễn phí.
- Hiển thị trực quan lý do đề xuất thông minh từ AI (💡 *Lý do gợi ý từ AI*).

### 2. 🔐 Đăng Nhập & Đăng Ký Đa Dạng (Firebase Auth)
- Đăng ký và đăng nhập thủ công thông qua tên đăng nhập/email và mật khẩu kèm tính năng gửi email xác thực tài khoản.
- Hỗ trợ đăng nhập nhanh bằng tài khoản Google trên thiết bị (**Google Sign-In**).
- Luồng bảo mật chặt chẽ: Bắt buộc người dùng xác nhận và đồng ý với **Điều khoản & Chính sách quyền riêng tư** (tích hợp hộp thoại Pop-up tự động thông minh khi đăng nhập).

### 3. 🎨 Giao Diện UI/UX Premium & Hiện Đại
- Hỗ trợ chế độ Sáng/Tối (**Light / Dark Mode**) tương thích với hệ thống.
- Các hiệu ứng chuyển động mượt mà, ảnh động **Lottie** sinh động.
- Thanh công cụ tìm kiếm thông minh hỗ trợ gợi ý kết quả trực tiếp dưới dạng danh sách thả xuống (Dropdown Overlay).
- Tối ưu kích thước giao diện trên nhiều thiết bị di động khác nhau.

### 4. 🗄️ Lưu Trữ Dữ Liệu & Đồng Bộ Đám Mây
- **Firebase Firestore**: Đồng bộ thông tin cá nhân, cập nhật nickname, và quản lý bảo mật.
- **Firebase Storage**: Lưu trữ hình ảnh avatar người dùng.
- **Hive Database**: Lưu trữ lịch sử đọc truyện và danh sách yêu thích local giúp tăng tốc độ tải và giảm băng thông API.

---

## 🛠️ Công Nghệ Sử Dụng

- **Frontend**: Flutter & Dart
- **Quản lý trạng thái (State Management)**: `Provider`
- **Backend & Cloud**: Firebase Core, Firebase Auth, Cloud Firestore, Firebase Storage
- **AI Engine**: Google Generative AI (Gemini SDK)
- **Local Storage**: Hive & Hive Flutter
- **UI & Animations**: Lottie, Google Fonts, Flutter HTML (hiển thị mô tả truyện dạng rich-text)

---

## 🚀 Hướng Dẫn Cài Đặt và Chạy Project

### 1. Yêu Cầu Hệ Thống
- Đã cài đặt Flutter SDK (khuyên dùng phiên bản stable mới nhất, tối thiểu `^3.11.5`).
- Đã cài đặt Android Studio / VS Code và các trình giả lập tương ứng.

### 2. Các Bước Thực Hiện
1. Clone mã nguồn ứng dụng về máy:
   ```bash
   git clone https://github.com/Percy234/P-Comic.git
   cd P-Comic
   ```
2. Cài đặt các gói thư viện cần thiết:
   ```bash
   flutter pub get
   ```
3. Cấu hình khóa API Gemini:
   Tạo tệp cấu hình chứa API Key của bạn tại đường dẫn `lib/config/api_config.dart` (tệp này đã được đưa vào danh sách `.gitignore` để tránh rò rỉ khóa lên GitHub):
   ```dart
   // lib/config/api_config.dart
   class ApiConfig {
     static const String geminiApiKey = 'MÃ_API_KEY_GEMINI_CỦA_BẠN';
   }
   ```
4. Chạy ứng dụng trên thiết bị / trình giả lập:
   ```bash
   flutter run
   ```
   *Để chạy phiên bản Web trên một cổng cố định (phục vụ kiểm thử đăng nhập Google)*:
   ```bash
   flutter run -d chrome --web-port=5000
   ```

---

## 📦 Quy Trình Build & Tự Động Phát Hành (CI/CD)

Ứng dụng sử dụng **GitHub Actions** để tự động hóa quy trình build bản release mỗi khi bạn đẩy một thẻ phiên bản (tag) mới.

### Cách thức hoạt động:
1. Khi push một tag có tiền tố `v` (ví dụ: `v1.1.1`):
   - GitHub Actions sẽ tự động setup JDK, Flutter, tải dependencies.
   - Sử dụng Secret `GEMINI_API_KEY` được thiết lập trên kho chứa (Repository Settings) để tạo file config tạm thời.
   - Biên dịch ứng dụng sang file APK Release đã được đổi tên gọn gàng thành **`P_Comic.apk`**.
   - Tạo bản phát hành **Release** tương ứng trên GitHub và tải tệp APK lên đó.

### Cách thiết lập Secret trên GitHub:
1. Vào repository của bạn trên GitHub -> **Settings** -> **Secrets and variables** -> **Actions**.
2. Nhấn **New repository secret**.
3. Điền **Name**: `GEMINI_API_KEY` và **Value**: `MÃ_API_KEY_GEMINI_CỦA_BẠN`.
4. Nhấn **Add secret** để lưu lại.
