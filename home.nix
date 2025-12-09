{ config, pkgs, unstablePkgs ? pkgs, lib, hostname, ... }:

{
  home.username = "mlundquist";
  home.homeDirectory = "/home/mlundquist";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "foot";
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
        alias term="foot"
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

  # Set XFCE default terminal to foot
  xfconf.settings = {
    xfce4-keyboard-shortcuts = {
      "commands/default/<Super>t" = "foot";
      "commands/custom/<Primary><Alt>t" = "foot";
    };
  };

  home.packages = with pkgs; [
    unstablePkgs.oh-my-posh
    zoxide
    ripgrep
    fd
    jq
    yq
    htop
    btop
    foot    # Lightweight terminal emulator (better for VNC)
    kitty   # Terminal emulator (GPU-accelerated, slower over VNC)
    x11vnc  # VNC server for X11

    # Additional CLI tools
    glow  # Markdown viewer
    gh    # GitHub CLI

    # Python packages (integrated)
    (python311.withPackages (ps: with ps; [
      gdal
      pillow
      pip
      poetry-core
      pynvim
      seaborn
      statsmodels
      pandocfilters
      panflute
    ]))
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

  # GTK theming configuration
  gtk = {
    enable = true;
    theme = {
      package = pkgs.paradise-gtk-theme;
      name = "paradise";
    };
    iconTheme = {
      package = pkgs.tela-icon-theme;
      name = "Tela-black-dark";
    };
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # dconf settings for GNOME/GTK applications
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "paradise";
      icon-theme = "Tela-black-dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
    };
  };

  # Qt theming
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "adwaita-dark";
  };

  home.stateVersion = "25.11";
}
