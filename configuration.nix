# NixOS configuration for nix-python VM
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

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

  # Enable NVIDIA drivers for passthrough GPU (headless, no X server needed)
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
    extraGroups = [ "networkmanager" "wheel" "docker" "media" "video" "audio" ];
    # Set your password using: passwd mlundquist
    # Or use hashedPassword here
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
  };

  # Allow unfree packages (needed for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # Enable experimental features for flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    pciutils
    git
    htop
    tailscale
    ollama
    kitty.terminfo
    neovim
    zsh
    x11vnc  # VNC server for X11
  ];

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
  networking.firewall.allowedTCPPorts = [ 5900 ];  # wayvnc
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
