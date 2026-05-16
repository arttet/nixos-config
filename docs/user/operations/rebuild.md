# 🔄 Updates and Rebuilds

Use this page to apply changes to an installed workstation. 

Because this is a declarative system, you do not update software or change settings on the live system directly. Instead, you modify your local Git repository, test the changes, and then apply them.

## 🏗️ Applying Local Changes

If you've made modifications to your local repository (e.g., added a new package in your Nix modules), follow these steps to build and apply the new configuration.

First, make sure you are in the root of the repository:

```sh
test -f flake.nix && test -f justfile
```

It is highly recommended to build and test the configuration before switching to it. This validates your syntax and logic without touching your running system:

```sh
just workstation-gui build
```

```sh
just workstation-gui test
```

Once the tests pass, apply the new configuration to your system. This makes the changes live and creates a new bootable generation:

```sh
doas nixos-rebuild switch --flake .#
```

*(Note: If you encounter issues after switching, you can easily roll back to the previous generation via GRUB or the rollback command).*

## 📦 System Updates

Automatic background upgrades are intentionally disabled so your system remains completely predictable. When you are ready to update your packages to their latest versions, you update the `flake.lock` file.

First, update the lockfile to fetch the latest revisions of your inputs (like `nixpkgs`):

```sh
nix flake update
```

Run the formatting and policy checks:

```sh
just check
```

Build the system with the new updates:

```sh
just workstation-gui build
```

Run the local validation tests:

```sh
just workstation-gui test
```

Finally, apply the update to your live system:

```sh
doas nixos-rebuild switch --flake .#
```
