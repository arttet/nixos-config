# Workstation Installation

The workstation install path targets real hardware. It is not required for local
VM validation.

The workstation does not require a custom ISO right now. Use the official NixOS
ISO as the bootstrap environment.

This install is console-only and encrypted. It uses UEFI GRUB2 with systemd
initrd, an unencrypted `/boot`, and LUKS2 manual passphrase unlock for the root
container.

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

Print a safe plan before running destructive commands. This is intentionally not
exposed as a default `just` command; run the Nushell script explicitly after
reviewing the disk device:

```sh
nu scripts/install/workstation.nu /dev/disk/by-id/<reviewed-disk>
```

Expected result:

- The selected disk is printed.
- The local overlay path is printed.
- A destructive warning is printed.
- Exact manual commands are printed.
- No disk is partitioned or formatted by the plan command.

The plan uses the repository's locked `nix-community/disko` flake input through
`nix run .#disko`. The storage layout source of truth remains
`nixos/modules/storage/disko.nix`.

The final `nixos-install` command uses `--impure` intentionally. That is the
local install boundary that lets the flake read `NIX_CONFIG_LOCAL_USER` and
`NIX_CONFIG_LOCAL_HARDWARE`, then pass those paths into the NixOS configuration
through `specialArgs`.

If the local overlay is not at the default path, pass it explicitly:

```sh
nu scripts/install/workstation.nu /dev/disk/by-id/<reviewed-disk> --overlay /path/to/user.nix
```

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

The root filesystem is encrypted with LUKS2. The first supported unlock model is
manual passphrase entry at boot.

TPM unlock, YubiKey unlock, Secure Boot, automatic snapshots, GRUB snapshot boot
entries, impermanence, and hibernation are deferred.

Secure Boot is not supported yet.
