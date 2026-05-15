# System Architecture

The platform uses layers to avoid mixing public infrastructure with private machine state.

Public NixOS modules define reusable behavior. Profiles define reusable system shapes. Host targets compose profiles. Local overlays provide identity. Generated build output remains disposable.

The `workstation` profile owns the shared headless core for future real hardware. Storage modules provide the opt-in installation layout for that hardware profile. The security, network, and tuning modules provide conservative real-hardware defaults through `platform.security`, `platform.network`, and `platform.tuning`.

The `workstation-gui` target imports the headless core and adds workstation-only product layers from `nixos/profiles/workstation/`. GUI software, browsers, desktop applications, containers, and language stacks must stay scoped to those workstation layers.

The application and development package contract is documented in
[Workstation Applications](./applications.md).

The `vm` profile imports `workstation` and keeps QEMU-only settings out of the hardware profile.

Destructive disk operations belong to the installation path, not to default build, CI, or VM runtime workflows.

Local overlays and generated hardware configuration form the private hardware layer. They are imported from local paths and must not be committed.

This keeps the repository useful without turning it into a record of one machine's accidental state.

## Overlays & Secrets

Local overlays provide host-specific identity and private settings. **Secrets and identity stay outside git.**

The repository may define where private material enters the system, but it must not contain real usernames, SSH keys, API tokens, VPN credentials, hardware configuration, generated machine identity, or encrypted secrets.

The repository can import an overlay from:

```txt
~/.nix-config-local/user.nix
```

or from `NIX_CONFIG_LOCAL_USER`.

Overlay files are local state. They must not be committed.

The NixOS module layer does not read environment variables directly. The public flake resolves local overlay paths at the flake boundary and passes them into NixOS through `specialArgs`. Normal CI evaluation does not depend on local overlay files. Local workstation installation uses `--impure` explicitly so the selected local overlay and generated hardware configuration can be imported.

### User Overlay

The user overlay should define the real local user, shell, wheel membership, authorized SSH keys if needed, local hostname, local timezone, and optional host-specific settings.

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

### Hardware Configuration

Generated hardware configuration is also local state. During install it is expected at:

```txt
/mnt/etc/nixos/hardware-configuration.nix
```

After install it is expected at:

```txt
/etc/nixos/hardware-configuration.nix
```

Use `NIX_CONFIG_LOCAL_HARDWARE` to import the generated file during installation or local validation. Do not commit it. Commands that rely on these environment variables must use `--impure` explicitly.

## Targets

The active runtime target is `vm`.
The active real-hardware profile target is `workstation`.
The active V1 workstation product target is `workstation-gui`.

### Workstation Profile

The `workstation` profile is the reusable headless core for future real hardware targets: laptop, mini-PC, or desktop.

It enables NetworkManager and keeps OpenSSH disabled by default. The package set is intentionally small: `git`, `curl`, `wget`, `jq`, `just`, `nushell`, `helix`, `btop`, `pciutils`, `usbutils`, and basic archive tools.

`workstation-gui` is the V1 GUI/product composition. It imports the headless core and adds workstation-scoped layers from `nixos/profiles/workstation/`.

The profile uses a UEFI/GRUB2 boot model with systemd initrd. Its storage layout is prepared as an opt-in installation path with a parameterized disk device, GPT, a 512 MiB ESP mounted at `/boot/efi`, a 512 MiB unencrypted ext4 `/boot`, LUKS2 encrypted root, Btrfs subvolumes, and swapfile support.

The profile enables the conservative `platform.tuning` layer for real hardware. The `vm` profile disables this layer to keep local QEMU runtime simple.

The profile enables the conservative `platform.security` layer and the explicit `platform.network` DNS policy.

### VM Profile

The `vm` profile is the local QEMU mirror of `workstation`.

It imports `workstation`, then adds VM-only behavior:
- QEMU guest support.
- Serial console settings.
- Headless VM graphics settings.
- QEMU memory, disk, port forwarding, and runtime assumptions.
- The temporary public test user used by local VM validation.

VM state is disposable. The profile exists to validate workstation changes before applying them to future real hardware.

The VM keeps QEMU storage settings in the VM target. It does not apply the workstation storage layout during normal runtime commands.

The VM disables the real-hardware `platform.tuning`, `platform.security`, and `platform.network` layers to remain a fast disposable runtime target. These layers are validated through workstation evaluation instead.

The VM may enable SSH for local validation. The workstation profile disables SSH by default.

## Future Targets

Future targets should be added deliberately. A target becomes active only when its architecture, documentation, security boundary, and validation path are clear.
