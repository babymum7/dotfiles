{ pkgs, lib, user, ... }: {
  imports = [ ./default.nix ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # Keep this value. It ensures backward compatibility with the version you started with.
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  home.activation = {
    ensureHerdr = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ! command -v herdr &>/dev/null && [ ! -x "$HOME/.local/bin/herdr" ]; then
        echo "herdr not found. Installing herdr via official installer..."
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://herdr.dev/install.sh | $DRY_RUN_CMD ${pkgs.bash}/bin/bash || true
      fi
    '';
  };
}
