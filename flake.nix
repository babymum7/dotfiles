{
  description = "Portable Nix configuration for macOS and Linux";

  inputs = {
    # Unstable packages are recommended for desktop environments and developers
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Controls system-level configuration on macOS
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manages user-level packages and dotfiles on both macOS and Linux
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
    let
      user = "username";
    in {
      # 1. macOS configuration (nix-darwin + home-manager)
      # Target: macOS. Run on Mac (first run uses github:nix-darwin/nix-darwin/master#darwin-rebuild):
      darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
        # Change "aarch64-darwin" to "x86_64-darwin" if using an older Intel Mac
        system = "aarch64-darwin";
        specialArgs = { inherit user; };
        modules = [
          ./hosts/macos/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; };
            # Change "username" to your actual macOS local username
            home-manager.users.${user} = import ./home/macos.nix;
          }
        ];
      };

      # 2. Linux configuration (Home Manager standalone)
      # Target: Linux. Run on Linux:
      # nix run github:nix-community/home-manager -- switch --flake .#linux
      homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        extraSpecialArgs = { inherit user; };
        modules = [
          ./hosts/linux/configuration.nix
          ./home/linux.nix
        ];
      };
    };
}
