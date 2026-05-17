# 🛠️ Automated Validation

Validation starts with the smallest useful checks. We use a multi-layered approach to ensure the configuration is technically sound before it ever touches real hardware.

## 🧱 Core Build Checks

Run the flake checks and build the system closures explicitly to verify evaluation and compilation:

```sh
just check
just vm build
just workstation build
just workstation-gui build
```

## 🧪 Runtime Validation (QEMU)

Validate actual system behavior using a disposable virtual machine. This is the primary way to verify network, SSH, and service logic:

```sh
just vm test
```

Workstation profiles can also be validated without real hardware:

```sh
just workstation test
just workstation-gui test
```

`workstation-gui test` validates the graphical configuration without launching Hyprland or requiring a GPU.

## ✅ Pre-Flight Checklist

For a full local validation pass before opening or merging a change, run:

```sh
just check
just docs build
just vm test
just workstation-gui test
```

The workstation storage layout is evaluated with an example disk path only. Tests do not partition, format, or encrypt real disks.

Installer dry-run tests are part of the local script test suite:

```sh
just test
```

Expected result:

- Pure installer unit tests always run.
- Generated installer config dry-run tests run when a compatible `mkpasswd`
  implementation is available.
- Nix parsing, evaluation, and build-plan checks run when both `nix` and
  `nix-instantiate` are available.

On non-Nix development hosts, the unavailable Nix-dependent checks are skipped
with an explicit message. The real installer still enters a Nix shell from
`install.sh`, which provides the expected `mkpasswd` implementation.

For Linux root environments that can create loop devices, run the destructive
loopback storage test separately:

```sh
RUN_DISKO_LOOP_TEST=1 just test
```

Expected result:

- The test creates a temporary sparse disk image.
- `disko` partitions, encrypts, formats, and mounts it under `/mnt`.
- The test verifies `/mnt`, `/mnt/boot`, and `/mnt/boot/efi`, then unmounts and
  removes the temporary loop device.

Real install apply mode also performs pre-flight checks before destructive disk
operations: UEFI boot mode, required installer commands, free `/mnt`, and network
connectivity to `cache.nixos.org`.
