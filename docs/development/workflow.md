# Workflow

The repository is designed for local feedback.

Make a small change. Build the VM. Boot it. Validate behavior. Update the
docs while the decision is still fresh.

```sh
just check
just vm build
just vm run
```

Build output stays under `target/` by default. Override it with `BUILD_DIR` when
testing isolated builds.

## Flake Source Visibility

Nix flakes only see files tracked by git. If a newly added Nix file is referenced
by `flake.nix`, stage it before running checks:

```sh
git add nixos/hosts/vm/default.nix
```

For a larger new tree, stage the whole directory:

```sh
git add nixos docs examples misc
```
