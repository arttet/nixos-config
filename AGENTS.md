# AGENTS.md

Repository instructions for `nix-config`.

## Active Scope

The active targets are:

```txt
workstation
vm
```

- `workstation` is the real-hardware, console-only personal workstation target.
- `vm` is the disposable local QEMU mirror of `workstation`.
- `vm` imports `workstation`.

## Rules

- Documentation must be written in English.
- Planning or chat may be in Russian.
- Do not use Home Manager.
- Do not add GUI services.
- Do not add active laptop-specific targets yet.
- Do not add active VPN targets yet.
- Do not commit real usernames, hostnames, SSH keys, API tokens, VPN tokens,
  hardware configuration, encrypted secrets, or secrets of any kind.
- Custom scripts must use Nushell if scripts are needed.
- Keep the main branch buildable.
- Agents cannot validate Windows WSL2/QEMU runtime or real hardware installs
  directly.
- Agents must provide exact commands and expected results for local runtime or
  hardware validation.
- The user performs runtime and hardware verification locally.
- Agents must not claim runtime or hardware install success without user
  confirmation.

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
├── nix/
├── nixos/
├── scripts/
└── target/        # ignored local build output
```

## NixOS Layout

Only the `nixos/` tree is active for NixOS configuration:

```txt
nixos/
├── hosts/
│   ├── vm/
│   └── workstation/
├── profiles/
│   ├── base.nix
│   ├── vm.nix
│   └── workstation.nix
└── modules/
    ├── core/
    └── storage/
```

Do not add parallel root-level `hosts/`, `profiles/`, or `modules/` trees.

## Commands

Use modular just commands:

```sh
just check
just vm build
just vm run
just vm daemon
just vm ssh
just vm status
just vm stop
just vm test
just vm clean
just workstation build
just workstation test
```

Build artifacts go to `target/` by default. Override with:

```sh
BUILD_DIR=/tmp/nix-config-build just vm build
```

## Local Overlay

Real identity is local-only.

Default overlay path:

```txt
~/.nix-config-local/user.nix
```

Environment override:

```sh
NIX_CONFIG_LOCAL_USER=/path/to/user.nix just workstation build
```

The committed example overlay in `examples/local/user.nix` must use fake values
only.
