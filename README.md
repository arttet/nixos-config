# NixOS Platform

Personal NixOS infrastructure for machines that can be destroyed and rebuilt at
any time.

The repository is docs-first and keeps public infrastructure separate from local
identity. The active runtime target is a disposable headless NixOS guest VM for
local development and validation.

## Status

Current stage: `002`

Stage 001 runtime acceptance is complete:

- `just check` passes.
- `just guest build` builds the VM.
- `just guest run` starts the VM.
- Console login works with `user` / `user`.
- Network works from inside the VM.
- No GUI and no Home Manager are used.

Stage 002 adds CI/CD, Cloudflare Pages docs deployment, daemonized guest
lifecycle commands, and cleaned documentation structure.

## Quick Start

From a Linux environment with Nix flakes, QEMU, OpenSSH, `sshpass`, and `just`:

```sh
just check
just guest build
just guest run
```

On Windows, run the workflow inside WSL2.

## Guest VM Commands

```sh
just guest build
just guest run
just guest daemon
just guest status
just guest ssh
just guest stop
just guest test
just guest clean
```

Build and runtime artifacts live under `target/` by default. Override the build
directory when needed:

```sh
BUILD_DIR=/tmp/nixos-platform just guest build
```

## Documentation

Published docs:

- https://nix.arttet.dev
- https://nixos-config-docs.pages.dev

Local docs:

```sh
just docs build
```

## Security Baseline

The repository must not contain real usernames, hostnames, SSH keys, API tokens,
VPN tokens, hardware configuration, encrypted secrets, or secrets of any kind.

Local identity belongs in local overlays only. Build outputs and runtime state
belong under ignored directories such as `target/`.

## Out Of Scope

The current stage does not include laptop installation, VPN, Hyprland, Home
Manager, disk encryption, YubiKey, Secure Boot, ISO/OVA artifacts, or a binary
cache.
