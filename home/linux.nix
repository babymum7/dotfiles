{ config, pkgs, ... }: {
  imports = [ ./default.nix ];

  # Change "username" to your actual Linux local username
  home.username = "username";
  home.homeDirectory = "/home/username";

  # Keep this value. It ensures backward compatibility with the version you started with.
  home.stateVersion = "24.11";
  # Linux-specific user packages (optional)
  home.packages = with pkgs; [
    # Add Linux specific tools here (e.g. gcc, gnumake, etc.)
  ];
}
