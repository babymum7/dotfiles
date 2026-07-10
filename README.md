# Portable Nix Configuration (macOS & Linux)

Kho lưu trữ cấu hình dotfiles bằng Nix Flakes kết hợp với **nix-darwin** (cho macOS ở nhà) và **Home Manager** (cho cả macOS và Linux ở công ty). Hệ thống được cấu hình tối ưu để sử dụng cùng với **Determinate Nix Installer**.

---

## 1. Cài đặt Determinate Nix (Cho cả macOS và Linux)

Khuyến khích sử dụng trình cài đặt của Determinate Systems để có cấu hình Nix Flakes sẵn dùng, hoạt động ổn định và sống sót sau các bản cập nhật macOS lớn.

### Lệnh cài đặt:
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Tắt Telemetry & Sentry (Tùy chọn):
Nếu bạn không muốn gửi dữ liệu chẩn đoán ẩn danh về máy chủ của Determinate:
1. Trước khi chạy trình cài đặt, hãy thiết lập biến môi trường:
   ```bash
   export DETSYS_IDS_TELEMETRY=disabled
   ```
2. Để tắt dịch vụ báo cáo lỗi Sentry, bạn có thể thiết lập:
   ```bash
   export NIX_SENTRY_ENDPOINT=""
   ```

### Gỡ cài đặt hoàn toàn:
Nếu muốn gỡ cài đặt sạch sẽ Determinate Nix, hãy chạy lệnh sau:
```bash
/nix/nix-installer uninstall
```

---

## 2. Chuẩn bị cấu hình trước khi chạy

Trước khi áp dụng cấu hình lên máy, bạn cần cập nhật tên người dùng cục bộ (local username) của mình trong các file sau:

1. **`flake.nix`**:
   * Tìm dòng `home-manager.users.username` và đổi `username` thành tên user trên macOS của bạn.
2. **`home/macos.nix`**:
   * Đổi `home.username = "username";` và `home.homeDirectory = "/Users/username";` cho đúng với macOS của bạn.
3. **`home/linux.nix`**:
   * Đổi `home.username = "username";` và `home.homeDirectory = "/home/username";` cho đúng với Linux của bạn.

---

## 3. Áp dụng cấu hình (Apply)

### A. Trên macOS
Sử dụng `nix-darwin` (đã được cấu hình `nix.enable = false` để tránh xung đột với trình daemon của Determinate Nix):

```bash
# Di chuyển vào thư mục repo
cd ~/dotfiles

# Áp dụng cấu hình (nix-darwin + home-manager)
nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake .#macos
```
*Lưu ý:* Lần chạy đầu tiên sẽ yêu cầu mật khẩu sudo để thiết lập các liên kết tượng trưng hệ thống.

### B. Trên Linux
Sử dụng Home Manager phiên bản độc lập (standalone):

```bash
# Di chuyển vào thư mục repo
cd ~/dotfiles

# Áp dụng cấu hình Home Manager
nix run github:nix-community/home-manager -- switch --flake .#linux
```

---

## 4. Cấu trúc thư mục

```text
.
├── flake.nix                  # Khai báo các input/output của toàn bộ hệ thống
├── home/
│   ├── default.nix            # Cấu hình user chung (các gói CLI dùng chung, Git, shell aliases)
│   ├── macos.nix              # Cấu hình user đặc thù cho macOS
│   └── linux.nix              # Cấu hình user đặc thù cho Linux
└── hosts/
    ├── macos/
    │   └── configuration.nix  # Cấu hình mức hệ thống (system-level) cho macOS
    └── linux/
        └── configuration.nix  # Cấu hình mức máy trạm (host-level) cho Linux
```
