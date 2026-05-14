# Workstation Installation

The workstation install path targets future real hardware. It is not required
for local VM validation.

The workstation does not require a custom ISO right now. Use the official NixOS
ISO as the bootstrap environment.

## Future Flow

1. Boot the official NixOS ISO in UEFI mode.
2. Connect the network.
3. Clone or otherwise provide this repository flake.
4. Create a local user overlay outside git.
5. Review the target disk device.
6. Enable the workstation storage layout with that disk device.
7. Install the `workstation` target.

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

## Encryption

Encrypted root is planned but not forced by the current install path. The first
supported encrypted model will be passphrase-based unlock. YubiKey and TPM
unlock can be added later.

Secure Boot is not supported yet.
