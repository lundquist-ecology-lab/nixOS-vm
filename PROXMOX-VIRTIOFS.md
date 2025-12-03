# Setting Up Virtiofs Shared Folders in Proxmox

Your VM (9000) uses virtiofs to share folders from the Proxmox host to the VM. This document explains how it works and how to configure it for a new VM.

## How Virtiofs Works in Your Setup

Your current VM has these virtiofs mounts:
```
virtiofs0: peppy,direct-io=1,expose-acl=1
virtiofs1: onyx,direct-io=1,expose-acl=1
```

This creates two shared folders:
- `peppy` → accessible in VM at `/mnt/peppy`
- `onyx` → accessible in VM at `/mnt/onyx`

## Proxmox Host Configuration

The virtiofs shares need to be configured as storage on your Proxmox host.

### Check Existing Storage

View your current storage configuration:
```bash
cat /etc/pve/storage.cfg
```

You should see entries for `peppy` and `onyx` directories.

### Example Storage Configuration

In `/etc/pve/storage.cfg`, you might have something like:

```
dir: peppy
        path /mnt/peppy
        content vztmpl,iso,backup
        shared 0

dir: onyx
        path /mnt/onyx
        content images,rootdir
        shared 0
```

Or they might be configured through the web UI under:
**Datacenter → Storage**

## Adding Virtiofs to a New VM

### Method 1: Using qm command (Recommended)

```bash
# Add virtiofs shares to VM 101
qm set 101 --virtiofs0 peppy,direct-io=1,expose-acl=1
qm set 101 --virtiofs1 onyx,direct-io=1,expose-acl=1
```

### Method 2: Edit VM config directly

Edit `/etc/pve/qemu-server/101.conf` and add:
```
virtiofs0: peppy,direct-io=1,expose-acl=1
virtiofs1: onyx,direct-io=1,expose-acl=1
```

### Method 3: Proxmox Web UI (if available in your version)

Some Proxmox versions support adding virtiofs through the web UI:
1. Select VM → Hardware → Add → VirtIO-FS
2. Configure the share name and options

## Virtiofs Options Explained

- **Tag name** (`peppy`, `onyx`): The identifier used to mount the share in the VM
- **direct-io=1**: Enable direct I/O (better performance, bypasses page cache)
- **expose-acl=1**: Expose ACL attributes to the guest

## Mounting in the VM (NixOS)

Your `hardware-configuration.nix` already contains the mount configuration:

```nix
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
```

The `device` field matches the tag name in the virtiofs configuration.

## Creating New Shared Folders

To add a new shared folder (e.g., "projects"):

### 1. On Proxmox Host

Create the directory and configure storage:

```bash
# Create directory on host
mkdir -p /mnt/projects

# Add to storage config (or use web UI)
# Edit /etc/pve/storage.cfg and add:
# dir: projects
#         path /mnt/projects
#         content images,rootdir
#         shared 0

# Or via pvesm command:
pvesm add dir projects --path /mnt/projects --content images,rootdir
```

### 2. Add to VM

```bash
qm set 101 --virtiofs2 projects,direct-io=1,expose-acl=1
```

### 3. In NixOS Configuration

Add to `hardware-configuration.nix`:

```nix
fileSystems."/mnt/projects" = {
  device = "projects";
  fsType = "virtiofs";
  options = [ "rw" "x-systemd.automount" "_netdev" "nofail" ];
};
```

Then rebuild:
```bash
sudo nixos-rebuild switch
```

## Troubleshooting

### Share not accessible in VM

Check if virtiofs is configured:
```bash
# On Proxmox host
cat /etc/pve/qemu-server/[VMID].conf | grep virtiofs
```

Check if the VM can see the device:
```bash
# Inside VM
lsmod | grep virtiofs
dmesg | grep virtiofs
```

### Permission issues

Make sure permissions on the host directory allow access:
```bash
# On Proxmox host
ls -ld /mnt/peppy /mnt/onyx
chmod 755 /mnt/peppy /mnt/onyx  # Adjust as needed
```

### Mount fails in VM

Check systemd mount status:
```bash
# Inside VM
systemctl status mnt-peppy.mount
systemctl status mnt-onyx.mount
journalctl -u mnt-peppy.mount
```

Try manual mount:
```bash
# Inside VM (as root)
mkdir -p /mnt/test-peppy
mount -t virtiofs peppy /mnt/test-peppy
```

## Performance Notes

- **direct-io=1**: Recommended for better performance, especially for database files
- **cache=always**: Could be added for better read performance on static files
- For large file operations, virtiofs typically outperforms 9p or NFS

## Comparison with Old Method

Your setup uses the **modern Proxmox virtiofs** implementation, which:
- ✅ Is built into Proxmox (no manual virtiofsd services needed)
- ✅ Simpler configuration
- ✅ Better integrated with Proxmox management
- ✅ More reliable and easier to troubleshoot

The old method required:
- ❌ Manual systemd service creation for virtiofsd
- ❌ Socket file management
- ❌ Complex QEMU args in VM config
- ❌ More maintenance

## Summary

Your current setup is using the **preferred modern method**. For the new NixOS VM:

1. Virtiofs shares `peppy` and `onyx` should already be configured on your Proxmox host
2. Simply add them to the new VM with `qm set` or the creation script
3. The NixOS configuration will automatically mount them at `/mnt/peppy` and `/mnt/onyx`

No additional services or complex configuration needed!
