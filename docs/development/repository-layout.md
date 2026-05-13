# Repository Layout

The repository separates implementation, documentation, examples, and generated
artifacts.

Important directories:

- `nixos/` contains active NixOS modules, profiles, and hosts.
- `docs/` contains the VitePress documentation portal.
- `examples/` contains fake-only examples.
- `misc/justfiles/` contains reusable `just` modules.
- `target/` contains local build output and is ignored by git.

Future milestone files may exist outside the active target, but they should not
be exposed until their milestone is ready.
