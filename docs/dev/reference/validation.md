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
