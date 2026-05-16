# 🔄 Development Guide

This guide describes the "Inner Loop" of platform development: how to modify the configuration, verify your changes safely, and prepare them for production.

## 🔁 The Inner Loop

The standard development cycle follows these three steps:

1. **Edit**: Modify a module or profile under `nixos/`.
2. **Build**: Verify that the code evaluates and compiles correctly.
3. **Test**: Boot the configuration in a local QEMU virtual machine to ensure behavior is correct.

## 🧪 Local Verification

Because applying changes directly to your physical hardware is risky, we use a disposable VM for testing.

### 1. Build and Run the VM
This will compile your current Git state and launch a QEMU window:
```sh
just vm run
```

### 2. Automated Tests
Run the automated test suite to verify network, SSH, and core services:
```sh
just vm test
```

## 🏗️ Building Products

To verify that the full workstation product builds without errors (without launching a VM or applying it):

```sh
just workstation-gui build
```

The build output is stored in the `target/` directory, which is ignored by Git.

## 🚢 Next Steps

Once your changes are verified in the VM, you can follow the [Automated Validation](../reference/validation) to prepare a Pull Request.
