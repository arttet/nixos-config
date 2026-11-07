# Repository Layout

The repository separates implementation, documentation, examples, and generated
artifacts.

Important directories:

- `nixos/` contains active NixOS modules, profiles, and hosts.
- `nixos/profiles/workstation/` contains workstation-scoped V1 product layers.
- `docs/src/` contains the English user and engineering guides.
- `docs/.vitepress/` contains the VitePress configuration and theme.
- `docs/package.json` and `docs/aube-lock.yaml` define documentation dependencies.
- `templates/` contains reusable configuration templates.
- `schemas/` contains local-state schemas and fake-only validation fixtures.
- `scripts/` contains Nushell installer, maintenance, and test commands.
- `misc/justfiles/` contains reusable `just` modules.
- `formatter.nix` defines the repository formatter.
- `target/` contains local build output and is ignored by git.

Personal application configuration lives in the separate dotfiles repository.
Connect it through local `state.json` user sources (`dotfiles`, `dotfilesModule`,
`dotfilesRoot`, and `links`). Home Manager integrates these files through the
existing NixOS module; system policy and real machine identity stay outside the
dotfiles layer. See [Workstation Installation](../../user/installation/workstation).

Future milestone files may exist outside the active target, but they should not
be exposed until their milestone is ready.
