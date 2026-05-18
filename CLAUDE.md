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
just switch [profile]       # doas nixos-rebuild switch --install-bootloader --flake .#<profile> --impure
just vm test                # QEMU smoke: daemon start, SSH reach, network
just workstation-gui test   # build + headless validate of GUI profile (no GPU)
just docs build             # VitePress build under docs/
```

`profile` defaults to `default` (= `workstation-gui`). For runtime install on real hardware the entry point is `./install.sh`, which runs `nu scripts/install/bootstrap.nu --apply`.

Pre-flight before opening a PR (from `docs/dev/reference/validation.md`):

```sh
just check && just docs build && just vm test && just workstation-gui test
```

Destructive loopback storage test (Linux root only):

```sh
RUN_DISKO_LOOP_TEST=1 just test
```

## Architecture

Three flake targets exposed by `flake.nix`. The user-facing product is `workstation-gui`; the others exist for validation:

| Target | Purpose |
| --- | --- |
| `workstation-gui` | Default real-hardware install (Hyprland, PipeWire, browsers) |
| `workstation` | Headless baseline used by checks and dev workflows |
| `vm` | Disposable QEMU profile for runtime smoke tests |

Layering (strict, enforced by `docs/dev/architecture/composition.md`):

```
nixos/modules/{core,storage}/   →  reusable capability modules (each gated by `platform.<name>.enable`)
nixos/profiles/                 →  collections that define a system shape (base, vm, workstation/*)
nixos/hosts/<target>/           →  final composition entry point per flake target
local overlay (outside git)     →  machine identity: hostname, user, passwords, hardware-configuration.nix
```

The headless `workstation` profile must remain fully functional without X11/Wayland; `workstation-gui` imports it and adds the UI stack only. Do not leak desktop apps into core modules.

### Local overlay (machine identity)

Machine-specific config never goes in git. The flake reads it from a path supplied at evaluation time:

- Default path: `~/.nix-config-local/user.nix` (per `misc/justfiles/overlay.just`)
- Override: `NIX_CONFIG_LOCAL_USER=/path/to/user.nix` and `NIX_CONFIG_LOCAL_HARDWARE=/path/to/hardware-configuration.nix`
- The legacy `/etc/nixos/local/default.nix` + `/etc/nixos/hardware-configuration.nix` are still auto-discovered via `localPathOrNull` in `flake.nix` (uses `builtins.pathExists` + `tryEval` so missing files degrade to `null` instead of breaking pure evaluation).
- Assertions in `nixos/modules/core/local-overlay.nix` only fire if env vars point to a non-existent path.
- The committed `examples/local/user.nix` and `examples/local/default.nix` must contain fake values only.

`just switch` always passes `--impure` so `builtins.getEnv` resolves these env vars; `just check` runs pure (CI-safe).

## Hard rules

From `AGENTS.md` — load before touching anything:

- Documentation is English; planning/chat may be Russian.
- No Home Manager. No active laptop or VPN targets yet.
- Custom scripts must be Nushell.
- Never commit real usernames, hostnames, SSH keys, tokens, hardware configs, or any secret material.
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
- Unfree packages only in `workstation-gui`, declared explicitly.

## Flake checks worth knowing

`flake.nix` exposes static policy assertions under `checks.${system}`:

- `formatting` — treefmt
- `workstation-kernel-policy` — workstation uses `pkgs.linuxPackages_latest`
- `workstation-secure-boot-policy` — GRUB enabled with `--disable-shim-lock` + `--modules=tpm`; `sbctl`, `efibootmgr`, `sbsigntool`, `grub2` present on workstation, absent from `vm`
- `workstation-storage-layout` — disko GPT layout: 512M ESP, 512M /boot, LUKS2-encrypted btrfs root with `@root` + `@swap` subvolumes

These run in `just check`. They are evaluation-only — they don't prove runtime behavior.
