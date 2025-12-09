{ config, pkgs, unstablePkgs ? pkgs, lib, hostname, ... }:

{
  home.username = "mlundquist";
  home.homeDirectory = "/home/mlundquist";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.pyenv/bin"
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      oh-my-zsh = {
        enable = true;
        theme = ""; # Disable oh-my-zsh theme to use custom prompt
        plugins = [
          "git"
        ];
      };
      autosuggestion = {
        enable = true;
        strategy = [ "history" "completion" ];
      };
      syntaxHighlighting.enable = true;
      history = {
        path = "${config.xdg.dataHome}/zsh/history";
        size = 50000;
      };
      initExtra = ''
        # Key bindings
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word

        # Aliases
        alias zshconfig="nvim ~/.zshrc"
        setopt NO_BEEP

        export VISUAL="nvim"
        export EDITOR="nvim"

        # Oh My Posh prompt
        eval "$(oh-my-posh init zsh --config ${config.xdg.configHome}/oh-my-posh/kitty.omp.json)"

        # Enable Oh My Posh autoupgrade
        oh-my-posh enable autoupgrade &>/dev/null || true
      '';
    };

    git = {
      enable = true;
      userName = "Matthew Lundquist";
      userEmail = "lundquistecologylab@gmail.com";
      extraConfig = {
        core.editor = "nvim";
        pull.rebase = false;
        push.default = "current";
        init.defaultBranch = "main";
      };
    };

    fzf.enable = true;
    bat.enable = true;

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };
  };

  xdg = {
    enable = true;
    configFile."oh-my-posh/kitty.omp.json" = {
      source = ./dotfiles/oh-my-posh/kitty.omp.json;
    };
  };

  home.packages = with pkgs; [
    unstablePkgs.oh-my-posh
    zoxide
    ripgrep
    fd
    jq
    htop
    kitty   # Terminal emulator
    x11vnc  # VNC server for X11 (for Guacamole)
  ];

  # Systemd user service for x11vnc
  systemd.user.services.x11vnc = {
    Unit = {
      Description = "x11vnc - VNC server for X11";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -forever -shared -rfbport 5900";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "25.11";
}
