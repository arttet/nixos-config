# NixOS Configuration

[![CI](https://github.com/arttet/nixos-config/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/arttet/nixos-config/actions/workflows/ci.yml)

Personal reproducible NixOS infrastructure for machines that can be destroyed and rebuilt at any time.

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

    [Pull Requests]
    pr:
        create      # Create a new Pull Request
        review n="" # Ask Gemini to review the Pull Request
        view n=""   # View comments for the Pull Request

    [Deployment]
    deploy:
        list        # List Cloudflare Pages projects
        create name # Create a Cloudflare Pages project
        delete name # Delete a Cloudflare Pages project
```
