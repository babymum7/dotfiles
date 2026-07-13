{
  description = "Nix configuration for macOS and Linux";

  inputs = {
    # Unstable packages are recommended for desktop environments and developers
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";

    # Controls system-level configuration on macOS
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manages user-level packages and dotfiles on both macOS and Linux
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-bun = {
      url = "https://github.com/NixOS/nixpkgs/archive/943e4c3c705a1b3025348d82d6aada3c442327ec.tar.gz";
    };
  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-bun, nix-darwin, home-manager }:
    let
      # Centralized local username configuration.
      # Sửa tên user ở đây hoặc chạy ./bootstrap.sh --user <tên_user>
      macUser = "babymum7";
      linuxUser = "trong";
    in {
      # 1. macOS configuration (nix-darwin + home-manager)
      # Target: macOS. Run on Mac (first run uses nix-darwin tarball archive):
      # nix run https://github.com/nix-darwin/nix-darwin/archive/nix-darwin-26.05.tar.gz#darwin-rebuild -- switch --flake .#macos
      darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
        # Change "aarch64-darwin" to "x86_64-darwin" if using an older Intel Mac
        system = "aarch64-darwin";
        specialArgs = { user = macUser; };
        modules = [
          ./hosts/macos/configuration.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [
              (final: prev: {
                bun = nixpkgs-bun.legacyPackages."aarch64-darwin".bun;
              })
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { user = macUser; };
            # Dynamically imported using the centralized 'macUser' variable above
            home-manager.users.${macUser} = import ./home/macos.nix;
          }
        ];
      };

      # 2. Linux configuration (Home Manager standalone)
      # Target: Linux. Run on Linux:
      # nix run https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz -- switch --flake .#linux
      homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [
            (final: prev: {
              bun = nixpkgs-bun.legacyPackages."x86_64-linux".bun;
            })
          ];
        };
        extraSpecialArgs = { user = linuxUser; };
        modules = [
          ./home/linux.nix
        ];
      };

    };
}
