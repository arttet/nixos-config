# Workstation Installation

The workstation install path targets real hardware. It is not required for local
VM validation.

The workstation does not require a custom ISO right now. Use the official NixOS
ISO as the bootstrap environment.

This V0 install is console-only and unencrypted. It uses UEFI GRUB2 with systemd
initrd, which keeps the boot path compatible with future LUKS root encryption
and later GRUB customization.

## Flow

1. Boot the official NixOS ISO in UEFI mode.
2. Connect the network.
3. Clone or otherwise provide this repository flake.
4. Create a local user overlay outside git.
5. Validate the overlay.
6. Choose and review the target disk device.
7. Review the install plan.
8. Run disko manually.
9. Generate hardware configuration.
10. Run `nixos-install`.
11. Reboot.
12. Log in as the local user.
13. Validate network and rebuild.

## Local Overlay

Create a local overlay before installation:

```sh
mkdir -p ~/.nix-config-local
cp examples/local/user.nix ~/.nix-config-local/user.nix
```

Edit the copied file with real local identity. Do not commit it.

Validate that the overlay exists:

```sh
just overlay check
```

## Disk Device Review

Disk layout application is destructive. Before any future install command is
run, inspect disks from the ISO environment:

```sh
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL
```

Use stable device paths such as `/dev/disk/by-id/...` when possible. Do not copy
an example disk path without checking that it points to the intended device.

Example configuration shape:

```nix
{
  platform.storage = {
    enable = true;
    diskDevice = "/dev/disk/by-id/nvme-example";
  };
}
```

The example path is not a real committed workstation device.

## Plan

Print a safe plan before running destructive commands:

```sh
just workstation plan-install /dev/disk/by-id/<reviewed-disk>
```

Expected result:

- The selected disk is printed.
- The local overlay path is printed.
- A destructive warning is printed.
- Exact manual commands are printed.
- No disk is partitioned or formatted by the plan command.

## Hardware Configuration

After disko creates and mounts the target filesystem under `/mnt`, generate
hardware configuration:

```sh
sudo nixos-generate-config --root /mnt
```

The generated install-time path is:

```txt
/mnt/etc/nixos/hardware-configuration.nix
```

The runtime path after reboot is:

```txt
/etc/nixos/hardware-configuration.nix
```

The public repository must not contain this file.

## Encryption

The current workstation install is unencrypted. The next storage stage will add
LUKS root encryption. The current layout and systemd initrd are intentionally
compatible with a future encrypted boot flow.

Secure Boot is not supported yet.
