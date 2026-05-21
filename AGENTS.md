# AGENTS.md

Repository instructions for `nix-config`.

Keep this file compact. It is loaded often by agents, so detailed procedures
belong in `docs/` and should be linked from here instead of duplicated.

## Active Scope

For users, the product is the graphical workstation installed on real hardware.
In Nix terms, that is the `workstation-gui` flake target.

| Target | Role |
| --- | --- |
| `workstation-gui` | Default real-hardware workstation install |
| `workstation` | Non-graphical base used by checks and development workflows |
| `vm` | Disposable local QEMU system for testing without real hardware |

For the user guide entry point, see `docs/user/index.md`.
For the clean-hardware install runbook, see `docs/user/installation/workstation.md`.
For local VM testing, see `docs/user/installation/vm.md`.

## Hard Rules

- Documentation must be written in English.
- Planning or chat may be in Russian.
- Home Manager is allowed only through the existing flake input and NixOS module
  integration. Treat it as a lightweight dotfiles/symlink wrapper, similar to
  Stow, for local user overlays only. Do not move system policy, package
  baselines, services, secrets, or real user identity/state into Home Manager.
  Do not add standalone Home Manager roots.
- Do not add active laptop-specific targets yet.
- Do not add active VPN targets yet.
- Do not commit real usernames, hostnames, SSH keys, API tokens, VPN tokens,
  hardware configuration, encrypted secrets, or secrets of any kind.
- Do not use or modify the user's global Git configuration for agent actions.
  Use repository-local Git config, command-scoped environment overrides, or
  provide explicit commands for the user to run when a global setting is needed.
- Custom scripts must use Nushell if scripts are needed.
- Keep the main branch buildable.
- Agents cannot validate Windows WSL2/QEMU runtime or real hardware installs
  directly.
- Agents must provide exact commands and expected results for local runtime or
  hardware validation.
- The user performs runtime and hardware verification locally.
- Agents must not claim runtime or hardware install success without user
  confirmation.
- For real-hardware installs, agents must treat user-run validation output as
  the hardware acceptance result.
- Deferred features: TPM unlock, YubiKey unlock, Secure Boot, automatic
  snapshots, impermanence, and hibernation.
- Automated backups are deferred. Future backup work may add remote untrusted
  storage, restic with rclone, or YubiKey-backed encryption.

## Read Docs First

Before changing a subsystem, read the relevant documentation instead of loading
unrelated files:

- User guide overview: `docs/user/index.md`
- Workstation install: `docs/user/installation/workstation.md`
- Workstation rebuilds: `docs/user/operations/rebuild.md`
- Maintenance and cleanup: `docs/user/operations/cleanup.md`
- Backups: `docs/user/operations/backups.md`
- Recovery and rollbacks: `docs/user/operations/recovery.md`
- VM local testing: `docs/user/installation/vm.md`
- Engineering overview: `docs/dev/index.md`
- Architecture overview: `docs/dev/architecture/layers.md`
- System composition: `docs/dev/architecture/composition.md`
- Security and network: `docs/dev/architecture/security.md`
- Storage and data: `docs/dev/architecture/storage.md`
- Boot UX: `docs/dev/architecture/boot.md`
- System tuning: `docs/dev/architecture/tuning.md`
- Command reference: `docs/dev/reference/just.md`
- Repository layout: `docs/dev/reference/layouts.md`
- Testing and validation: `docs/dev/reference/validation.md`
- Nix style guide: `docs/dev/standards/nix-style.md`

## Layout Rules

Only the `nixos/` tree is active for NixOS configuration. Do not add parallel
root-level `hosts/`, `profiles/`, or `modules/` trees.

Important layout references:

- Repository layout: `docs/dev/reference/layouts.md`
- NixOS architecture: `docs/dev/architecture/layers.md`
- Command surface: `docs/dev/reference/just.md`

## Commands

Use modular `just` commands. Prefer the docs reference for the full command
surface: `docs/dev/reference/just.md`.

Common checks:

```sh
just check
just docs build
just workstation-gui build
just workstation-gui test
just workstation build
just workstation test
just vm build
just vm test
```

Use `workstation-gui` for the default real-hardware workstation path. Use
`workstation` only for headless/core validation. Use `vm` only for disposable
local QEMU testing.

Build artifacts go to `target/` by default unless a command documents another
output path.

## Local Overlay

Real identity is local-only.

Default overlay path:

```txt
~/.nix-config-local/user.nix
```

Environment override:

```sh
NIX_CONFIG_LOCAL_USER=/path/to/user.nix just workstation-gui build
```

The committed example overlay in `examples/local/` must use fake values only.
