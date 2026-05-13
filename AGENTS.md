# AGENTS.md

Repository instructions for `nix-config`.

## Active Milestone

Milestone 002 is the active implementation scope.

Goal: prepare the first stable merge with documentation cleanup, CI/CD,
Cloudflare Pages deployment, daemonized guest lifecycle commands, and basic
guest validation.

## Rules

- Documentation must be written in English.
- Planning or chat may be in Russian.
- Do not use Home Manager.
- Do not add GUI services.
- Do not add active laptop targets yet.
- Do not add active VPN targets yet.
- Do not add disk encryption yet.
- Do not commit real usernames, hostnames, SSH keys, API tokens, VPN tokens,
  hardware configuration, encrypted secrets, or secrets of any kind.
- Custom scripts must use Nushell if scripts are needed.
- Keep the main branch buildable.
- Agents cannot validate the Windows WSL2/QEMU runtime directly.
- Agents must provide exact commands and expected results for local runtime
  verification.
- The user performs runtime verification locally.
- Agents must not claim runtime success without user confirmation.

## Active Target

Only one runtime target is active:

```txt
guest
```

The `guest` target is:

- minimal
- headless
- QEMU-oriented
- disposable
- intended for local development and validation

Older target files may remain in the repository for future milestones, but they
are not part of the active milestone 002 flake or just workflow.

## Repository Layout

```txt
nix-config/
├── flake.nix
├── flake.lock
├── README.md
├── AGENTS.md
├── justfile
├── docs/
├── examples/
├── misc/
├── nixos/
├── scripts/
└── target/        # ignored local build output
```

## NixOS Layout

```txt
nixos/
├── hosts/
│   └── guest/
│       └── default.nix
├── profiles/
│   ├── base.nix
│   └── guest.nix
└── modules/
    └── core/
        ├── local-overlay.nix
        └── users.nix
```

## Commands

Use modular just commands:

```sh
just check
just guest build
just guest run
just guest daemon
just guest ssh
just guest status
just guest stop
just guest test
just guest clean
```

Build artifacts go to `target/` by default. Override with:

```sh
BUILD_DIR=/tmp/nix-config-build just guest build
```

## Local Overlay

Real identity is local-only.

Default overlay path:

```txt
~/.nix-config-local/user.nix
```

Environment override:

```sh
NIX_CONFIG_LOCAL_USER=/path/to/user.nix just guest build
```

The committed example overlay in `examples/user.nix` must use fake values only.
