# NixOS VM Configuration

This directory contains the NixOS configuration files for the `nix-python` VM, generated based on your current VM 9000 (arch-python) setup.

## Quick Start

**Want to create the VM right away?** See [QUICK-START.md](QUICK-START.md)

**Need detailed Proxmox setup info?** See [PROXMOX-SETUP.md](PROXMOX-SETUP.md)

**Questions about virtiofs?** See [PROXMOX-VIRTIOFS.md](PROXMOX-VIRTIOFS.md)

## Files

### NixOS Configuration
- `configuration.nix` - Main system configuration
- `hardware-configuration.nix` - Hardware-specific configuration

### Proxmox Setup
- `create-vm.sh` - Automated script to create the VM on Proxmox (run on host)
- `QUICK-START.md` - Fast path to creating and installing the VM
- `PROXMOX-SETUP.md` - Detailed Proxmox configuration guide
- `PROXMOX-VIRTIOFS.md` - Guide to virtiofs shared folders
- `README.md` - This file

## System Features

The configuration includes:

- **Hostname**: nix-python
- **User**: mlundquist (with sudo access)
- **Services**:
  - Docker (with your user in the docker group)
  - Tailscale
  - OpenSSH
  - NetworkManager
  - Time synchronization
- **Hardware**:
  - NVIDIA GeForce RTX 5060 Ti (passthrough with proprietary drivers)
  - Virtiofs mounts: /mnt/peppy and /mnt/onyx
  - UEFI boot with systemd-boot
- **Locale**: en_US.UTF-8
- **Timezone**: US/Eastern

## Installation Steps

To rebuild this VM as a NixOS system:

1. **Boot from NixOS installation media**
   - Download the latest NixOS ISO from https://nixos.org/download
   - Boot your VM from the ISO

2. **Partition and format your disks** (if starting fresh)
   ```bash
   # This matches your current setup:
   # /dev/sda1 - 512MB EFI partition
   # /dev/sda2 - Root partition (rest of disk)

   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/sda -- set 1 esp on
   parted /dev/sda -- mkpart primary 512MiB 100%

   mkfs.fat -F 32 -n boot /dev/sda1
   mkfs.ext4 -L nixos /dev/sda2
   ```

3. **Mount the filesystems**
   ```bash
   mount /dev/sda2 /mnt
   mkdir -p /mnt/boot/efi
   mount /dev/sda1 /mnt/boot/efi
   ```

4. **Copy the configuration files**
   ```bash
   mkdir -p /mnt/etc/nixos
   # Copy configuration.nix and hardware-configuration.nix to /mnt/etc/nixos/
   ```

5. **Install NixOS**
   ```bash
   nixos-install
   ```

6. **Set user password**
   ```bash
   nixos-enter --root /mnt -c 'passwd mlundquist'
   ```

7. **Reboot**
   ```bash
   reboot
   ```

## Post-Installation

After booting into NixOS:

1. **Join Tailscale network**
   ```bash
   sudo tailscale up
   ```

2. **Verify virtiofs mounts**
   ```bash
   ls /mnt/peppy
   ls /mnt/onyx
   ```

3. **Test Docker**
   ```bash
   docker ps
   ```

## Customization

To modify the system:

1. Edit `/etc/nixos/configuration.nix`
2. Rebuild the system:
   ```bash
   sudo nixos-rebuild switch
   ```

## Notes

- The NVIDIA driver is set to use the stable proprietary driver. If you experience issues, you can try the open-source driver by setting `hardware.nvidia.open = true;` in configuration.nix
- UUIDs in hardware-configuration.nix are from your current system. If you repartition, update these UUIDs using `blkid`
- The virtiofs mounts require your VM host to be configured to share those directories
- You may need to adjust firewall settings in configuration.nix based on your needs
# nixOS-vm
