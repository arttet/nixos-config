# 🏗️ Local Environment

To contribute to this platform, you need a local development environment capable of running **Nix** and **QEMU**. 

One of the core strengths of this repository is that it is **distro-agnostic**. You do not need to be running NixOS to build, test, or modify the configuration.

## 🛠️ Environment Guides

Depending on your host operating system, follow the specific setup instructions below:

| Environment | Description | Link |
| :--- | :--- | :--- |
| **Mutable Linux** | Instructions for setting up the Nix package manager and virtualization tools on a standard Linux distribution (like Arch Linux). | [View Guide](./mutable_linux) |
| **WSL2** | The recommended path for Windows users. We use **openSUSE Tumbleweed** inside WSL2 as the host for Nix. | [View Guide](./wsl) |
