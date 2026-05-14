# Hardware Layer

Real hardware configuration is local state.

The public repository must not contain a real `hardware-configuration.nix`,
serial numbers, disk IDs, hostnames, usernames, SSH keys, or secrets.

During installation, NixOS generates hardware configuration under:

```txt
/mnt/etc/nixos/hardware-configuration.nix
```

After installation, the runtime path is:

```txt
/etc/nixos/hardware-configuration.nix
```

The repository can import a local hardware configuration through:

```sh
NIX_CONFIG_LOCAL_HARDWARE=/mnt/etc/nixos/hardware-configuration.nix
```

The local user and host policy lives in the local overlay. The default overlay
path is:

```txt
~/.nix-config-local/user.nix
```

The workstation install path must fail during local planning if the user overlay
is missing. Hardware configuration is generated during the install flow and must
be reviewed before `nixos-install`.
