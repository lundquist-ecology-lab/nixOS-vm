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

  # Enable NVIDIA drivers
  # Note: This is for the passthrough GeForce RTX 5060 Ti
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;

    # Power management (experimental, can cause sleep/suspend issues)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use the open source kernel module (for newer cards)
    # Set to false if you have stability issues
    open = false;

    # Enable the Nvidia settings menu
    nvidiaSettings = true;

    # Select the appropriate driver version for your card
    # For RTX 5060 Ti, use the latest production driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # User accounts
  users.users.mlundquist = {
    isNormalUser = true;
    description = "mlundquist";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # Set your password using: passwd mlundquist
    # Or use hashedPassword here
  };

  # Enable automatic login (optional, comment out if not desired)
  # services.getty.autologinUser = "mlundquist";

  # Allow unfree packages (needed for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tailscale
    ollama
  ];

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

  # Enable time synchronization
  services.timesyncd.enable = true;

  # Open ports in the firewall (adjust as needed)
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether (not recommended for production)
  # networking.firewall.enable = false;

  # Enable virtiofs support for shared folders
  boot.kernelModules = [ "virtiofs" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
