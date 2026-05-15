# Rebuilding

Rebuild the VM whenever infrastructure changes:

```sh
just vm build
```

Boot it again to validate runtime behavior:

```sh
just vm run
```

For background operation:

```sh
just vm daemon
just vm status
just vm stop
```

Rebuild an installed workstation with explicit `doas` escalation:

```sh
doas nixos-rebuild switch --flake .#workstation
```

Rollback to the previous generation:

```sh
doas nixos-rebuild switch --rollback
```

## Manual Updates

Automatic system upgrades are disabled. Updates are manual and deliberate:

```sh
nix flake update
just check
just workstation build
just workstation test
doas nixos-rebuild switch --flake .#workstation
```

This keeps kernel, nixpkgs, and platform changes tied to reviewed `flake.lock`
updates.
