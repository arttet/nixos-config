# 🚀 Quick Start

The platform provides a streamlined path from initial hardware migration to daily declarative iteration.

## ⚡ Migration from Mutable Linux

To replace your current operating system with this declarative configuration, boot your computer using the [official Minimal NixOS ISO](https://nixos.org/download), connect to Wi-Fi, and run:

```sh
curl -sL github.com/arttet/nixos-config/raw/main/install.sh | bash
```

The script will ask you a few simple questions (like your disk, hostname, and password) and then fully automate the partitioning, installation, and configuration of the default profile.

👉 **Read [Workstation](./installation/workstation)** for the detailed step-by-step hardware installation guide.

## 🔄 Daily Iteration on NixOS

Once your machine is running this NixOS Configuration, you no longer perform manual system tweaks. Instead, you manage the system through your local Git repository:

1. **Modify**: Update your local clone (e.g., enable a new tool in the Nix modules).
2. **Validate**: Check changes locally using `just check` or by booting the VM with `just vm run`.
3. **Apply**: Switch your running system to the new generation:
   ```sh
   doas nixos-rebuild switch --flake .#
   ```

If you ever make a mistake, simply reboot and select the previous generation from the GRUB boot menu.

👉 **Read [Operations](./operations/)** for daily maintenance, updates, and rebuild guides.
