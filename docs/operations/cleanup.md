# Cleanup

Guest VM state is disposable.

```sh
just guest clean
```

Build outputs are kept under `target/` by default and should remain outside git.
Cleaning removes runtime state and build output links, not the Nix store.
