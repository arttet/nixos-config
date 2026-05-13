# Overlays

Local overlays provide host-specific identity and private settings.

The repository can import an overlay from:

```txt
~/.nix-config-local/user.nix
```

or from `NIX_CONFIG_LOCAL_USER`.

Overlay files are local state. They must not be committed.
