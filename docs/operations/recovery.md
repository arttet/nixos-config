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

## Security Policy Recovery

Security changes are part of the runtime contract. If firewall, login, doas, or
kernel hardening policy prevents normal access, recover from a known-good NixOS
generation first.

Recommended order:

1. Select an older generation from GRUB.
2. Log in as the local overlay user.
3. Inspect the failed generation and logs.
4. Rebuild from the repository after reverting or overriding the broken policy.

If no installed generation is usable, boot the official NixOS ISO in UEFI mode,
unlock the root filesystem, mount the system, provide the local overlay and
hardware configuration, then rebuild or reinstall from the repository flake.

Do not disable security mitigations globally as a recovery shortcut. Use a local
override only for the specific policy that caused the failure, and document it.

If `doas` policy itself breaks, recover through GRUB first. If no generation is
usable, use the official NixOS ISO, mount the system, fix the local overlay or
security module, and rebuild from the repository flake.
