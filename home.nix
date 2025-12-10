{ config, pkgs, unstablePkgs ? pkgs, lib, hostname, ... }:

{
  home.username = "mlundquist";
  home.homeDirectory = "/home/mlundquist";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "xfce4-terminal";
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
        alias term="xfce4-terminal"
        alias onyx="cd /onyx"
        alias peppy="cd /peppy"
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
    configFile."xfce4/terminal/terminalrc" = {
      text = ''
        [Configuration]
        FontName=JetBrainsMono Nerd Font 11
        MiscAlwaysShowTabs=FALSE
        MiscBell=FALSE
        MiscBellUrgent=FALSE
        MiscBordersDefault=TRUE
        MiscCursorBlinks=FALSE
        MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
        MiscDefaultGeometry=100x30
        MiscInheritGeometry=FALSE
        MiscMenubarDefault=FALSE
        MiscMouseAutohide=FALSE
        MiscMouseWheelZoom=TRUE
        MiscToolbarDefault=FALSE
        MiscConfirmClose=TRUE
        MiscCycleTabs=TRUE
        MiscTabCloseButtons=TRUE
        MiscTabCloseMiddleClick=TRUE
        MiscTabPosition=GTK_POS_TOP
        MiscHighlightUrls=TRUE
        MiscMiddleClickOpensUri=FALSE
        MiscCopyOnSelect=TRUE
        MiscShowRelaunchDialog=TRUE
        MiscRewrapOnResize=TRUE
        MiscUseShiftArrowsToScroll=FALSE
        MiscSlimTabs=FALSE
        MiscNewTabAdjacent=FALSE
        MiscSearchDialogOpacity=100
        MiscShowUnsafePasteDialog=TRUE
        ColorForeground=#c0caf5
        ColorBackground=#1a1b26
        ColorCursor=#c0caf5
        ColorSelection=#1a1b26
        ColorSelectionBackground=#c0caf5
        ColorBoldUseDefault=FALSE
        ColorPalette=#15161e;#f7768e;#9ece6a;#e0af68;#7aa2f7;#bb9af7;#7dcfff;#a9b1d6;#414868;#f7768e;#9ece6a;#e0af68;#7aa2f7;#bb9af7;#7dcfff;#c0caf5
        TabActivityColor=#f7768e
      '';
    };
  };

  # Set XFCE default terminal to xfce4-terminal
  xfconf.settings = {
    xfce4-keyboard-shortcuts = {
      "commands/default/<Super>t" = "xfce4-terminal";
      "commands/custom/<Primary><Alt>t" = "xfce4-terminal";
    };

    # Performance optimizations for VNC
    xfwm4 = {
      "general/use_compositing" = false;  # Disable compositor for VNC
      "general/vblank_mode" = "off";
      "general/frame_opacity" = 100;
      "general/inactive_opacity" = 100;
      "general/show_frame_shadow" = false;
      "general/show_popup_shadow" = false;
    };

    xsettings = {
      "Gtk/EnableAnimations" = false;  # Disable animations
      "Gtk/CursorThemeName" = "Bibata-Modern-Classic";
      "Gtk/CursorThemeSize" = 24;
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
    kitty   # Terminal emulator (GPU-accelerated, slower over VNC, kept as backup)
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

  # Systemd user service for x11vnc with performance optimizations
  systemd.user.services.x11vnc = {
    Unit = {
      Description = "x11vnc - VNC server for X11";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # Performance-optimized x11vnc flags:
      # -speeds lan: Optimize for LAN speeds
      # -threads: Enable multi-threading
      # -wireframe: Show wireframes during window moves (faster)
      # -clip 1920x1080+0+0: Clip to visible screen area
      # Note: -ncache removed as it creates a tall virtual framebuffer that confuses some VNC clients (like Guacamole)
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :0 -forever -shared -rfbport 5900 -clip 1920x1080+0+0 -speeds lan -threads -wireframe";
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
      package = pkgs.arc-theme;
      name = "Arc-Dark";
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
      gtk-theme = "Arc-Dark";
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
