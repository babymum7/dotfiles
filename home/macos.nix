{ config, pkgs, ... }: {
  imports = [ ./default.nix ];

  # Change "username" to your actual macOS local username
  home.username = "username";
  home.homeDirectory = "/Users/username";
  
  # Keep this value. It ensures backward compatibility with the version you started with.
  home.stateVersion = "24.11";

  # macOS-specific user packages (optional)
  home.packages = with pkgs; [
    # Add macOS specific tools here
  ];
}
