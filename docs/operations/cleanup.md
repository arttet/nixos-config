# Cleanup

VM state is disposable.

```sh
just vm clean
```

Build outputs are kept under `target/` by default and should remain outside git.
Cleaning removes runtime state and build output links, not the Nix store.

The workstation enables conservative automatic Nix garbage collection:

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 14d";
};
```

Inspect roots before manual cleanup:

```sh
nix-store --gc --print-roots
nix profile history --profile /nix/var/nix/profiles/system
```

Avoid deleting rollback generations too aggressively on a real workstation.
