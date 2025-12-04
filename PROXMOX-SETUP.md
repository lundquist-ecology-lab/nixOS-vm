# Setting Up NixOS VM on Proxmox

This guide covers creating a new NixOS VM on Proxmox with GPU passthrough and virtiofs shared folders.

## Prerequisites

- Proxmox VE host with IOMMU enabled
- NixOS ISO downloaded to Proxmox
- NVIDIA GPU available for passthrough (RTX 5060 Ti)
- Host directories prepared for virtiofs sharing

## Step 1: Enable IOMMU (if not already done)

On your Proxmox host:

1. Edit GRUB configuration:
   ```bash
   nano /etc/default/grub
   ```

2. For AMD CPU, modify the line:
   ```
   GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
   ```

3. Update GRUB and reboot:
   ```bash
   update-grub
   reboot
   ```

4. Verify IOMMU is enabled:
   ```bash
   dmesg | grep -e DMAR -e IOMMU
   ```

## Step 2: Prepare NVIDIA GPU for Passthrough

1. Identify your GPU's PCI ID:
   ```bash
   lspci -nn | grep NVIDIA
   ```
   Look for something like: `01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GB206 [10de:XXXX]`

2. Add GPU to VFIO (replace with your actual IDs):
   ```bash
   echo "options vfio-pci ids=10de:XXXX,10de:YYYY" > /etc/modprobe.d/vfio.conf
   ```
   (XXXX is GPU ID, YYYY is audio device ID from the same card)

3. Blacklist NVIDIA drivers on host:
   ```bash
   echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
   echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf
   ```

4. Update initramfs:
   ```bash
   update-initramfs -u -k all
   reboot
   ```

## Step 3: Download NixOS ISO

1. Go to Proxmox web UI → your node → local storage → ISO Images
2. Click "Download from URL"
3. URL: `https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso`
4. Or use the graphical ISO for easier installation

## Step 4: Create VM via Proxmox Web UI

1. **Click "Create VM" in top-right**

2. **General Tab**:
   - VM ID: Choose an available ID (e.g., 100)
   - Name: `nix-python`
   - Start at boot: ✓ (if desired)

3. **OS Tab**:
   - ISO image: Select the NixOS ISO
   - Guest OS Type: Linux
   - Version: 6.x - 2.6 Kernel

4. **System Tab**:
   - Machine: q35
   - BIOS: OVMF (UEFI)
   - Add EFI Disk: ✓
   - EFI Storage: local-lvm (or your preferred storage)
   - SCSI Controller: VirtIO SCSI single
   - Qemu Agent: ✓ (optional)

5. **Disks Tab**:
   - Bus/Device: SCSI 0
   - Storage: Choose your storage
   - Disk size: 120GB (or match your current setup)
   - Cache: Write back (for better performance)
   - Discard: ✓ (if using SSD)
   - SSD emulation: ✓ (if on SSD)

6. **CPU Tab**:
   - Sockets: 1
   - Cores: 32 (to match your current setup)
   - Type: host (for best performance)

7. **Memory Tab**:
   - Memory: 131072 MB (128 GB)
   - Ballooning: Disabled (uncheck)

8. **Network Tab**:
   - Bridge: vmbr0 (or your main bridge)
   - Model: VirtIO (paravirtualized)

9. **Confirm** and create the VM

## Step 5: Configure VM for GPU Passthrough (via Shell)

SSH to your Proxmox host and edit the VM config (replace 100 with your VM ID):

```bash
nano /etc/pve/qemu-server/100.conf
```

Add these lines:

```conf
# GPU Passthrough - replace with your actual PCI IDs
hostpci0: 0000:01:00,pcie=1,x-vga=1

# CPU configuration
cpu: host,hidden=1,flags=+pcid
args: -cpu host,kvm=off,hv_vendor_id=proxmox

# Machine type
machine: q35
```

## Step 6: Add Virtiofs Shared Folders

Continue editing `/etc/pve/qemu-server/100.conf`:

```conf
# Virtiofs shared folders
args: -object memory-backend-memfd,id=mem,size=131072M,share=on -numa node,memdev=mem -chardev socket,id=char-peppy,path=/var/run/vm-100-peppy.sock -device vhost-user-fs-pci,queue-size=1024,chardev=char-peppy,tag=peppy -chardev socket,id=char-onyx,path=/var/run/vm-100-onyx.sock -device vhost-user-fs-pci,queue-size=1024,chardev=char-onyx,tag=onyx
```

**Note**: The `args` line should be merged with any existing args. Don't create multiple `args:` lines.

## Step 7: Create Virtiofsd Services

