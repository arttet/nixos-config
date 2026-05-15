# Workstation Install Rehearsal

This rehearsal validates the workstation installation flow before the first
real hardware install.

The rehearsal uses the official NixOS ISO and the repository flake. It is a real
bare-metal installation exercise, not a VM test.

## Scope

Validate:

- bare-metal installation flow
- LUKS2 and Btrfs layout
- Plymouth graphical LUKS prompt
- GRUB2 and UEFI boot
- rollback and rebuild
- local overlay architecture
- recovery from the official ISO
- documentation quality

Keep out of scope:

- Home Manager
- SSH enabled by default
- root login
- Secure Boot
- TPM or YubiKey unlock
- VM runtime changes

## Preflight

Run the non-destructive repository checks first:

```sh
just check
just docs build
just vm build
just workstation build
just workstation test
just workstation-gui test
```

Expected result:

- flake checks pass
- documentation builds
- VM build succeeds
- workstation closure builds
- workstation evaluation checks pass
- graphical workstation evaluation checks pass

The VM remains disposable and is not the install target.

## Local Overlay

The installer wizard creates a temporary local overlay under `/tmp`.
For normal repository checks before ISO boot, the local overlay can still be
validated with:

```sh
mkdir -p ~/.nix-config-local
just overlay check
```

Do not commit real local overlays.

## ISO Boot

Boot the official NixOS ISO in UEFI mode.

Confirm that the machine was booted through UEFI:

```sh
test -d /sys/firmware/efi
```

Connect the network from the ISO environment. For Wi-Fi, use `iwctl`.

Then enter a temporary Nushell/Git environment:

```sh
nix shell nixpkgs#nushell nixpkgs#git
```

Run the install from a root shell. If the ISO session is not root, become root
before entering the Nix shell, or use `sudo -E` when invoking the Nushell
installer so the temporary `nu` binary remains available.

Clone this repository and enter it.

## Disk Review

Disk layout application is destructive. Review the target disk before running
any disko command:

```sh
lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL
ls -l /dev/disk/by-id/
```

Use a stable `/dev/disk/by-id/...` path where possible.

## Installer Wizard

Run dry-run first:

```sh
nu scripts/install/bootstrap.nu --dry-run
```

Expected result:

- selected disk is printed
- local overlay path is printed
- destructive warning is printed
- exact manual install commands are printed
- no disk is partitioned or formatted by the plan command

Review the selected disk before running apply mode.

## Install Execution

Run apply mode:

```sh
nu scripts/install/bootstrap.nu --apply
```

The flow is:

1. Generate `/tmp/nix-config-install/pc/user.nix`.
2. Generate `/tmp/nix-config-install/pc/install.env`.
3. Generate `/tmp/workstation-disko.nix`.
4. Confirm the exact disk path.
5. Run disko.
6. Enter the LUKS2 passphrase when prompted.
7. Generate hardware configuration under `/mnt`.
8. Verify `/mnt/etc/nixos/hardware-configuration.nix` exists.
9. Run `nixos-install --impure --flake "path:/absolute/path/to/nixos-config#workstation-gui"`.

Do not commit the generated hardware configuration.

## First Boot

After reboot:

1. Unlock LUKS2 with the manual passphrase through the Plymouth prompt.
2. Confirm GRUB shows NixOS generations.
3. Log in as the local overlay user.
4. Confirm SSH is not enabled by default.
5. Confirm root password login is not available.

Basic checks:

```sh
test -d /sys/firmware/efi
findmnt
swapon --show
systemctl status NetworkManager
systemctl status sshd || true
```

## Rebuild

From the installed workstation, rebuild from the repository:

```sh
doas nixos-rebuild switch --impure --flake "path:/absolute/path/to/nixos-config#workstation-gui"
```

Expected result:

- rebuild completes
- a new NixOS generation appears
- system remains on the selected workstation target
- SSH remains disabled unless explicitly enabled by local override

## Rollback

Validate rollback visibility without forcing a failure:

```sh
doas nixos-rebuild boot --impure --flake "path:/absolute/path/to/nixos-config#workstation-gui"
```

Reboot and confirm GRUB allows selecting older generations.

If a generation fails later, select a known-good generation in GRUB, then inspect
and rebuild from the repository. If the graphical boot prompt fails, edit the
GRUB entry once and remove `splash` from the kernel command line. Do not rerun
destructive disk commands during a normal rollback.

## Recovery

Recovery starts from the official NixOS ISO:

1. Boot the ISO in UEFI mode.
2. Review disks with `lsblk`.
3. Unlock the LUKS2 container.
4. Mount the Btrfs subvolumes.
5. Provide the local overlay and generated hardware configuration.
6. Rebuild or reinstall from the repository flake.

See [Recovery](ops-recovery) for the recovery policy.

## Runtime Diagnostics

After installation, collect early boot and runtime diagnostics:

```sh
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
systemd-analyze plot > boot.svg
dmesg --human --level=err,warn
journalctl -b -p warning
lspci -k
lsusb
findmnt
cat /proc/cmdline
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
cat /sys/power/mem_sleep
cat /sys/block/*/queue/scheduler
```

Keep diagnostic bundles local unless sensitive data has been reviewed.

## Acceptance

The rehearsal is successful when:

- preflight checks pass
- official NixOS ISO boots in UEFI mode
- local overlay is used and remains uncommitted
- disko applies the LUKS2 and Btrfs layout to the reviewed disk
- GRUB2 boots the installed system through UEFI
- manual LUKS unlock works
- local user can log in
- SSH is disabled by default
- root login is disabled by default
- `doas nixos-rebuild switch --impure --flake "path:/absolute/path/to/nixos-config#workstation-gui"` works
- GRUB rollback generations are visible
- recovery path is documented and understood
- VM workflow remains disposable and unchanged
