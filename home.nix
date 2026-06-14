{ config, pkgs, unstablePkgs ? pkgs, lib, hostname, ... }:

{
  home.username = "mlundquist";
  home.homeDirectory = "/home/mlundquist";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "mate-terminal";
    PYTHONPATH = "/home/mlundquist/.local/lib/python3.12/site-packages";
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
        alias oc='opencode'
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
    configFile."opencode/instructions/local-coder.md" = {
      text = ''
        Prefer direct, code-first responses for software tasks.

        ## Tool use — MANDATORY

        You have tools available to read, write, and edit files. You MUST use them.

        - NEVER output file contents as a code block in chat. Always use the write_file or edit tool to write to disk.
        - NEVER describe what you are going to do. Just do it using the appropriate tool call.
        - NEVER output JSON tool call syntax as text. Issue the actual tool call.
        - When asked to create a file, call the write tool immediately — do not plan, do not explain first.
        - When asked to edit a file, read it first with the read tool, then write the change with the edit tool.
        - For string-based edits, choose an `oldString` that is unique in the file by including enough surrounding context.
        - For exact-match edit tools, copy the `oldString` directly from the file and preserve whitespace, indentation, and line endings exactly.
        - If the tool reports `found multiple matches for oldString`, immediately expand the match to include surrounding lines, nearby function signatures, or the full block until it is unique.
        - If an `oldString` matches multiple locations, stop retrying the same short match and replace a larger block or rewrite the file instead.
        - If an exact string match keeps failing, stop making tiny edits and rewrite the nearest unambiguous block or the full file.
        - Complete every task using tool calls. A response that only contains text has failed.

        ## Style

        - Keep explanations short unless the user explicitly asks for depth.
        - Do not expose chain-of-thought or internal reasoning. Provide conclusions only.
        - Do not narrate planned actions or describe tool usage before calling tools.
        - Prefer terse responses: one sentence when possible, short paragraphs when necessary.
        - Avoid filler phrases, self-references, and step-by-step commentary unless the user asks for it.
        - For Gemma 4 models, never enable thinking mode or include the `<|think|>` token in prompts.
        - For fixes and edits, state the root cause in one sentence, then apply the fix via tool call.
        - For plans, use a short numbered list and avoid implementation detail unless asked.
        - Avoid long preambles, motivational language, and repeated restatement of the request.
        - When tests are requested, include focused tests only.
        - When the request is ambiguous, make the smallest reasonable assumption and state it briefly.
      '';
    };
    # OpenCode configuration for Ollama (localhost for VM)
    configFile."opencode/opencode.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        instructions = [
          "./instructions/local-coder.md"
        ];
        agent = {
          build = {
            maxTokens = 32768;
            maxOutputTokens = 16384;
            maxSteps = 12;
          };
          general = {
            maxTokens = 8192;
            maxOutputTokens = 4096;
            maxSteps = 12;
          };
          explore = {
            maxTokens = 8192;
            maxOutputTokens = 4096;
            maxSteps = 12;
          };
          plan = {
            maxTokens = 8192;
            maxOutputTokens = 4096;
            maxSteps = 8;
          };
        };
        command = {
          fix = {
            description = "Code-first bug fix";
            template = ''
              Fix the problem below.

              Output format:
              1. One sentence naming the root cause.
              2. The corrected code or patch.
              3. Minimal tests if they help verify the fix.

              Keep the response concise and code-first.

              Request:
              $ARGUMENTS
            '';
          };
          plan = {
            description = "Short implementation plan";
            template = ''
              Produce a short implementation plan for the request below.

              Rules:
              - Use 3 to 6 numbered steps.
              - Focus on concrete engineering actions.
              - Do not write code unless explicitly requested.
              - Mention major risks or assumptions briefly.

              Request:
              $ARGUMENTS
            '';
          };
          explain = {
            description = "Brief technical explanation";
            template = ''
              Explain the following in a concise, technical way.

              Rules:
              - Optimize for clarity and speed of understanding.
              - Use examples only if they materially help.
              - Keep the answer compact unless the request asks for depth.

              Topic:
              $ARGUMENTS
            '';
          };
        };
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
                name = "Llama 3.1 8B (4K - no tools)";
                tools = false;  # Default 4K context too small
              };
              "llama3.1:8b-32k" = {
                name = "Llama 3.1 8B (32K)";
                tools = true;  # 32K context for tool calling
                limit = {
                  context = 32768;
                  output = 2048;
                };
                options = {
                  maxTokens = 2048;
                  maxOutputTokens = 2048;
                  max_tokens = 2048;
                  max_output_tokens = 2048;
                };
              };
              "devstral:24b" = {
                name = "Devstral 24B (Slow comparison model)";
                tools = false;  # Default 4K context too small
              };
              "devstral:24b-16k" = {
                name = "Devstral 24B (16K - benchmark only)";
                tools = true;  # 16K context, less memory than 32K
              };
              "devstral:24b-32k" = {
                name = "Devstral 24B (32K - needs 24GB VRAM)";
                tools = true;  # Requires RTX 4090 or better
              };
              "ministral-3:14b" = {
                name = "Ministral 3 14B (Best current local default)";
                tools = false;
              };
              "ministral-3:14b-64k" = {
                name = "Ministral 3 14B 64K (Tool calling)";
                tools = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
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
              "gemma4-64k:latest" = {
                name = "Gemma 4 64K";
                tools = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
              "qwen3:14b" = {
                name = "Qwen3 14B (Reasoning-heavy alternative)";
                tools = false;
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
              "qwen3:14b-32k" = {
                name = "Qwen3 14B 32K (Tool calling)";
                tools = true;
                limit = {
                  context = 32768;
                  output = 4096;
                };
              };
              "qwen3:14b-64k" = {
                name = "Qwen3 14B 64K (Tool calling)";
                tools = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
              "qwen2.5-coder:14b" = {
                name = "Qwen2.5 Coder 14B (Best tool calling)";
                tools = true;
                limit = {
                  context = 32768;
                  output = 4096;
                };
              };
              "qwen2.5-coder:14b-64k" = {
                name = "Qwen2.5 Coder 14B 64K (Tool calling)";
                tools = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
              "hermes3:8b" = {
                name = "Hermes 3 8B (Tool calling)";
                tools = true;
                limit = {
                  context = 8192;
                  output = 2048;
                };
              };
              "hermes3:3b" = {
                name = "Hermes 3 3B (Lightweight tool calling)";
                tools = true;
                limit = {
                  context = 8192;
                  output = 2048;
                };
              };
              "qwen3.6-64k:35b" = {
                name = "Qwen3.6 35B 64K (Tool calling)";
                tools = true;
                limit = {
                  context = 65536;
                  output = 8192;
                };
              };
            };
          };
        };
        model = "ollama/qwen3.6-64k:35b";
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
    lsof  # Required by opencode.nvim to find running opencode processes
    glow  # Markdown viewer
    gh    # GitHub CLI
    xclip  # Clipboard provider for Neovim on X11/VNC sessions
    xsel   # Fallback clipboard provider for Neovim on X11/VNC sessions
    wl-clipboard  # Clipboard provider for Neovim on Wayland sessions

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

      # ML / Deep learning
      torch-bin
      torchvision-bin

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
