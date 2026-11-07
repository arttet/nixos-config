# NixOS Configuration

[![CI](https://github.com/arttet/nixos-config/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/arttet/nixos-config/actions/workflows/ci.yml)

Personal declarative NixOS configuration, paired with a separate
[dotfiles repository](https://github.com/arttet/dotfiles) for application settings.
System policy lives here; personal configuration is linked through the existing
Home Manager integration. Real machine identity and secrets stay outside Git.

| Target         | Purpose                                            |
| -------------- | -------------------------------------------------- |
| `desktop`      | Default workstation with Hyprland on real hardware |
| `workstation`  | Headless workstation foundation                    |
| `vm`           | Disposable QEMU system for local validation        |
| `homelab-rpi5` | Independent headless Raspberry Pi 5 system         |

## Getting Started

- [User guide](docs/src/user/index.md)
- [Hardware installation](docs/src/user/installation/workstation.md)
- [Rebuilds and updates](docs/src/user/operations/rebuild.md)
- [Development setup](docs/src/dev/setup/index.md)
- [Repository layout](docs/src/dev/reference/layouts.md)

Install [mise](https://mise.jdx.dev/getting-started.html), review `mise.toml`, then:

```sh
mise trust
mise install aube uv node python
mise install
just docs install
just docs build
```

Documentation uses aube with a frozen lockfile. NixOS builds require Linux with
Nix; VM runtime checks also require QEMU. See the setup guide for WSL2.

Use `just upgrade` to update project tools in dependency order. It installs the
configured package managers first, updates their pins, then upgrades dependent
tools. Review the configuration diff after updating.

## 📚 Project Resources

Useful project resources:

| Resource      | URL                      |
| ------------- | ------------------------ |
| Documentation | <https://nix.arttet.dev> |

## 🛠 Management & Development

This project uses `just` as the primary task runner for development, validation, documentation, and deployment workflows.

### ⚡ Justfile Commands

The justfile provides a single command surface for common project workflows.

```sh
$ just help
Available recipes:
    default # Show help
    help    # List all commands

    [Development]
    fmt     # Format code
    check   # Run repository checks

    [VM Runtime]
    vm:
        build    # Build the VM
        run      # Run the VM
        daemon   # Start the VM in the background
        status   # Show VM status
        ssh      # Open an SSH session into the VM
        stop     # Stop the background VM
        test     # Validate daemon startup, SSH reachability, and VM network
        validate # Validate the VM profile without starting QEMU
        clean    # Remove VM state

    [Workstation]
    workstation:
        build          # Build the workstation system closure
        test           # Validate the workstation profile
        runtime-checks # Print real-hardware workstation tuning validation commands
        dns-report     # Print real-hardware workstation DNS validation commands
        network-report # Print real-hardware workstation network validation commands
        logs-report    # Print real-hardware workstation log validation commands

    [Desktop]
    desktop:
        build        # Build the desktop system closure
        test         # Validate the desktop profile
        power-checks # Print real-hardware desktop power validation commands

    [Local Overlay]
    overlay:
        path  # Print the local user overlay path
        check # Check that the local user overlay exists

    [Documentation]
    docs:
        dev     # Serve docs
        build   # Build docs
        preview # Preview docs
```
