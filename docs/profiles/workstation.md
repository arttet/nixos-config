# Workstation Profile

The `workstation` profile is the reusable personal development environment for
future real hardware targets: laptop, mini-PC, or desktop.

It is console-only for now. It enables NetworkManager and keeps OpenSSH disabled
by default. The package set is intentionally small: `git`, `curl`, `wget`, `jq`,
`just`, `nushell`, `vim`, `htop`, `pciutils`, `usbutils`, and basic archive
tools.

The profile uses a UEFI/GRUB2 boot model with systemd initrd. Its storage layout
is prepared as an opt-in installation path with a parameterized disk device,
GPT, a 512 MiB ESP mounted at `/boot/efi`, a 512 MiB unencrypted ext4 `/boot`,
LUKS2 encrypted root, Btrfs subvolumes, and swapfile support.

The profile does not include a GUI, Hyprland, desktop managers, Home Manager,
VPN targets, TPM unlock, YubiKey unlock, Secure Boot, enabled SSH by default, or
machine-specific hardware state.

The workstation uses `pkgs.linuxPackages_latest`. The actual kernel version is
controlled by `flake.lock`, and rollback uses NixOS generations from GRUB.

Project status is V0/development. `system.stateVersion` is pinned to `25.11` as
a NixOS compatibility marker. It must change only through a deliberate migration,
not as part of routine package upgrades.

## Install Model

The workstation target does not require a custom ISO right now.

The future install flow is:

1. Boot the official NixOS ISO.
2. Connect the network.
3. Clone or otherwise provide this repository flake.
4. Create a local user overlay outside git.
5. Review the disk device and install plan.
6. Generate local hardware configuration.
7. Install the `workstation` target.

Real users, hostnames, SSH keys, hardware configuration, and secrets must remain
local and uncommitted.

Storage application is destructive and must only happen after reviewing the disk
device from the official NixOS ISO environment. See
[Workstation Installation](../installation/workstation.md) and
[Storage Model](../architecture/storage-model.md).

## Validation

Build the profile without real hardware:

```sh
just workstation build
```

Run the CI-safe profile validation:

```sh
just workstation test
```
