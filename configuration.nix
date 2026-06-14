# NixOS configuration for nix-python VM
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, unstablePkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nix-python";
  networking.networkmanager.enable = true;

  # Disable waiting for network online during boot to prevent DHCP delays
  systemd.services.NetworkManager-wait-online.enable = false;

  # Set your time zone
  time.timeZone = "US/Eastern";

  # Internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable NVIDIA drivers for passthrough GPU
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for CUDA + Steam
  };

  # Needed for proprietary NVIDIA firmware blobs
  hardware.enableRedistributableFirmware = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Required for Ada/Blackwell GPUs: use NVIDIA's open kernel module
    open = true;

    nvidiaSettings = true;

    # RTX 5060 Ti (GB206) requires 595.x+; 580.142 (nixos-25.11 beta) lacks the PCI ID
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.58.03";
      sha256_64bit = "sha256-jA1Plnt5MsSrVxQnKu6BAzkrCnAskq+lVRdtNiBYKfk=";
      sha256_aarch64 = "sha256-hzzIKY1Te8QkCBWR+H5k1FB/HK1UgGhai6cl3wEaPT8=";
      openSha256 = "sha256-6LvJyT0cMXGS290Dh8hd9rc+nYZqBzDIlItOFk8S4n8=";
      settingsSha256 = "sha256-2vLF5Evl2D6tRQJo0uUyY3tpWqjvJQ0/Rpxan3NOD3c=";
      persistencedSha256 = "sha256-AtjM/ml/ngZil8DMYNH+P111ohuk9mWw5t4z7CHjPWw=";
    };
  };

  boot.blacklistedKernelModules = [ "nouveau" "nvidiafb" ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  # Load NVIDIA stack during normal boot (not initrd), plus virtiofs for shared folders
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "virtiofs" ];

  # Enable zsh system-wide
  programs.zsh.enable = true;
  
  # Enable VSCode
  programs.nix-ld.enable = true;

  # Tmux configuration
  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Use the most broadly available terminfo entry for SSH/tmux sessions.
      # This avoids terminal capability queries leaking through when the local
      # terminal, SSH session, and remote tmux terminfo do not align cleanly.
      set -g default-terminal "screen-256color"
      set -g allow-passthrough off
      set -as terminal-overrides ",xterm-256color:RGB"
      set -as terminal-overrides ",screen-256color:RGB"
      set -as terminal-overrides ",tmux-256color:RGB"
      set -as terminal-overrides ",vte-256color:RGB"

      set -g mouse on
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g history-limit 100000

      set -g status-position bottom
      set -g status-interval 5
      set -g status-justify left
      set -g status-style "bg=#151515,fg=#E8E3E3"
      set -g message-style "bg=#8DA3B9,fg=#151515"
      set -g mode-style "bg=#8AA6A2,fg=#151515"

      set -g pane-border-style "fg=#424242"
      set -g pane-active-border-style "fg=#D9BC8C"

      setw -g window-status-format " #I:#W "
      setw -g window-status-current-format " #I:#W "
      setw -g window-status-style "bg=#151515,fg=#8AA6A2"
      setw -g window-status-current-style "bg=#D9BC8C,fg=#151515,bold"
      setw -g window-status-activity-style "bg=#151515,fg=#B66467"

      set -g status-left-length 32
      set -g status-right-length 64
      set -g status-left " #[fg=#D9BC8C,bold]tmux #[fg=#E8E3E3]#S "
      set -g status-right " #[fg=#8AA6A2]%Y-%m-%d #[fg=#E8E3E3]%H:%M "
    '';
  };

  # User accounts
  users.users.mlundquist = {
    isNormalUser = true;
    description = "mlundquist";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "media" "video" "audio" "shares" ];
    # Set your password using: passwd mlundquist
    # Or use hashedPassword here
  };

  # Create shares group with GID 1002 to match Proxmox host permissions
  users.groups.shares = {
    gid = 1002;
  };

  # Enable XFCE desktop environment
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm = {
      enable = true;
      autoLogin = {
        enable = true;
        user = "mlundquist";
      };
    };

    # Explicitly configure NVIDIA device with BusID
    deviceSection = ''
      BusID "PCI:1:0:0"
      Option "ConnectedMonitor" "DFP-0"
      Option "ModeValidation" "AllowNonEdidModes, NoVertRefreshCheck, NoHorizSyncCheck, NoMaxPClkCheck"
      Option "AllowEmptyInitialConfiguration" "False"
    '';

    screenSection = ''
      Option "metamodes" "DFP-0: 1920x1080_60 +0+0"
      DefaultDepth 24
    '';
  };

  # Performance optimizations for VM
  services.journald.extraConfig = ''
    SystemMaxUse=100M
  '';

  # Reduce swappiness for better performance
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  # Allow unfree packages (needed for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # Enable experimental features for flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection to prevent disk filling up
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Fonts configuration
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    (nerd-fonts.jetbrains-mono or (nerdfonts.override { fonts = [ "JetBrainsMono" ]; }))
    jetbrains-mono
    font-awesome
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    pciutils
    git
    htop
    tailscale
    (unstablePkgs.ollama.override { acceleration = "cuda"; })  # Use latest version with CUDA
    python3  # Python 3.13 (default via overlay)
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.boto3
    (pkgs.lib.meta.lowPrio pkgs.python314)  # Python 3.14 available via 'python3.14'
    kitty.terminfo
    neovim
    zsh
    tigervnc  # High-performance VNC server (x0vncserver)

    # Theming
    arc-theme
    tela-icon-theme
    bibata-cursors
    adwaita-qt
    libsForQt5.qt5ct
    lxappearance  # GTK theme configuration tool

    # GUI Applications
    firefox
    thunderbird
    gimp
    blender
    nautilus  # GNOME Files
    obs-studio
    remmina
    mpv
    imv  # Image viewer
    zathura  # PDF viewer
    file-roller  # Archive manager

    # Development tools
    texliveFull
    pandoc
    biber
    librsvg

    # System utilities
    bat
    ripgrep
    fd
    fzf
    zoxide
    brightnessctl
    pavucontrol
    gvfs  # Virtual filesystems for Nautilus
    udiskie
    trash-cli
    tree-sitter
    fastfetch
    btop

    # CLI tools
    jq
    yq
    tmux
    ranger
    yazi
    yt-dlp
    rsync
    unzip
    zip

    # LLM service switching scripts
    (pkgs.writeShellApplication {
      name = "llm-status";
      runtimeInputs = with pkgs; [ systemd gnugrep ];
      text = ''
        echo "=== LLM Service Status ==="
        echo ""
        echo "Ollama:"
        systemctl is-active ollama && echo "  ✓ Running" || echo "  ✗ Stopped"
        echo ""
        echo "GPU Usage:"
        nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | head -1 | {
          read -r used total
          echo "  VRAM: ''${used}MB / ''${total}MB"
        }
      '';
    })

    # AI Trading environment helper scripts
    (pkgs.writeShellApplication {
      name = "ai-trading-setup";
      runtimeInputs = with pkgs; [ python312 git ];
      text = ''
        VENV_DIR="$HOME/ai-trading-venv"
        TRADING_DIR="$HOME/ai-trading"

        echo "=== AI Trading Setup ==="
        echo ""

        # Ensure venv exists
        if [ ! -d "$VENV_DIR" ]; then
          echo "[1/6] Creating virtual environment..."
          python3 -m venv "$VENV_DIR"
        else
          echo "[1/6] Virtual environment exists."
        fi

        # shellcheck disable=SC1091
        source "$VENV_DIR/bin/activate"

        echo "[2/6] Upgrading pip..."
        pip install --upgrade pip setuptools wheel

        echo "[3/6] Installing PyTorch with CUDA 12.8..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

        echo "[4/6] Installing trading and ML packages..."
        pip install \
          yfinance \
          pandas \
          numpy \
          scikit-learn \
          xgboost \
          matplotlib \
          seaborn \
          jupyter \
          ipykernel \
          notebook \
          jupyterlab \
          fastapi \
          'uvicorn[standard]' \
          httpx \
          websockets \
          lean

        echo "[5/6] Setting up TradingAgents..."
        mkdir -p "$TRADING_DIR"
        if [ ! -d "$TRADING_DIR/TradingAgents" ]; then
          git clone https://github.com/TauricResearch/TradingAgents.git "$TRADING_DIR/TradingAgents"
          pip install -e "$TRADING_DIR/TradingAgents"
        else
          echo "  TradingAgents already cloned. Updating..."
          cd "$TRADING_DIR/TradingAgents"
          git pull
          pip install -e .
        fi

        echo "[6/6] Registering Jupyter kernel..."
        python -m ipykernel install --user --name ai-trading --display-name "AI Trading (Python 3.12 + CUDA)"

        echo ""
        echo "=== Setup Complete ==="
        echo "Run 'ai-trading-verify' to check the installation."
      '';
    })
    (pkgs.writeShellApplication {
      name = "ai-trading-verify";
      runtimeInputs = [ ];
      text = ''
        VENV_DIR="$HOME/ai-trading-venv"

        if [ ! -d "$VENV_DIR" ]; then
          echo "ERROR: Virtual environment not found at $VENV_DIR"
          echo "Run 'ai-trading-setup' first."
          exit 1
        fi

        # shellcheck disable=SC1091
        source "$VENV_DIR/bin/activate"

        echo "=== AI Trading Environment Verification ==="
        echo ""

        echo "--- System GPU ---"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo "FAIL: nvidia-smi not available"
        echo ""

        echo "--- Python ---"
        python --version
        echo ""

        echo "--- PyTorch CUDA ---"
        python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available:  {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version:    {torch.version.cuda}')
    print(f'GPU device:      {torch.cuda.get_device_name(0)}')
    try:
        print(f'GPU memory:      {torch.cuda.get_device_properties(0).total_mem / 1024**3:.1f} GB')
    except Exception:
        print('GPU memory:      (could not query)')
else:
    print('WARNING: CUDA not available!')
" || echo "FAIL: PyTorch import failed"
        echo ""

        echo "--- Package Availability ---"
        for pkg in yfinance pandas numpy sklearn xgboost matplotlib jupyter fastapi uvicorn; do
          if python -c "import $pkg" 2>/dev/null; then
            echo "  OK: $pkg"
          else
            echo "  MISSING: $pkg"
          fi
        done
        echo ""

        echo "--- Docker GPU ---"
        if docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null; then
          echo "  OK: Docker GPU passthrough working"
        else
          echo "  WARN: Docker GPU test failed (may need: docker pull nvidia/cuda:12.8.0-base-ubuntu22.04)"
        fi
        echo ""

        echo "--- LEAN Docker ---"
        if docker image inspect quantconnect/lean:latest >/dev/null 2>&1; then
          echo "  OK: LEAN image available"
        else
          echo "  WARN: LEAN image not pulled (run 'ai-trading-lean' to pull)"
        fi
        echo ""

        echo "=== Verification Complete ==="
      '';
    })
    (pkgs.writeShellApplication {
      name = "ai-trading-jupyter";
      runtimeInputs = [ ];
      text = ''
        VENV_DIR="$HOME/ai-trading-venv"
        if [ ! -d "$VENV_DIR" ]; then
          echo "ERROR: Run 'ai-trading-setup' first."
          exit 1
        fi
        # shellcheck disable=SC1091
        source "$VENV_DIR/bin/activate"
        echo "Starting Jupyter Lab on port 8888..."
        echo "Access at: http://$(hostname -I | awk '{print $1}'):8888"
        jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
      '';
    })
    (pkgs.writeShellApplication {
      name = "ai-trading-lean";
      runtimeInputs = with pkgs; [ docker ];
      text = ''
        echo "Pulling QuantConnect LEAN Docker image..."
        docker pull quantconnect/lean:latest
        echo ""
        echo "Pulling LEAN foundation image..."
        docker pull quantconnect/lean:foundation
        echo ""
        echo "Testing LEAN Docker GPU access..."
        docker run --rm --gpus all quantconnect/lean:latest nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null \
          && echo "OK: LEAN Docker has GPU access" \
          || echo "Note: LEAN image may not include nvidia-smi. GPU access is handled by the container toolkit."
        echo ""
        echo "LEAN Docker images ready."
        echo "Use 'lean init' in a project directory to start a LEAN project."
      '';
    })
  ];

  # Environment variables for theming
  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  # Enable XDG Desktop Portal for screen sharing and remote access
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Enable Tailscale
  services.tailscale.enable = true;
  
  # Enable Ollama service
  services.ollama = {
    enable = true;
    acceleration = "cuda"; # Use NVIDIA CUDA acceleration
    package = unstablePkgs.ollama.override { acceleration = "cuda"; }; # Use latest version with CUDA
    host = "0.0.0.0"; # Listen on all interfaces
    port = 11434;
    environmentVariables = {
      # Allow requests from OpenWebUI
      OLLAMA_ORIGINS = "*";
      # Keep only one model resident to limit RAM/VRAM pressure
      OLLAMA_MAX_LOADED_MODELS = "1";
      # Reduce KV cache VRAM usage (halves KV cache memory vs f16)
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      # Enable flash attention for more efficient attention computation
      OLLAMA_FLASH_ATTENTION = "1";
    };
  };

  # TradingAgents Chainlit web UI service
  systemd.services.trading-agents = {
    description = "TradingAgents Chainlit Web UI";
    after = [ "network.target" "ollama.service" ];
    wantedBy = [ ];  # Don't auto-start; use 'ai-trading-web' to start

    environment = {
      HOME = "/home/mlundquist";
      CUDA_VISIBLE_DEVICES = "0";
      LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ]}:/run/opengl-driver/lib";
      CUDA_HOME = "/run/opengl-driver";
    };

    serviceConfig = {
      Type = "simple";
      User = "mlundquist";
      Group = "users";
      WorkingDirectory = "/home/mlundquist/ai-trading/TradingAgents";
      ExecStart = "/home/mlundquist/ai-trading-venv/bin/chainlit run chainlit_app.py --host 0.0.0.0 --port 8080";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Store Ollama models on the larger /onyx volume
  fileSystems."/var/lib/ollama/models" = {
    device = "/onyx/ollama-data/models";
    options = [ "bind" "nofail" "x-systemd.requires=onyx.mount" "x-systemd.after=onyx.mount" ];
  };

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # NVIDIA Container Toolkit for Docker GPU access (needed for QuantConnect LEAN)
  hardware.nvidia-container-toolkit.enable = true;

  # The CDI generator is a short-lived process that gets killed mid-run during
  # nixos-rebuild switch when the NVIDIA driver changes, causing restart-limit failures.
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    serviceConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 60;
    };
  };

  # Enable Proxmox guest agent for VM integration
  services.qemuGuest.enable = true;

  # Enable time synchronization
  services.timesyncd.enable = true;

  # Open ports in the firewall
  networking.firewall.allowedTCPPorts = [ 5900 11434 8888 8080 ];  # VNC, Ollama, Jupyter, FastAPI
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether (not recommended for production)
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
