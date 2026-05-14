# Storage Model

The workstation storage foundation is prepared but not applied to real hardware
by default.

The intended workstation install model is:

- UEFI-only boot.
- `systemd-boot`.
- GPT partitioning.
- 1 GiB EFI System Partition mounted at `/boot`.
- Root partition using the remaining disk.
- ext4 root filesystem for now.
- Swapfile-based swap at `/var/lib/swapfile`.
- Default swapfile size of 8192 MiB.

The disk device is always a parameter. The repository must not hardcode a real
device such as `/dev/sda` for workstation installs.

## Repository Options

Storage options live under `platform.storage`:

| Option | Purpose | Default |
| --- | --- | --- |
| `platform.storage.enable` | Enables the workstation storage layout for an install path. | `false` |
| `platform.storage.diskDevice` | Disk device to partition. Required when storage is enabled. | `null` |
| `platform.storage.swapFilePath` | Swapfile path. | `/var/lib/swapfile` |
| `platform.storage.swapSizeMiB` | Swapfile size in MiB. | `8192` |

The generated layout is exposed as `platform.storage.diskoLayout`. It is
disko-compatible data for the future destructive install path, not a default CI
or local runtime command.

## VM Boundary

The `vm` target remains a disposable QEMU mirror of `workstation`. Normal VM
commands do not apply the workstation disk layout and do not partition disks.

VM validation keeps the normal small runtime disk. Storage layout checks use
evaluation-only examples instead of increasing normal VM runtime cost.

## Destructive Operations

Any future command that applies the disk layout to a real device is destructive.
It must require an explicit disk device review and must not become part of
default `just`, CI, or VM runtime workflows.
