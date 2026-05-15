# Workstation Installation

This is the frozen first-install flow for real hardware.

The default install target is `workstation-gui`. The `workstation` target remains
available as a headless fallback.

The install is destructive once the disk layout is applied. Review the selected
disk before running apply mode.

## Prepare Boot Media

Download the latest official NixOS ISO from the NixOS website.

Ventoy may be used as a convenient USB boot manager:

```txt
https://github.com/ventoy/Ventoy
```

Ventoy is optional. It is not part of this repository and is not required by the
configuration.

## Boot The ISO

Boot the official ISO in UEFI mode.

Confirm UEFI:

```sh
test -d /sys/firmware/efi
```

## Connect Network

Wired networking usually works automatically.

For Wi-Fi, use `iwctl`:

```sh
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect <SSID>
exit
ping -c 3 nixos.org
```

Replace `wlan0` with the device shown by `device list`.

## Enter Nushell

Run the install from a root shell on the ISO. The official NixOS ISO usually
starts in a root-capable environment; if not, switch to root before continuing.

The ISO does not need to include Nushell. Enter a temporary root shell with
Nushell and Git:

```sh
nix shell nixpkgs#nushell nixpkgs#git
```

If you started from a non-root shell, prefer becoming root before entering the
Nix shell. If you must use `sudo`, preserve the environment explicitly:

```sh
sudo -E nu scripts/install/bootstrap.nu
```

Clone the repository:

```sh
git clone https://github.com/arttet/nixos-config.git
cd nixos-config
```

## Run The Installer Wizard

Start the guided installer:

```sh
nu scripts/install/bootstrap.nu
```

The wizard asks for:

- install id, default `pc`;
- target, default `workstation-gui`;
- username, default `user`;
- hostname, default `pc`;
- timezone, default `UTC`;
- disk device.

The username must start with a lowercase letter or underscore and then use only
lowercase letters, numbers, underscores, or dashes. It cannot be `root`.
Administrative access is granted through the generated local user and `wheel`
membership.

The hostname must use letters, digits, and hyphens only. The timezone is
validated against `/usr/share/zoneinfo` when that database is available in the
ISO environment.

Prompt controls:

- Enter accepts the shown default.
- A typed value overrides the default.
- Invalid values are rejected at the current step without restarting the
  wizard.
- `r` goes back one step.
- `q` exits.

The wizard reads disk candidates from:

```sh
lsblk -J -o NAME,SIZE,TYPE,MODEL,SERIAL,MOUNTPOINTS,PATH
```

It shows a numbered disk list and also allows manual override. Prefer a stable
`/dev/disk/by-id/...` path when choosing manually.

## Dry Run

Dry-run is the default. It generates local install files and prints commands,
but does not partition or format disks:

```sh
nu scripts/install/bootstrap.nu --dry-run
```

Generated files use abstract local install state:

```txt
/tmp/nix-config-install/pc/user.nix
/tmp/nix-config-install/pc/install.env
/tmp/workstation-disko.nix
```

The generated `install.env` contains:

```sh
export NIX_CONFIG_LOCAL_USER="/tmp/nix-config-install/pc/user.nix"
export NIX_CONFIG_LOCAL_HARDWARE="/mnt/etc/nixos/hardware-configuration.nix"
```

No `.envrc` or `direnv` is required.

## Apply Install

Run apply mode only after reviewing the selected disk:

```sh
nu scripts/install/bootstrap.nu --apply
```

Before destructive disk operations, the script requires typing the exact disk
path. Pressing Enter is not enough.

Apply mode runs:

```sh
nu "/absolute/path/to/nixos-config/scripts/install/disko.nu" "<selected-disk>"
nixos-generate-config --root /mnt
test -f /mnt/etc/nixos/hardware-configuration.nix
NIX_CONFIG_LOCAL_USER="/tmp/nix-config-install/pc/user.nix" \
NIX_CONFIG_LOCAL_HARDWARE="/mnt/etc/nixos/hardware-configuration.nix" \
nixos-install --impure --flake "path:/absolute/path/to/nixos-config#workstation-gui"
```

The installer prints the exact absolute paths for the current checkout.

## Disk-Only Helper

To apply only the disk layout manually:

```sh
nu scripts/install/disko.nu /dev/disk/by-id/<reviewed-disk>
```

This runs disko only. It does not generate hardware configuration and does not
run `nixos-install`.

## First Boot

After install:

```sh
reboot
```

Expected result:

- GRUB shows NixOS generations.
- Plymouth shows the LUKS passphrase prompt.
- The local user can log in.
- SSH is disabled by default.
- Root password login is disabled.

Basic validation:

```sh
test -d /sys/firmware/efi
findmnt
swapon --show
systemctl status NetworkManager
doas true
doas nixos-rebuild switch --impure --flake "path:/absolute/path/to/nixos-config#workstation-gui"
```

## Deferred

TPM unlock, YubiKey unlock, Secure Boot, automatic snapshots, impermanence, and
hibernation are deferred.
