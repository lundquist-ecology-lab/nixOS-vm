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

    package = config.boot.kernelPackages.nvidiaPackages.beta;  # Use beta driver for latest GPU support
  };

  boot.blacklistedKernelModules = [ "nouveau" "nvidiafb" ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  # Load NVIDIA stack during normal boot (not initrd), plus virtiofs for shared folders
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "virtiofs" ];

  # Enable zsh system-wide
  programs.zsh.enable = true;

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
    unstablePkgs.ollama  # Use latest version from unstable for newer models
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
  
  # Enable Ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda"; # Use NVIDIA CUDA acceleration
    package = unstablePkgs.ollama; # Use latest version for devstral-small-2 support
  };

  # Force Ollama to listen on all interfaces for Docker access
  systemd.services.ollama.environment = {
    OLLAMA_HOST = pkgs.lib.mkForce "0.0.0.0:11434"; # override module default
    # Allow requests from OpenWebUI
    OLLAMA_ORIGINS = "*";
    # Keep only one model resident to limit RAM/VRAM pressure
    OLLAMA_MAX_LOADED_MODELS = "1";
  };

  # Store Ollama models on the larger /onyx volume
  fileSystems."/var/lib/ollama/models" = {
    device = "/onyx/ollama-data/models";
    options = [ "bind" ];
  };

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Enable Proxmox guest agent for VM integration
  services.qemuGuest.enable = true;

  # Enable time synchronization
  services.timesyncd.enable = true;

  # Open ports in the firewall
  networking.firewall.allowedTCPPorts = [ 5900 11434 ];  # x0vncserver (TigerVNC), Ollama API
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
