# Quick Start Guide - NixOS VM on Proxmox

## TL;DR - Fastest Path

### On Your Proxmox Host:

1. **Review and edit the creation script:**
   ```bash
   nano create-vm.sh

   # Values to verify/adjust:
   # - VMID (default: 9005)
   # - STORAGE (default: onyx-dir, matches your existing VM)
   # - NIXOS_ISO (exact filename in your ISO storage)
   # - GPU PCI IDs are already set correctly: 01:00.0 and 01:00.1
   # - Virtiofs shares: peppy and onyx (should already be configured)
   ```

2. **Run the creation script:**
   ```bash
   bash create-vm.sh
   ```

3. **Verify the VM was created:**
   ```bash
   cat /etc/pve/qemu-server/9005.conf
   ```

4. **Start the VM:**
   ```bash
   qm start 9005
   ```

### In the VM Console:

5. **Partition and format (if fresh install):**
   ```bash
   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/sda -- set 1 esp on
   parted /dev/sda -- mkpart primary 512MiB 100%

   mkfs.fat -F 32 -n boot /dev/sda1
   mkfs.ext4 -L nixos /dev/sda2

   mount /dev/sda2 /mnt
   mkdir -p /mnt/boot/efi
   mount /dev/sda1 /mnt/boot/efi
   ```

6. **Copy config files to the mounted system:**
   ```bash
   mkdir -p /mnt/etc/nixos

   # If virtiofs is working in the live environment:
   cp /mnt/peppy/git/nixOS-vm/configuration.nix /mnt/etc/nixos/
   cp /mnt/peppy/git/nixOS-vm/hardware-configuration.nix /mnt/etc/nixos/

   # OR manually create them with nano and paste content:
   nano /mnt/etc/nixos/configuration.nix
   nano /mnt/etc/nixos/hardware-configuration.nix
   ```

7. **Install NixOS:**
   ```bash
   nixos-install
   ```

8. **Set password:**
   ```bash
   nixos-enter --root /mnt -c 'passwd mlundquist'
   ```

9. **Reboot:**
   ```bash
   reboot
   ```

### After First Boot:

10. **Join Tailscale:**
    ```bash
    sudo tailscale up
    ```

11. **Verify everything:**
    ```bash
    # GPU
    nvidia-smi

    # Mounts
    ls /mnt/peppy
    ls /mnt/onyx

    # Docker
    docker ps

    # Network
    ip addr show
    ```

---

## Before You Start

### Prerequisites Checklist:

- [ ] Proxmox host has IOMMU enabled (should be, since VM 9000 works)
- [ ] GPU passthrough is working (confirmed - RTX 5060 Ti on 01:00.0/01:00.1)
- [ ] NixOS ISO downloaded to Proxmox
- [ ] Virtiofs shares `peppy` and `onyx` are configured (already done for VM 9000)
- [ ] VM ID 9005 is available

### Verify Before Running Script:

```bash
# On Proxmox host:

# 1. Check storage pools
pvesm status
# You should see 'onyx-dir' and your ISO storage

# 2. Check NixOS ISO is downloaded
ls /var/lib/vz/template/iso/ | grep -i nixos

# 3. Verify virtiofs shares are configured
cat /etc/pve/storage.cfg | grep -A 3 "peppy\|onyx"

# 4. Verify VM ID 9005 is available
qm list | grep 9005 || echo "VM 9005 is available"
```

---

## Alternative: Manual VM Creation

If you prefer using the Proxmox web UI instead of the script:

1. **Create VM** (use OVMF/UEFI, q35 machine, 32 cores, 128GB RAM)
2. **Edit** `/etc/pve/qemu-server/[VMID].conf` manually
3. **Add** GPU passthrough line: `hostpci0: 0000:01:00,pcie=1,x-vga=1`
4. **Create** virtiofsd services manually
5. **Follow** detailed steps in PROXMOX-SETUP.md

---

## Troubleshooting

**VM won't start:**
- Check config syntax: `cat /etc/pve/qemu-server/100.conf`
- View logs: `journalctl -u qemu-server@100.service`

**No GPU in VM:**
- Verify IOMMU: `dmesg | grep IOMMU`
- Check GPU binding: `lspci -nnk | grep -A 3 NVIDIA`

**Virtiofs not working:**
- Check services: `systemctl status virtiofsd-*`
- Check sockets: `ls -l /var/run/vm-*.sock`

**Can't connect via console:**
- Try VNC instead of Serial console in Proxmox UI
- GPU passthrough may disable VNC; use physical display or remove `x-vga=1` temporarily

---

## Files in This Repository

- `configuration.nix` - Main NixOS config
- `hardware-configuration.nix` - Hardware-specific settings
- `create-vm.sh` - Automated VM creation script
- `PROXMOX-SETUP.md` - Detailed manual setup guide
- `README.md` - NixOS installation and usage guide
- `QUICK-START.md` - This file

---

## Getting Help

- NixOS Manual: `https://nixos.org/manual/nixos/stable/`
- Proxmox Wiki: `https://pve.proxmox.com/wiki/Main_Page`
- GPU Passthrough: `https://pve.proxmox.com/wiki/Pci_passthrough`
