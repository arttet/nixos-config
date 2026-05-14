# Workstation Profile

The `workstation` profile is the reusable personal development environment for
future real hardware targets: laptop, mini-PC, or desktop.

It is console-only for now. It enables NetworkManager and OpenSSH, and includes
base development and diagnostics tools such as `git`, `curl`, `wget`, `jq`,
`just`, `nushell`, `iproute2`, `iputils`, `tcpdump`, `lsof`, and hardware
inspection utilities.

The profile uses a UEFI/systemd-boot boot model. Its storage layout is prepared
as an opt-in installation path with a parameterized disk device, GPT, a 1 GiB
ESP mounted at `/boot`, ext4 root, and swapfile support.

The profile does not include a GUI, Hyprland, desktop managers, Home Manager,
VPN targets, enabled disk encryption, or machine-specific hardware state.

## Install Model

The workstation target does not require a custom ISO right now.

The future install flow is:

1. Boot the official NixOS ISO.
2. Connect the network.
3. Clone or otherwise provide this repository flake.
4. Create a local user overlay outside git.
5. Install the `workstation` target.

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
