{ pkgs, ... }: {
  # Linux host-specific configurations.
  # Add packages and configurations specific to your work environment here.
  home.packages = with pkgs; [
    # E.g., corporate tools, VPN clients, or specific development runtimes
    # gcc
    # gnumake
  ];
}
