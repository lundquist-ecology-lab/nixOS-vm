#!/bin/bash
# Script to create NixOS VM on Proxmox
# Run this on your Proxmox host
# Based on working config from VM 9000 (arch-python)

set -e

# Configuration - ADJUST THESE VALUES
VMID=9005
VM_NAME="nix-python"
STORAGE="onyx-dir"  # Your storage name (check with: pvesm status)
ISO_STORAGE="local"  # Where ISOs are stored
NIXOS_ISO="nixos-24.11-minimal-x86_64-linux.iso"  # Adjust to actual ISO name
BRIDGE="vmbr0"
MEMORY=131072  # 128 GB
BALLOON=32768  # 32 GB balloon memory
CORES=32
DISK_SIZE="150G"

# GPU PCI IDs - Both GPU and audio device
GPU_PCI_ID="01:00.0"      # GPU device
GPU_AUDIO_PCI_ID="01:00.1"  # GPU audio device

# Virtiofs share names (must match host configuration)
# These are the share names, not paths - paths are configured on Proxmox host
PEPPY_SHARE="peppy"
ONYX_SHARE="onyx"

echo "Creating NixOS VM with ID $VMID..."

# Create the VM (matching working config from VM 9000)
qm create $VMID \
  --name $VM_NAME \
  --memory $MEMORY \
  --balloon $BALLOON \
  --cores $CORES \
  --cpu host \
  --machine q35 \
  --bios ovmf \
  --efidisk0 ${STORAGE}:1,pre-enrolled-keys=1 \
  --scsihw virtio-scsi-pci \
  --scsi0 ${STORAGE}:${DISK_SIZE} \
  --ide2 ${ISO_STORAGE}:iso/${NIXOS_ISO},media=cdrom \
  --net0 virtio,bridge=$BRIDGE \
  --boot order=scsi0 \
  --ostype l26 \
  --numa 1 \
  --onboot 1 \
  --agent 1 \
  --vga virtio

echo "VM created. Adding GPU passthrough..."

# Add GPU and GPU audio passthrough
qm set $VMID --hostpci0 ${GPU_PCI_ID},pcie=1
qm set $VMID --hostpci1 ${GPU_AUDIO_PCI_ID},pcie=1

echo "Adding virtiofs shared folders..."

# Add virtiofs mounts (modern Proxmox method - no manual services needed!)
qm set $VMID --virtiofs0 ${PEPPY_SHARE},direct-io=1,expose-acl=1
qm set $VMID --virtiofs1 ${ONYX_SHARE},direct-io=1,expose-acl=1

echo ""
echo "========================================="
echo "VM created successfully!"
echo "========================================="
echo "VM ID: $VMID"
echo "Name: $VM_NAME"
echo "Storage: $STORAGE"
echo "Memory: ${MEMORY}MB (Balloon: ${BALLOON}MB)"
echo "Cores: $CORES"
echo ""
echo "GPU Passthrough:"
echo "  - GPU: ${GPU_PCI_ID}"
echo "  - Audio: ${GPU_AUDIO_PCI_ID}"
echo ""
echo "Virtiofs Shares:"
echo "  - ${PEPPY_SHARE} → /mnt/peppy (in VM)"
echo "  - ${ONYX_SHARE} → /mnt/onyx (in VM)"
echo ""
echo "NOTE: Virtiofs shares must be configured on Proxmox host!"
echo "Configure in: Datacenter → Storage → Add → Directory"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo ""
echo "1. Verify VM configuration:"
echo "   cat /etc/pve/qemu-server/${VMID}.conf"
echo ""
echo "2. Start the VM:"
echo "   qm start $VMID"
echo ""
echo "3. Connect via console (Web UI or):"
echo "   qm terminal $VMID"
echo ""
echo "4. Install NixOS:"
echo "   See README.md for installation instructions"
echo "   Copy configuration.nix and hardware-configuration.nix to /mnt/etc/nixos/"
echo ""
echo "5. After first boot, verify:"
echo "   - nvidia-smi (GPU)"
echo "   - ls /mnt/peppy /mnt/onyx (shares)"
echo "   - docker ps (Docker)"
echo "   - sudo tailscale up (Tailscale)"
echo ""
echo "========================================="
