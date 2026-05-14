# Recovery

The recovery model is rebuild-first.

If a VM is broken, delete its state and rebuild it. If a real machine is
broken in a future milestone, the platform should provide enough documented
state to recreate it rather than preserve unknown drift.

For workstation installs, recovery starts from the official NixOS ISO: boot the
ISO in UEFI mode, review the disk state, mount or recreate the system according
to the documented storage model, and rebuild from the repository flake.

Any command that repartitions, formats, or encrypts a real disk is destructive.
Review the disk device with `lsblk` before running such commands.

The operating system is intended to be rebuilt rather than imaged. User data,
local overlays, and secrets require backups; `/nix/store`, VM runtime state, and
build artifacts do not. See [Backups](backups.md).

Useful boot and log diagnostics after a recovery boot:

```sh
systemd-analyze
systemd-analyze critical-chain
journalctl -b -p warning
journalctl --disk-usage
```
