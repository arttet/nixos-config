# Storage & Data

The workstation storage foundation is production-grade and encrypted, but it is not applied to real hardware by default.

The intended workstation install model is:

- UEFI-only boot.
- GRUB2.
- systemd initrd.
- Plymouth graphical LUKS prompt.
- GPT partitioning.
- 512 MiB EFI System Partition mounted at `/boot/efi`.
- 512 MiB unencrypted ext4 `/boot` partition.
- Remaining disk as a LUKS2 encrypted root container.
- Btrfs inside LUKS.
- Btrfs subvolumes for `/`, `/nix`, `/home`, `/var/log`, and `/swap`.
- Swapfile-based swap at `/swap/swapfile`.
- Default swapfile size of 8192 MiB.

The disk device is always a parameter. The repository must not hardcode a real device such as `/dev/sda` for workstation installs.

## Repository Options

Storage options live under `platform.storage`:

| Option | Purpose | Default |
| --- | --- | --- |
| `platform.storage.enable` | Enables the workstation storage layout for an install path. | `false` |
| `platform.storage.diskDevice` | Disk device to partition. Required when storage is enabled. | `null` |
| `platform.storage.swapFilePath` | Swapfile path. | `/swap/swapfile` |
| `platform.storage.swapSizeMiB` | Swapfile size in MiB. | `8192` |

The generated layout is exposed as `platform.storage.diskoLayout` and wired into `disko.devices` when `platform.storage.enable = true`. The repository uses the locked `nix-community/disko` flake input as the install implementation.

## Btrfs

All Btrfs mountpoints use:

```txt
compress=zstd
noatime
discard=async
```

The subvolume model is:

| Subvolume | Mountpoint |
| --- | --- |
| `@root` | `/` |
| `@nix` | `/nix` |
| `@home` | `/home` |
| `@log` | `/var/log` |
| `@swap` | `/swap` |

The `@swap` subvolume hosts `/swap/swapfile`. The NixOS swap module owns the Btrfs NOCOW preparation through the `prepare-btrfs-swap` systemd service before the swap unit starts. The install plan does not ask the user to run `chattr` manually.

Periodic trim is enabled by the workstation tuning layer. The storage layout also uses `discard=async` for Btrfs mountpoints. This keeps SSD/NVMe behavior safe without adding synchronous discard overhead.

## Encryption

The root container uses LUKS2 with manual passphrase unlock. Plymouth provides
the graphical prompt, but the unlock method remains passphrase-based. TPM and
YubiKey unlock integration are explicitly deferred. Secure Boot protects the EFI
boot path through the security layer; it does not change how the LUKS container
is unlocked.

During the clean-hardware installer apply flow, the installer asks for the LUKS
passphrase, writes it to a root-only file under
`/run/nixos-config-installer/<session>/secrets/`, generates a `disko`
configuration with `passwordFile`, and removes the secrets directory after it is
no longer needed. The generated user password hash is also staged under
`/run/nixos-config-installer/<session>/secrets/` before it is copied into the
installed target root. The LUKS passphrase is not the local user login password
and is not persisted by the installer.

### Install Boundary

Encryption setup is a destructive storage operation. A real install must happen only after reviewing the target disk device and confirming that all data on that device can be erased.

The current repository does not require TPM or YubiKey unlock to build, run, or install `workstation`.

## Partition Size Rationale

The 512 MiB ESP is reserved for UEFI boot files, GRUB assets, kernels, future bootloader growth, and recovery scenarios.

The 512 MiB `/boot` partition is reserved for workstation generation management, multiple kernels and initrds during rebuild transitions, and the encrypted root boot flow.

## Explicitly Deferred

The layout does not implement automatic snapshots, Timeshift integration, GRUB snapshot boot entries, impermanence, hibernation, TPM unlock, or YubiKey unlock.

## VM Boundary

The `vm` target remains a disposable QEMU mirror of `workstation`. Normal VM commands do not apply the workstation disk layout and do not partition disks.

VM validation keeps the normal small runtime disk. Storage layout checks use evaluation-only examples instead of increasing normal VM runtime cost.

## Destructive Operations

Any command that applies the disk layout to a real device is destructive. It must require an explicit disk device review and must not become part of default CI or VM runtime workflows.

## Backup Policy

The backup policy is:

```txt
System is reproducible.
Data is valuable.
Back up data, not the full OS image.
```

Operational backup details live in the User Guide.
