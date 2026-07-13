{ config, pkgs, ... }:
let
  bun-1_3_14 = pkgs.bun.overrideAttrs (oldAttrs: rec {
    version = "1.3.14";
    src = let
      sys = pkgs.stdenv.hostPlatform.system;
      platformConfig = if sys == "x86_64-linux" then {
        name = "linux-x64";
        sha256 = "13w4gvgwrjq9bi3ddp53hgm3z399d8i2aqpcmsaqbw2mx2pf47lm";
      } else if sys == "aarch64-darwin" then {
        name = "darwin-aarch64";
        sha256 = "0816cp154xi6x01qh7h0cgvild3jb3lvf2mcqxxgkmlah8hn5ffq";
      } else throw "Unsupported system for bun overlay: ${sys}";
    in pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-${platformConfig.name}.zip";
      sha256 = platformConfig.sha256;
    };
  });
in {
  # Common packages for both macOS and Linux
  home.packages = [
    pkgs.neovim
    pkgs.htop
    pkgs.curl
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    bun-1_3_14
    pkgs.fnm
  ];

  # Basic Git configuration (adjust to your preference)
  programs.git = {
    enable = true;
    settings = {
      user.name = "babymum7";
      user.email = "nbtrong2312@gmail.com";
      init.defaultBranch = "main";
    };
  };

  # Common shell configuration
  programs.bash = {
    enable = false;
  };
  programs.nushell = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      g = "git";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
    };
    extraEnv = ''
      # Initialize fnm node version manager
      let fnm_bin = "${pkgs.fnm}/bin/fnm"
      if ($fnm_bin | path exists) {
        let env_vars = (^$fnm_bin env --json | from json)
        load-env $env_vars
        $env.PATH = ($env.PATH | prepend $"($env_vars.FNM_MULTISHELL_PATH)/bin")
      }
    '';
    extraConfig = ''
      $env.config.show_banner = false
    '';
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Common shell aliases
  home.shellAliases = {
    ll = "ls -l";
    la = "ls -la";
    g = "git";
  };

  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/wezterm";

  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/herdr/config.toml";

  home.file.".config/herdr/nvim-newtab.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/herdr/nvim-newtab.sh";

  home.file.".config/herdr/nvim-explorer.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/herdr/nvim-explorer.sh";

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/nvim";
}
