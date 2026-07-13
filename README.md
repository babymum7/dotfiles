# Nix Configuration (macOS & Linux)

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

Trước khi chạy, script `bootstrap.sh` sẽ tự động cập nhật tên người dùng cục bộ (local username) vào biến tương ứng (`macUser` hoặc `linuxUser`) trong `flake.nix` tùy thuộc vào hệ điều hành đang dùng.

Nếu muốn cấu hình thủ công, bạn chỉ cần sửa các biến này ở đầu file `flake.nix`.
---

## 3. Áp dụng cấu hình (Apply)

Để thiết lập hệ thống lần đầu (bootstrap), hãy chạy script `bootstrap.sh` và truyền tên người dùng cục bộ của bạn bằng tham số `--user`:

```bash
# Thiết lập hệ thống lần đầu
./bootstrap.sh --user <tên_user_của_bạn>
```

Script sẽ tự động:
1. Kiểm tra và cài đặt Determinate Nix nếu chưa có.
2. Tạo symlink liên kết thư mục hiện tại của repo tới thư mục `~/.dotfiles`.
3. Tự động cập nhật tên người dùng cục bộ vào `flake.nix`.
4. Thực hiện việc áp dụng cấu hình Nix ban đầu.

Để cập nhật/xây dựng lại cấu hình sau này (rebuild) khi bạn thay đổi các file trong repo, chạy script `rebuild.sh`:

```bash
# Xây dựng lại cấu hình
./rebuild.sh
```

Cả hai script đều hỗ trợ tham số `--dry-run` để bạn chạy thử nghiệm kiểm tra lệnh trước khi áp dụng thực tế.

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

---

## 5. Lưu ý cấu hình GPU cho ứng dụng GUI (như WezTerm) trên generic Linux

Trên các bản phân phối Linux không phải NixOS (như Ubuntu, Debian, Fedora), các ứng dụng đồ họa GUI được quản lý bởi Nix (ví dụ: WezTerm) cần truy cập driver GPU của hệ thống host để có hiệu năng tối ưu và tránh lỗi crash khi khởi chạy.

Bạn có thể tự động cấu hình tích hợp driver đồ họa của host vào Nix bằng cách chạy lệnh sau:

```bash
sudo dotfiles-gpu-setup
```

Lệnh này sẽ tự động phát hiện driver GPU của host và tạo các liên kết driver cần thiết trong Nix store để ứng dụng đồ họa hoạt động mượt mà.
