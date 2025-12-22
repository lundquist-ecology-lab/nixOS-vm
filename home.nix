{ config, pkgs, unstablePkgs ? pkgs, lib, hostname, ... }:

{
  home.username = "mlundquist";
  home.homeDirectory = "/home/mlundquist";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "mate-terminal";
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
        alias term="mate-terminal"
        alias onyx="cd /onyx"
        alias peppy="cd /peppy"
        setopt NO_BEEP

        export VISUAL="nvim"
        export EDITOR="nvim"

        # Oh My Posh prompt - use minimal theme for SSH/Guacamole sessions
        if [[ -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; then
          eval "$(oh-my-posh init zsh --config ${config.xdg.configHome}/oh-my-posh/minimal.omp.json)"
        else
          eval "$(oh-my-posh init zsh --config ${config.xdg.configHome}/oh-my-posh/kitty.omp.json)"
        fi

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

    btop = {
      enable = true;
      settings = {
        color_theme = "kitty";
        theme_background = false;  # Use terminal background
        vim_keys = true;
      };
    };
  };

  xdg = {
    enable = true;
    configFile."nvim" = {
      source = ./dotfiles/nvim;
      recursive = true;
    };
    configFile."oh-my-posh/kitty.omp.json" = {
      source = ./dotfiles/oh-my-posh/kitty.omp.json;
    };
    configFile."oh-my-posh/minimal.omp.json" = {
      source = ./dotfiles/oh-my-posh/minimal.omp.json;
    };
    configFile."btop/themes/kitty.theme" = {
      source = ./dotfiles/btop/themes/kitty.theme;
    };
    # OpenCode configuration for Ollama (localhost for VM)
    configFile."opencode/opencode.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        provider = {
          ollama = {
            npm = "@ai-sdk/openai-compatible";
            name = "Ollama (local)";
            options = {
              baseURL = "http://localhost:11434/v1";
            };
            models = {
              # Recommended agentic models with working tool calling
              "llama3.1:8b" = {
                name = "Llama 3.1 8B (Best for limited VRAM)";
                tools = true;  # Only needs ~5GB VRAM
              };
              "devstral:24b" = {
                name = "Devstral 24B (4K - no tools)";
                tools = false;  # Default 4K context too small
              };
              "devstral:24b-16k" = {
                name = "Devstral 24B (16K - needs 16GB VRAM)";
                tools = true;  # 16K context, less memory than 32K
              };
              "devstral:24b-32k" = {
                name = "Devstral 24B (32K - needs 24GB VRAM)";
                tools = true;  # Requires RTX 4090 or better
              };
              "llama3.1:70b" = {
                name = "Llama 3.1 70B (Most Capable)";
                tools = true;
              };
              "arcee-agent" = {
                name = "Arcee Agent 7B (Efficient)";
                tools = true;
              };
              "dolphin-llama3:8b" = {
                name = "Dolphin 3.0 Llama 3.1 8B (General)";
                tools = true;
              };
              # Models without tool support
              "deepseek-r1:latest" = {
                name = "DeepSeek R1 (Reasoning only)";
                tools = false;
              };
              "qwen3-coder:30b-32k" = {
                name = "Qwen3 Coder 30B (Broken tools)";
                tools = false;
              };
            };
          };
        };
        model = "ollama/llama3.1:8b";  # Default: works on any GPU with tools
      };
    };
  };

  home.packages = with pkgs; [
    unstablePkgs.oh-my-posh
    zoxide
    ripgrep
    fd
    jq
    yq
    yarn
    htop
    kitty   # Terminal emulator (GPU-accelerated, slower over VNC, kept as backup)
    tigervnc  # High-performance VNC server (x0vncserver for capturing GPU display)

    # Additional CLI tools
    glow  # Markdown viewer
    gh    # GitHub CLI

    # LSP servers (NixOS-provided instead of Mason due to FHS incompatibility)
    lua-language-server
    pyright
    deno  # provides denols
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted  # html, css, json, eslint
    yaml-language-server
    nodePackages.bash-language-server
    clang-tools  # provides clangd
    rust-analyzer
    gopls
    taplo
    nodePackages.dockerfile-language-server-nodejs
    docker-compose-language-service
    texlab
    marksman
    ltex-ls

    # Python packages (integrated)
    (python312.withPackages (ps: with ps; [
      # Core
      pip
      poetry-core
      pynvim

      # Geospatial analysis
      geopandas
      rasterio
      shapely
      pyproj
      gdal

      # Scientific computing
      numpy
      pandas
      scipy
      scikit-image
      matplotlib
      seaborn
      statsmodels
      pillow

      # Utilities
      tqdm
      pandocfilters
      panflute

      # Jupyter
      jupyter
      ipykernel
      notebook
    ]))
  ];

  # Systemd user service for TigerVNC x0vncserver (high-performance VNC for GPU display)
  systemd.user.services.x0vncserver = {
    Unit = {
      Description = "TigerVNC x0vncserver - High-performance VNC for existing X display";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # Performance-optimized x0vncserver flags:
      # -display :0: Attach to existing GPU-rendered display
      # -rfbport 5900: VNC port
      # -SecurityTypes None: No authentication (use Tailscale for security)
      # -AcceptPointerEvents: Enable mouse input
      # -AcceptKeyEvents: Enable keyboard input
      # -MaxProcessorUsage=100: Use full CPU for encoding
      # -PollingCycle=10: Fast polling for responsive updates (ms)
      # -CompareFB=2: Optimized framebuffer comparison
      # -UseSHM: Use shared memory for better performance
      ExecStart = "${pkgs.tigervnc}/bin/x0vncserver -display :0 -rfbport 5900 -SecurityTypes None -PollingCycle=10 -CompareFB=2 -UseSHM -MaxProcessorUsage=100";
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
    "org/mate/desktop/interface" = {
      enable-animations = false;
      gtk-theme = "Arc-Dark";
      icon-theme = "Tela-black-dark";
      cursor-theme = "Bibata-Modern-Classic";
      cursor-size = 24;
    };
    "org/mate/Marco/general" = {
      compositing-manager = false;  # Disable compositor for smoother VNC
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
