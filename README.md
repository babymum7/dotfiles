# Nix Configuration (macOS & Linux)

Kho lưu trữ cấu hình dotfiles bằng Nix Flakes kết hợp với **nix-darwin** (cho macOS ở nhà) và **Home Manager** (cho cả macOS và Linux ở công ty). Hệ thống được cấu hình tối ưu để sử dụng cùng với **Determinate Nix Installer**.

---

## 1. Thiết lập tự động hệ thống (Bootstrap)

Để cài đặt và thiết lập hệ thống lần đầu trên máy mới, bạn chỉ cần chạy duy nhất script `bootstrap.sh`:

```bash
./bootstrap.sh --user <tên_user_của_bạn>
```
*(Nếu không truyền tham số `--user`, script sẽ tự động lấy username của tài khoản hiện tại).*

### Quy trình tự động của Script:
1. **Kiểm tra & Cài đặt Nix Native**: Nếu máy chưa cài Nix, script sẽ tự động tải và cài đặt Determinate Nix (yêu cầu mật khẩu `sudo`).
2. **Tạo liên kết symlink**: Tạo liên kết động từ thư mục chứa repo này tới thư mục `~/.dotfiles`.
3. **Cập nhật Username**: Cập nhật tên người dùng cục bộ của bạn vào `flake.nix` (biến `macUser` hoặc `linuxUser`).
4. **Áp dụng cấu hình Nix**: Kích hoạt cấu hình Nix/Home-Manager ban đầu (sử dụng cache/tarball trực tiếp để tránh lỗi GitHub API rate limit 403).
5. **Cài đặt WezTerm Nightly (Linux/Debian/Ubuntu)**: Tự động cấu hình GPG key, thêm kho APT chính thức và cài đặt `wezterm-nightly`. Nếu máy đang chạy bản Stable, APT sẽ tự động nâng cấp đè lên.
6. **Cài đặt Herdr (Linux)**: Kiểm tra và tự động cài đặt `herdr` thông qua kịch bản installer từ nhà phát triển (vào `~/.local/bin/herdr`).

---

## 2. Cập nhật cấu hình (Rebuild)

Khi bạn thay đổi cấu hình trong các file của thư mục repo cục bộ, hãy chạy script `rebuild.sh` để áp dụng:

```bash
./rebuild.sh
```

*   **Trên Linux**: Script sẽ chạy lệnh cập nhật `home-manager`.
*   **Trên macOS**: Script sẽ chạy lệnh cập nhật `darwin-rebuild`.
*   Cả hai script đều hỗ trợ tham số `--dry-run` để bạn chạy thử nghiệm kiểm tra lệnh trước khi áp dụng thực tế.

---

## 3. Cập nhật và bảo trì các gói phần mềm

*   **Các gói do Nix quản lý**: Chạy `nix flake update` để cập nhật file lock, sau đó chạy `./rebuild.sh` để áp dụng.
*   **WezTerm (Linux)**: Cập nhật thông qua trình quản lý gói hệ điều hành: `sudo apt update && sudo apt install --only-upgrade wezterm-nightly`.
*   **Herdr (Linux)**: Cập nhật trực tiếp bằng lệnh tích hợp của ứng dụng: `herdr update`.

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
