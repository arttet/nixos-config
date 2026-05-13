# Build Model

The active build target is the `guest` NixOS VM.

Nix evaluates the flake, builds the VM closure, and writes local output under
`target/` through the `just` workflow.

The build output is an artifact, not source.
