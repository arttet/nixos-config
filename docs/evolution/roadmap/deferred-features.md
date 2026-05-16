# Deferred Features

This registry tracks features that are intentionally outside the V1 workstation
freeze. Deferred does not mean rejected. It means the feature needs its own
design, validation, and rollback story before entering the platform baseline.

## Security And Boot

| Feature | Status | Why deferred |
| --- | --- | --- |
| Secure Boot | Deferred | Requires key management, signing workflow, recovery plan, and lockdown policy. |
| TPM unlock | Deferred | Needs threat model, recovery flow, and clear fallback from failed unlock. |
| YubiKey unlock | Deferred | Needs enrollment, backup key strategy, and install/recovery documentation. |
| Kernel lockdown | Deferred | Should be tied to Secure Boot and real hardware validation. |
| USBGuard | Deferred | Needs hardware whitelist planning to avoid locking out input devices or recovery tools. |
| Thunderbolt policy | Deferred | Hardware-specific and must not break docks or USB-C workflows without review. |

## Storage And Data

| Feature | Status | Why deferred |
| --- | --- | --- |
| Automatic snapshots | Deferred | Needs retention, rollback UX, disk usage policy, and bootloader integration. |
| Impermanence | Deferred | Requires a separate state model and data ownership audit. |
| Hibernation | Deferred | Complicates encrypted swap, resume reliability, and power policy. |
| Backup automation | Deferred | Needs encryption, retention, remote target, restore testing, and secret handling. |

## Desktop And UX

| Feature | Status | Why deferred |
| --- | --- | --- |
| Advanced AGS/Astal shell | Deferred | Belongs in dotfiles or a dedicated desktop-shell repository. |
| Theming and wallpapers | Deferred | Personal UX, not platform runtime. |
| Full desktop app expansion | Deferred | Must be added by category, not as a package dump. |
| Home Manager evaluation | Deferred | Current architecture intentionally avoids Home Manager. |

## Applications And Cloud

| Feature | Status | Why deferred |
| --- | --- | --- |
| Proton Drive sync client | Deferred | Linux/Nix drive-sync integration is not a clean baseline dependency yet. |
| Yandex Browser | Optional/deferred | Only acceptable if cleanly packaged and documented. |
| rclone backup/sync automation | Deferred | Needs backup policy, remote target, encryption, retention, and restore testing. |
| Advanced media stack | Deferred | V1 includes only minimal media workflow. |
| Podman migration | Deferred | Docker is selected first for compatibility and workflow predictability. |

## Hardware Operations

| Feature | Status | Why deferred |
| --- | --- | --- |
| Real hardware install certification | Deferred until performed by the user | Agents cannot validate bare-metal installation directly. |
| Suspend/resume tuning | Deferred | Requires target hardware measurements. |
| Battery tuning expansion | Deferred | Requires laptop-specific validation and regression testing. |
| GPU-specific tuning | Deferred | Requires exact hardware data and runtime measurements. |

## Rule For Promotion

A deferred feature can move into the baseline only when it has:

- a clear architecture owner
- implementation scoped to the correct layer
- documentation
- validation commands
- rollback or recovery guidance
- CI coverage where possible
