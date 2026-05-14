# Overlays

Local overlays provide host-specific identity and private settings.

The repository can import an overlay from:

```txt
~/.nix-config-local/user.nix
```

or from `NIX_CONFIG_LOCAL_USER`.

Overlay files are local state. They must not be committed.

The NixOS module layer does not read environment variables directly. The public
flake resolves local overlay paths at the flake boundary and passes them into
NixOS through `specialArgs`. Normal CI evaluation does not depend on local
overlay files. Local workstation installation uses `--impure` explicitly so the
selected local overlay and generated hardware configuration can be imported.

## User Overlay

The user overlay should define the real local user, shell, wheel membership,
authorized SSH keys if needed, local hostname, local timezone, and optional
host-specific settings.

Start from the fake example:

```txt
examples/local/user.nix
```

Check the selected overlay path:

```sh
just overlay path
```

Validate that the overlay exists:

```sh
just overlay check
```

## Hardware Configuration

Generated hardware configuration is also local state. During install it is
expected at:

```txt
/mnt/etc/nixos/hardware-configuration.nix
```

After install it is expected at:

```txt
/etc/nixos/hardware-configuration.nix
```

Use `NIX_CONFIG_LOCAL_HARDWARE` to import the generated file during installation
or local validation. Do not commit it. Commands that rely on these environment
variables must use `--impure` explicitly.
