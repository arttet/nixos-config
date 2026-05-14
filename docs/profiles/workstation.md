# Workstation Profile

The `workstation` profile is the reusable personal development environment for
future real hardware targets: laptop, mini-PC, or desktop.

It is console-only for now. It enables NetworkManager and OpenSSH, and includes
base development and diagnostics tools such as `git`, `curl`, `wget`, `jq`,
`just`, `nushell`, `iproute2`, `iputils`, `tcpdump`, `lsof`, and hardware
inspection utilities.

The profile does not include a GUI, Hyprland, desktop managers, Home Manager,
VPN targets, disk encryption, or machine-specific hardware state.

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

## Validation

Build the profile without real hardware:

```sh
just workstation build
```

Run the CI-safe profile validation:

```sh
just workstation test
```
