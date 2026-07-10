{ pkgs, ... }: {
  # List packages installed in system profile for macOS.
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
  ];
  # Disable nix-darwin's management of the Nix daemon and configuration
  # because it is managed by Determinate Nix.
  nix.enable = false;
  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; 

  # Set your state version for darwin-rebuild (read changelog before changing).
  system.stateVersion = 5;
}
