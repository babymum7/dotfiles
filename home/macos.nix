{ user, ... }: {
  imports = [ ./default.nix ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";
  
  # Keep this value. It ensures backward compatibility with the version you started with.
  home.stateVersion = "24.11";
}
