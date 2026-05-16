# Build Model

The main build target is the graphical workstation system closure. The headless
`workstation` closure and the `vm` target remain supporting validation targets.

Nix evaluates the flake, builds the requested closure, and writes local output
under `target/` through the `just` workflow.

The build output is an artifact, not source.
