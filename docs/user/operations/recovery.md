# 🚑 Recovery & Rollbacks

The recovery policy is:

```txt
System state is immutable.
Mistakes are cheap.
Roll back first, debug later.
```

If an update breaks your system (e.g., Wayland doesn't start, Wi-Fi stops working, or a package is broken), rolling back is the fastest way to get back to work.

## 🔄 Rolling Back from a Running System

If your system boots but something isn't working right after a rebuild, you can revert to the previous generation without rebooting:

```sh
doas nixos-rebuild switch --rollback
```

This immediately activates the previous known-good generation and sets it as the default for the next boot.

## 🚀 Rolling Back from a Broken Boot (GRUB)

If an update prevents the system from booting entirely (e.g., kernel panic, black screen, or login loop):

1. **Reboot** the machine.
2. In the **GRUB boot menu**, instead of selecting the default entry, use the arrow keys to scroll down.
3. Select an **older generation** (usually the second one in the list) that you know worked previously.
4. Press `Enter` to boot.

Your system will boot exactly as it was when that generation was created.

### 💾 Making the Boot Rollback Permanent

Booting an older generation from GRUB is a temporary state. If you reboot again, it will try to boot the broken (newest) generation. 

To permanently set the currently running (good) generation as the default, simply rebuild the system from it:

```sh
just switch
```

*(Assuming you have reverted the breaking changes in your local Git repository).*

## ⚠️ What Rollbacks Do Not Cover

NixOS generations only snapshot the **system configuration** (`/nix/store` and `/etc`). They **do not** roll back:
- **User Data:** Your documents and files in `/home` are untouched.
- **Disk Layouts:** Destructive changes like formatting a partition or resizing LUKS cannot be rolled back.

## 🆘 System Recovery from Live ISO

If no installed generation is usable (e.g., severe bootloader corruption or disk replacement), boot the official NixOS ISO in UEFI mode.

Review the disk state before mounting:

```sh
lsblk -f
```

Any command that repartitions, formats, or encrypts a real disk is destructive. After mounting or recreating the system according to the storage model, provide the local overlay and hardware configuration paths when reinstalling:

```sh
NIX_CONFIG_LOCAL_USER="$HOME/.cache/nixos-config-installer/state/pc/user.nix" \
NIX_CONFIG_LOCAL_HARDWARE="/mnt/etc/nixos/hardware-configuration.nix" \
nixos-install --impure --flake "path:/absolute/path/to/nixos-config#"
```

The recovered target root must also contain the password hash file referenced by
the local overlay:

```txt
/mnt/root/.nix-config-local/user.passwd
```

## 🔐 Restoring a LUKS2 Header

If your LUKS header becomes corrupted and the password no longer works, you can restore it from a backup (see [Backups](backups)).

Boot from a Live ISO, transfer your backup header file (`luks-header-backup.img`) to the live environment, and run:

```sh
cryptsetup luksHeaderRestore /dev/<partition> --header-backup-file /path/to/luks-header-backup.img
```

**WARNING:** This command replaces the current header. Ensure you are restoring the correct file to the correct partition, otherwise all data will be permanently lost.
