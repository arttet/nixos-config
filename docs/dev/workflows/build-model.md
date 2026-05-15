# Build Model

The active build targets are the `workstation` system closure and the `vm`
NixOS VM.

Nix evaluates the flake, builds the requested closure, and writes local output
under `target/` through the `just` workflow.

The build output is an artifact, not source.
