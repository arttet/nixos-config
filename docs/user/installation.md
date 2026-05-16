# 🚀 Quick Start

Welcome to the NixOS Platform! This system gives you a fully reproducible and disposable operating system built from code.

#### 📦 The Profiles

The platform is organized into three primary targets (profiles). `workstation-gui` is the default.

| Profile | Description | When to use it |
| --- | --- | --- |
| **`workstation-gui`** | The primary product. A full graphical desktop environment using Hyprland (Wayland), complete with browsers, editors, development tools, and multimedia support. Built on top of a secure, headless core. | Install this on clean hardware and use it day to day. |
| **`workstation`** | The headless foundation. It includes core security, networking, tuning, and CLI tools, but no graphical session. | Use this if you are building a server or just need a pure console experience. |
| **`vm`** | A headless, disposable QEMU virtual machine used for local testing and CI validation. | Use it when you want to test locally without touching real hardware. |

## ⚡ How to use this platform

If you are setting up a new computer, the process is streamlined into a single command. 

Boot your computer using the [official Minimal NixOS ISO](https://nixos.org/download), connect to Wi-Fi, and run:

```sh
curl -sL github.com/arttet/nixos-config/raw/main/install.sh | bash
```

The script will ask you a few simple questions (like your disk, hostname, and password) and then fully automate the partitioning, installation, and configuration of the default profile.

👉 **Read [Install Workstation](install-workstation)** for the detailed step-by-step installation guide.

## 🔄 Iterating on your system

Once installed, your system is declarative. Instead of running `apt install` or manually editing `/etc/` files, you:

1. Modify your local clone of the repository (e.g., enable a new tool in the Nix modules).
2. Validate changes locally using `just check` or by booting the VM with `just vm run`.
3. Apply the changes to your actual hardware:
   ```sh
   doas nixos-rebuild switch --flake .#
   ```

If you ever make a mistake, simply reboot and select the previous generation from the GRUB boot menu.