For each shared folder, create a systemd service:

```bash
# Service for peppy share
cat > /etc/systemd/system/virtiofsd-peppy-100.service << 'EOF'
[Unit]
Description=Virtiofs daemon for VM 100 peppy share
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/libexec/virtiofsd \
    --socket-path=/var/run/vm-100-peppy.sock \
    --shared-dir=/path/to/peppy \
    --cache=always \
    --sandbox=none
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Service for onyx share
cat > /etc/systemd/system/virtiofsd-onyx-100.service << 'EOF'
[Unit]
Description=Virtiofs daemon for VM 100 onyx share
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/libexec/virtiofsd \
    --socket-path=/var/run/vm-100-onyx.sock \
    --shared-dir=/path/to/onyx \
    --cache=always \
    --sandbox=none
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

**Important**: Replace `/path/to/peppy` and `/path/to/onyx` with actual paths on your Proxmox host.

Enable and start the services:

```bash
systemctl daemon-reload
systemctl enable --now virtiofsd-peppy-100.service
systemctl enable --now virtiofsd-onyx-100.service
```

## Step 8: Install virtiofsd on Proxmox (if not present)

```bash
apt update
apt install virtiofsd
```

## Step 9: Start the VM and Install NixOS

1. Start the VM from Proxmox web UI
2. Open the console (noVNC or xterm.js)
3. Boot from the NixOS ISO
4. Follow the installation steps from the main README.md

### Quick Installation Commands:

```bash
# Partition the disk
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# Generate config (this creates a base config)
nixos-generate-config --root /mnt

# Replace with your custom configs
# (You'll need to copy configuration.nix and hardware-configuration.nix to /mnt/etc/nixos/)
# Options:
# 1. Use curl/wget to download from a URL
# 2. Use the virtiofs mounts if available
# 3. Manually edit the files in the console

# Install
nixos-install

# Set password
nixos-enter --root /mnt -c 'passwd mlundquist'

# Reboot
reboot
```

## Step 10: Transfer Configuration Files

### Option A: Via virtiofs (if accessible during install)

```bash
# If your shares are mounted in the live environment
cp /mnt/peppy/path/to/configuration.nix /mnt/etc/nixos/
cp /mnt/peppy/path/to/hardware-configuration.nix /mnt/etc/nixos/
```

### Option B: Via network (if you have connectivity)

```bash
# On the NixOS installer, get the config files
curl -o /mnt/etc/nixos/configuration.nix https://your-url/configuration.nix
curl -o /mnt/etc/nixos/hardware-configuration.nix https://your-url/hardware-configuration.nix
```

### Option C: Manual copy-paste

Edit the files in nano/vim and paste the content.

## Alternative: Clone Existing VM

If you want to convert your existing Arch VM:

1. **Backup** your current VM
2. Create a new VM as above
3. **Detach** the disk from the old VM
4. **Attach** it to the new NixOS VM
5. This preserves your data, but you'll still need to install NixOS

## Troubleshooting

### GPU Not Working
- Verify IOMMU groups: `find /sys/kernel/iommu_groups/ -type l`
- Check if GPU is bound to vfio-pci: `lspci -nnk | grep -A 3 NVIDIA`
- Ensure `x-vga=1` is set in hostpci0

### Virtiofs Not Mounting
- Check virtiofsd services: `systemctl status virtiofsd-peppy-100.service`
- Verify socket files exist: `ls -l /var/run/vm-100-*.sock`
- Check VM logs: `/var/log/syslog` or `journalctl -u qemu-server@100.service`

### VM Won't Boot
- Check VM config syntax: `cat /etc/pve/qemu-server/100.conf`
- Remove GPU passthrough temporarily to isolate the issue
- Use VNC console instead of GPU output initially

## Post-Installation Verification

After booting into NixOS:

```bash
# Check GPU
nvidia-smi

# Check mounts
df -h | grep mnt

# Check services
systemctl status docker tailscaled sshd

# Check network
ip addr show
```

## Performance Tuning

Consider these optimizations in your VM config:

```conf
# In /etc/pve/qemu-server/100.conf
cpu: host,hidden=1,flags=+pcid
numa: 1
hugepages: 1024
```

Then on Proxmox host, enable hugepages:

```bash
echo "vm.nr_hugepages = 66000" >> /etc/sysctl.conf
sysctl -p
```

## Notes

- VM ID 100 is used as an example - adjust to your actual VM ID throughout
- The q35 machine type is required for modern GPU passthrough
- OVMF (UEFI) is required for most modern GPUs
- Virtiofs requires memory-backend-memfd, which is why we configure shared memory
