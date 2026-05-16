# Repository Layout

The repository separates implementation, documentation, examples, and generated
artifacts.

Important directories:

- `nixos/` contains active NixOS modules, profiles, and hosts.
- `nixos/profiles/workstation/` contains workstation-scoped V1 product layers.
- `docs/` contains the VitePress documentation portal.
- `examples/` contains fake-only examples.
- `misc/justfiles/` contains reusable `just` modules.
- `formatter.nix` defines the repository formatter.
- `target/` contains local build output and is ignored by git.

Future milestone files may exist outside the active target, but they should not
be exposed until their milestone is ready.
