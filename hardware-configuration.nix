# Hardware configuration for nix-python VM
# Generated from VM 9000 (arch-python) on 2025-12-02
# Target VM: 9005 (nix-python)

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Root filesystem
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8b6fc16e-5626-42ab-b759-30cc561ca1f1";
    fsType = "ext4";
  };

  # EFI boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0ABC-3202";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Virtiofs mounts (shared folders from host)
  fileSystems."/mnt/peppy" = {
    device = "peppy";
    fsType = "virtiofs";
    options = [ "rw" "x-systemd.automount" "_netdev" "nofail" ];
  };

  fileSystems."/mnt/onyx" = {
    device = "onyx";
    fsType = "virtiofs";
    options = [ "rw" "x-systemd.automount" "_netdev" "nofail" ];
  };

  # No swap configured
  swapDevices = [ ];

  # CPU configuration - AMD Ryzen 9 9950X3D
  # Enables microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Networking hardware
  # Primary interface: ens18
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.ens18.useDHCP = lib.mkDefault true;

  # High-DPI console font (optional, for better readability on high-res displays)
  # console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
