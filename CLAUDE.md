# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Source of truth

`AGENTS.md` at the repo root is the canonical short rules sheet — read it first when you arrive cold. Detailed runbooks live in `docs/`; this file only points at them.

- User runbooks: `docs/user/installation/workstation.md`, `docs/user/operations/{rebuild,cleanup,recovery,backups}.md`
- Engineering: `docs/dev/architecture/{layers,composition,security,storage,boot,tuning}.md`
- Style: `docs/dev/standards/nix-style.md`
- Layout: `docs/dev/reference/layouts.md`
- Validation: `docs/dev/reference/validation.md`

## Commands

`just` is the only command surface. Recipes are grouped via `mod` imports from `misc/justfiles/*.just`.

```sh
just check                  # nix flake check (formatting + policy assertions)
just fmt                    # nixfmt via treefmt
just build [profile]        # nix build of nixosConfigurations.<profile>.config.system.build.toplevel
just test  [profile]        # build + scripts/tests/run.nu + GRUB / Secure-Boot tool assertions
just switch [profile]       # doas nixos-rebuild switch --install-bootloader --flake path:<repo>#<profile> --impure
just vm test                # QEMU smoke: daemon start, SSH reach, network
just desktop test   # build + headless validate of Desktop profile (no GPU)
just docs build             # VitePress build under docs/
```

`profile` defaults to `default` (= `desktop`). For runtime install on real hardware the entry point is `./install.sh`, which runs `nu scripts/install/bootstrap.nu --apply`.

Pre-flight before opening a PR (from `docs/dev/reference/validation.md`):

```sh
just check && just docs build && just vm test && just desktop test
```

Destructive loopback storage test (Linux root only):

```sh
RUN_DISKO_LOOP_TEST=1 just test
```

## Architecture

Three flake targets exposed by `flake.nix`. The user-facing product is `desktop`; the others exist for validation:

| Target | Purpose |
| --- | --- |
| `desktop` | Default real-hardware install (Hyprland, PipeWire, browsers) |
| `workstation` | Headless baseline used by checks and dev workflows |
| `vm` | Disposable QEMU profile for runtime smoke tests |

Layering (strict, enforced by `docs/dev/architecture/composition.md`):

```
nixos/modules/{core,storage}/   →  reusable capability modules (each gated by `platform.<name>.enable`)
nixos/profiles/                 →  collections that define a system shape (base, vm, workstation/*)
nixos/hosts/<target>/           →  final composition entry point per flake target
local overlay (outside git)     →  machine identity: hostname, user, passwords, hardware-configuration.nix
```

The headless `workstation` profile must remain fully functional without X11/Wayland; `desktop` imports it and adds the UI stack only. Do not leak desktop apps into core modules.

### Local overlay (machine identity)

Machine-specific config never goes in git. The flake reads it from a path supplied at evaluation time:

- Default overlay shim: `/etc/nixos/local/default.nix` (per `misc/justfiles/overlay.just`)
- Default state contract: `/etc/nixos/local/state.json`
- Override: `NIX_CONFIG_LOCAL_USER=/path/to/default.nix` and `NIX_CONFIG_LOCAL_HARDWARE=/path/to/hardware-configuration.nix`
- `/etc/nixos/local/default.nix` + `/etc/nixos/hardware-configuration.nix` are auto-discovered via `localPathOrNull` in `flake.nix` (uses `builtins.pathExists` + `tryEval` so missing files degrade to `null` instead of breaking pure evaluation).
- Assertions in `nixos/modules/core/local-overlay.nix` only fire if env vars point to a non-existent path.
- User identity, hostname, timezone, password paths, and dotfiles sources belong in `state.json` under `users[]`, not in generated per-user Nix files.

`just switch` always passes `--impure` so `builtins.getEnv` resolves these env vars; `just check` runs pure (CI-safe).

## Hard rules

From `AGENTS.md` — load before touching anything:

- Documentation is English; planning/chat may be Russian.
- Home Manager is allowed only through the existing flake input and NixOS module integration. Treat it as a lightweight dotfiles/symlink wrapper, similar to Stow, for local user overlays only. Do not move system policy, package baselines, services, secrets, or real user identity/state into Home Manager. Do not add standalone Home Manager roots. No active laptop or VPN targets yet.
- Custom scripts must be Nushell.
- Never commit real usernames, hostnames, SSH keys, tokens, hardware configs, or any secret material.
- Do not use or modify the user's global Git configuration for agent actions; use repository-local Git config, command-scoped environment overrides, or provide explicit commands for the user to run.
- Main branch must stay buildable.
- Agents cannot validate real hardware or Windows WSL2/QEMU runtime directly — provide exact commands and expected results; treat user-run output as the acceptance result. Do not claim runtime success without user confirmation.
- Deferred features (not currently implemented): TPM unlock, YubiKey unlock, automatic snapshots, impermanence, hibernation, automated backups. See `docs/evolution/roadmap/deferred-features.md`.
- Only the `nixos/` tree is active — do not create parallel root-level `hosts/`, `profiles/`, or `modules/` directories.

## Nix style (see `docs/dev/standards/nix-style.md`)

- camelCase option names describing capability/policy: `platform.security.hardenedKernel.enable`, not `platform.enable_linux_hardened`.
- `default.nix` for directory entry points, kebab-case for specific module files (`local-overlay.nix`, `boot-ux.nix`).
- Every module wraps its body in `lib.mkIf cfg.enable { … }`; importing a module must not activate it.
- No `with pkgs;`, no `builtins.readDir` auto-import — explicit only.
- Pin every flake input in `flake.nix`.
- Unfree packages only in `desktop`, declared explicitly.

## Flake checks worth knowing

`flake.nix` exposes static policy assertions under `checks.${system}`:

- `formatting` — treefmt
- `workstation-kernel-policy` — workstation uses `pkgs.linuxPackages_latest`
- `workstation-secure-boot-policy` — GRUB enabled with `--disable-shim-lock` + `--modules=tpm`; `sbctl`, `efibootmgr`, `sbsigntool`, `grub2` present on workstation, absent from `vm`
- `workstation-storage-layout` — disko GPT layout: 512M ESP, 512M /boot, LUKS2-encrypted btrfs root with `@root` + `@swap` subvolumes

These run in `just check`. They are evaluation-only — they don't prove runtime behavior.
