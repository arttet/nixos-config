# NixOS Platform

[![CI](https://github.com/arttet/nixos-config/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/arttet/nixos-config/actions/workflows/ci.yml)

Personal reproducible NixOS infrastructure for machines that can be destroyed and rebuilt at any time.

## 📚 Documentation

Read the documentation here:

| Site | URL |
| --- | --- |
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

    [Guest User]
    guest:
        build  # Build the guest VM
        run    # Run the guest VM
        daemon # Start the guest VM in the background
        status # Show guest VM status
        ssh    # Open an SSH session into the guest VM
        stop   # Stop the background guest VM
        test   # Validate daemon startup, SSH reachability, and guest network
        clean  # Remove guest VM state

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
