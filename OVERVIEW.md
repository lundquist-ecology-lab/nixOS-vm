# NixOS VM Setup - Complete Overview

This repository contains everything you need to recreate your current Arch Linux VM (9000) as a NixOS VM (9005) on Proxmox.

## What This Repository Contains

### 📋 NixOS Configuration Files

**configuration.nix**
- Main system configuration
- Services: Docker, Tailscale, SSH, NetworkManager
- NVIDIA GPU drivers for RTX 5060 Ti
- User account: mlundquist
- Hostname: nix-python
- Timezone: US/Eastern
- All your current services configured

**hardware-configuration.nix**
- Hardware-specific settings
- Boot configuration (UEFI/OVMF)
- Filesystem mounts (root, boot, virtiofs shares)
- CPU/network configuration
- Based on your actual VM 9000 hardware

### 🚀 Proxmox Setup Tools

**create-vm.sh** (Executable script)
- One-command VM creation
- Creates VM 9005 matching your VM 9000 configuration
- Sets up GPU passthrough (01:00.0, 01:00.1)
- Configures virtiofs shares (peppy, onyx)
- Uses your existing storage: onyx-dir

**Run on Proxmox host:**
```bash
# Review settings (may need to adjust NIXOS_ISO filename)
nano create-vm.sh

# Create the VM
bash create-vm.sh
```

### 📖 Documentation

**QUICK-START.md**
- Fastest path from zero to running NixOS VM
- Step-by-step commands
- Minimal explanation, maximum speed
- **Start here if you want to get going quickly**

**PROXMOX-SETUP.md**
- Detailed Proxmox configuration guide
- Manual VM creation steps
- GPU passthrough explanation
- Troubleshooting section

**PROXMOX-VIRTIOFS.md**
- Deep dive into virtiofs configuration
- How your peppy/onyx shares work
- Adding new shared folders
- Performance tuning

**README.md**
- System overview
- Features list
- Installation instructions for NixOS

**OVERVIEW.md** (This file)
- High-level summary
- Workflow guidance
- File descriptions

## The Complete Workflow

### Phase 1: Prepare on Proxmox Host

```bash
# 1. Copy this repository to your Proxmox host
#    (e.g., via git clone, scp, or the virtiofs mounts)

# 2. Verify prerequisites
pvesm status                    # Check onyx-dir storage exists
ls /var/lib/vz/template/iso/    # Find NixOS ISO filename
qm list | grep 9005             # Ensure VM ID is free

# 3. Edit create-vm.sh if needed
nano create-vm.sh
# Only change: NIXOS_ISO filename if different

# 4. Run the script
bash create-vm.sh

# 5. Verify
cat /etc/pve/qemu-server/9005.conf
```

### Phase 2: Install NixOS in the VM

```bash
# 1. Start VM
qm start 9005

# 2. Open console (Proxmox web UI or)
qm terminal 9005

# 3. In the VM, partition and format disk
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# 4. Mount filesystems
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# 5. Copy configuration files
mkdir -p /mnt/etc/nixos

# If virtiofs is accessible in the installer:
cp /mnt/peppy/git/nixOS-vm/configuration.nix /mnt/etc/nixos/
cp /mnt/peppy/git/nixOS-vm/hardware-configuration.nix /mnt/etc/nixos/

# Otherwise, manually create them or wget from a URL

# 6. Install NixOS
nixos-install

# 7. Set password
nixos-enter --root /mnt -c 'passwd mlundquist'

# 8. Reboot
reboot
```

### Phase 3: Post-Installation Setup

```bash
# After booting into NixOS:

# 1. Join Tailscale
sudo tailscale up

# 2. Verify GPU
nvidia-smi

# 3. Check mounts
ls /mnt/peppy
ls /mnt/onyx

# 4. Test Docker
docker ps

# 5. Verify network
ip addr show
```

## Key Differences from VM 9000

| Aspect | VM 9000 (arch-python) | VM 9005 (nix-python) |
|--------|----------------------|---------------------|
| OS | Arch Linux | NixOS 24.11 |
| VM ID | 9000 | 9005 |
| Hostname | arch-python | nix-python |
| Config Management | pacman, manual | Declarative nix files |
| GPU | ✅ RTX 5060 Ti | ✅ Same GPU |
| Docker | ✅ Enabled | ✅ Enabled |
| Tailscale | ✅ Running | ✅ Configured |
| Virtiofs | ✅ peppy, onyx | ✅ Same shares |
| Memory | 128 GB | 128 GB |
| Cores | 32 | 32 |
| Storage | onyx-dir | onyx-dir |

## Hardware Configuration Summary

**From your VM 9000 config:**
```
CPU: AMD Ryzen 9 9950X3D (32 cores)
Memory: 128 GB (32 GB balloon)
Storage: onyx-dir (qcow2)
GPU: NVIDIA RTX 5060 Ti (01:00.0 + 01:00.1)
Network: virtio on vmbr0
Machine: q35
BIOS: OVMF (UEFI)
Virtiofs: peppy, onyx (with direct-io)
```

## Troubleshooting Quick Reference

**VM won't start:**
```bash
cat /etc/pve/qemu-server/9005.conf    # Check config
journalctl -u qemu-server@9005.service # Check logs
```

**GPU not working:**
```bash
# In VM
lspci | grep NVIDIA
nvidia-smi
dmesg | grep -i nvidia
```

**Virtiofs not mounting:**
```bash
# In VM
systemctl status mnt-peppy.mount
journalctl -u mnt-peppy.mount
ls -ld /mnt/peppy
```

**Can't access VM console:**
- Use Proxmox web UI → VM 9005 → Console
- Try VNC option if serial doesn't work
- GPU passthrough may disable VNC after boot

## Next Steps After Installation

1. **Customize NixOS configuration:**
   ```bash
   sudo nano /etc/nixos/configuration.nix
   sudo nixos-rebuild switch
   ```

2. **Install additional packages:**
   Add to `environment.systemPackages` in configuration.nix

3. **Set up development environment:**
   Your Docker containers and tools can be configured declaratively

4. **Explore NixOS benefits:**
   - Atomic updates
   - Rollback capability
   - Reproducible builds
   - Declarative configuration

## Resources

- **NixOS Manual:** https://nixos.org/manual/nixos/stable/
- **NixOS Options:** https://search.nixos.org/options
- **NixOS Packages:** https://search.nixos.org/packages
- **Proxmox Wiki:** https://pve.proxmox.com/wiki/Main_Page

## Getting Help

If something doesn't work:

1. Check the troubleshooting sections in the documentation
2. Review logs: `journalctl -xe`
3. Verify configuration: `cat /etc/pve/qemu-server/9005.conf`
4. Compare with working VM 9000: `cat /etc/pve/qemu-server/9000.conf`

## Summary

This repository provides a turnkey solution to recreate your Proxmox VM with NixOS while preserving all your hardware configuration, services, and shared folders. The `create-vm.sh` script automates the Proxmox setup, and the NixOS configuration files ensure your new VM matches your current setup.

**Estimated time:** 30-60 minutes from start to fully running NixOS VM.
