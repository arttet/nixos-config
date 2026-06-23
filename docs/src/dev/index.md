# 🛠️ Engineering Overview

Welcome to the engineering documentation for the NixOS Configuration. This section is designed for developers who want to modify, test, and contribute to the system configuration.

## 🐧 Environment Requirements

Regardless of your host operating system, you will need the following tools installed to interact with this repository:

| Tool        | Purpose                                                                        |
| ----------- | ------------------------------------------------------------------------------ |
| **Nix**     | The engine used to evaluate and build the configuration (with Flakes enabled). |
| **Git**     | Required for version control and cloning the repository.                       |
| **Just**    | Command runner used for all common development workflows.                      |
| **QEMU**    | Required to boot the virtual machine for local testing and validation.         |
| **sshpass** | (Optional) Used for automated VM testing.                                      |

## 💻 Cross-Platform Development

You do not need to be running NixOS to develop for this platform. Whether you are on Windows (WSL) or a standard mutable Linux distribution, you can iterate on the code and test it safely.

| Operating System  | Recommended Environment                     | Setup Guide                         |
| :---------------- | :------------------------------------------ | :---------------------------------- |
| **Mutable Linux** | Native Nix package + QEMU (e.g. Arch Linux) | [View Guide](./setup/mutable_linux) |
| **WSL2**          | openSUSE Tumbleweed + Nix + QEMU            | [View Guide](./setup/wsl)           |

## 🧪 Testing & Safety

We prioritize a **Safe Sandbox** philosophy. You should never have to risk your primary operating system to test a configuration change.

- **Disposable Environments**: We use QEMU Virtual Machines as our primary development target. This allows you to boot and interact with your changes in seconds, completely isolated from your host hardware.
- **Identical Verification**: The same tests you run locally with `just vm test` are executed in our CI/CD pipeline, ensuring that what works on your machine will work for everyone.

## 🗺️ Engineering Map

If you are new to the project, we recommend exploring the documentation in this order:

1. **[Development Guide](./guide/)**: Learn how to write Nix code according to our standards and how to validate your changes in the sandbox.
2. **[Architecture & Design](./architecture/)**: Understand the "Why" behind our layered model and compare the different system profiles.
3. **[Reference](./reference/)**: Access technical specifications, repository layouts, and the full command library.
