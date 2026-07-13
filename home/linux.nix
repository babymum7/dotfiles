{ config, pkgs, user, ... }: {
  imports = [ ./default.nix ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # Keep this value. It ensures backward compatibility with the version you started with.
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  # Linux-specific user packages (optional)
  home.packages = with pkgs; [
    # Add Linux specific tools here (e.g. gcc, gnumake, etc.)
    wezterm
    (writeShellScriptBin "dotfiles-gpu-setup" ''
      exec ${config.targets.genericLinux.gpu.setupPackage}/bin/non-nixos-gpu-setup "$@"
    '')
  ];

  home.file.".local/share/applications/org.wezfurlong.wezterm.desktop".text = ''
    [Desktop Entry]
    Name=WezTerm
    Comment=A GPU-accelerated cross-platform terminal emulator and multiplexer
    Exec=${pkgs.wezterm}/bin/wezterm start --cwd .
    Icon=${pkgs.wezterm}/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png
    Type=Application
    Categories=System;TerminalEmulator;Utility;
    Terminal=false
  '';
}
