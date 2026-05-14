# Pre-GUI Freeze

The headless workstation foundation is frozen before GUI work begins.

This freeze means the operating system foundation is treated as a platform
contract. GUI work must be layered on top of it rather than changing the core
storage, boot, security, network, recovery, or upgrade model.

## Frozen

The following architecture is frozen for the pre-GUI baseline:

- UEFI-only boot.
- GRUB2.
- systemd initrd.
- `pkgs.linuxPackages_latest`.
- LUKS2 and Btrfs storage architecture.
- Local overlay and hardware layer separation.
- `system.stateVersion = "25.11"`.
- Root login disabled by default.
- SSH disabled by default.
- `doas` privilege escalation for workstation.
- Firewall enabled with no inbound ports open by default.
- Thunderbolt disabled by default.
- NetworkManager for workstation networking.
- `systemd-resolved` with explicit DNS policy.
- Conservative runtime tuning.
- Persistent and bounded journald.
- Volatile `/tmp`.
- Conservative automatic Nix garbage collection.
- Manual upgrade model.
- Rebuild, rollback, and recovery documentation.
- VM as disposable validation target.

## Deferred

The following remain out of scope:

- GUI.
- Wayland.
- Hyprland.
- Audio stack.
- Desktop portals.
- Fonts.
- Browser.
- Display or login manager.
- Home Manager.
- TPM unlock.
- YubiKey unlock.
- Secure Boot.
- USBGuard.
- Vendor-specific IOMMU parameters.
- Entropy daemons without measured entropy pressure.
- Automatic snapshots.
- Impermanence.
- Full developer environments.

## Rationale

The foundation must remain isolated from the desktop layer. Desktop work should
not rewrite the boot chain, disk layout, recovery model, DNS policy, privilege
escalation model, or upgrade process.

## Readiness Decision

The headless foundation is considered ready for GUI only when:

- `just check` passes.
- `just docs build` passes.
- `just vm build` passes.
- `just workstation build` passes.
- `just workstation test` passes.
- Documentation describes install, rollback, recovery, overlays, hardware, DNS,
  security, tuning, and backup policy.
- VM remains disposable and simple.
- Workstation remains console-only.

When those conditions hold, the decision is:

```txt
READY FOR GUI
```

If any condition fails, the decision is:

```txt
NOT READY FOR GUI
```
