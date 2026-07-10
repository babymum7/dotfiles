{ config, pkgs, ... }: {
  # Common packages for both macOS and Linux
  home.packages = with pkgs; [
    neovim
    tmux
    htop
    curl
    wget
    ripgrep
    fd
    fzf
    jq
  ];

  # Basic Git configuration (adjust to your preference)
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Common shell configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  # Common shell aliases
  home.shellAliases = {
    ll = "ls -l";
    la = "ls -la";
    g = "git";
  };
}
