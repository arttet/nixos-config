# Cleanup

VM state is disposable.

```sh
just vm clean
```

Build outputs are kept under `target/` by default and should remain outside git.
Cleaning removes runtime state and build output links, not the Nix store.
