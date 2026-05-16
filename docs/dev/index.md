# 🛠️ Engineering Overview

Welcome to the engineering documentation for the NixOS Platform. This section is designed for developers who want to modify, test, and contribute to the system configuration.

## 💻 Cross-Platform Development

You do not need to be running NixOS to develop for this platform. Whether you are on **Windows (WSL)**, **macOS**, or a **standard Linux distribution**, you can iterate on the code and test it safely.

### 🐧 Environment Requirements
If you are NOT on NixOS, you will need the following installed on your host:

| Tool | Purpose |
| --- | --- |
| **Nix** | The engine used to evaluate and build the configuration. |
| **Just** | Command runner for all common workflows. |
| **QEMU** | Required to boot the virtual machine for testing. |
| **sshpass** | (Optional) Used for automated VM testing. |

### 🪟 Developing on Windows/WSL
- Use **WSL2** (Ubuntu or openSUSE recommended).
- Install Nix inside your WSL distribution.
- Ensure QEMU is installed inside WSL (it will use the Windows host for hardware acceleration automatically in most modern setups).
- See the [WSL Setup Guide](./setup/wsl) for a step-by-step walkthrough.

### Core Tools
We use `just` as a command runner to simplify common tasks.
- `just check`: Run formatting and policy checks.
- `just workstation-gui build`: Build the system closure without applying it.

## 🧪 Testing and Validation

Since you cannot "switch" to a NixOS configuration on a non-NixOS host, we rely heavily on **QEMU Virtual Machines**.

### Local VM Testing
Run the following to build and boot the current configuration in a disposable window:
```sh
just vm run
```
This is the primary way to verify that your changes (like adding a new package or service) don't break the boot process or core system functionality.

### CI/CD
Every pull request is automatically validated using GitHub Actions. It runs the same `just vm test` suite that you can run locally.

## 🏗️ Architecture Layers
Explore the sub-sections to understand how the system is put together:
- **[System Architecture](./system/)**: The logical organization of modules.
- **[Storage & Data](./system/storage)**: How we use Btrfs and LUKS.
- **[Build Model](./workflows/build-model)**: How the Nix evaluation and building process works.
