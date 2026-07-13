{ config, pkgs, user, ... }:

{
  # Common packages for both macOS and Linux
  home.packages = [
    pkgs.neovim
    pkgs.htop
    pkgs.curl
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.fnm
  ];

  # Basic Git configuration (adjust to your preference)
  programs.git = {
    enable = true;
    settings = {
      user.name = user;
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

      # Add Bun bin directory to PATH
      let bun_bin = ($env.HOME | path join ".bun" "bin")
      $env.PATH = ($env.PATH | prepend $bun_bin)
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
  home.file.".omp/agent/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/omp/agent/config.yml";

}
