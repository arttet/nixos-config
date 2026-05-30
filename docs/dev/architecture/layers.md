# 🏛️ Architecture Overview

The NixOS Configuration is a layered infrastructure designed to separate public system logic from private machine identity. This approach ensures that the repository remains reproducible and shareable without exposing sensitive data or hardware-specific noise.

## 📊 Profile Comparison

The platform is composed of three primary targets. Use this table to understand the technical boundaries and feature sets of each profile.

| Feature          | `workstation-gui`       | `workstation`           | `vm`                    |
| :--------------- | :---------------------- | :---------------------- | :---------------------- |
| **Primary Goal** | Daily productivity      | Headless foundation     | Local validation        |
| **Graphics**     | Hyprland (Wayland)      | Headless (Console)      | Headless / Serial       |
| **Audio**        | PipeWire & WirePlumber  | Disabled                | Disabled                |
| **Networking**   | NetworkManager + Applet | NetworkManager (CLI)    | NetworkManager (CLI)    |
| **Security**     | `doas`, Hardened Kernel | `doas`, Hardened Kernel | `doas`, Standard Kernel |
| **Storage**      | LUKS2 + Btrfs           | LUKS2 + Btrfs           | Ext4 (Disposable)       |
| **Browsers**     | Zen, Brave, Chrome      | None                    | None                    |
| **Containers**   | Docker enabled          | Optional                | Optional                |

## 🏗️ The Layering Model

1. **Core Modules**: Reusable logic (Security, Networking, Tuning) that defines _how_ a feature works.
2. **Profiles**: Collections of modules that define _what_ a system is (e.g., a workstation).
3. **Hosts**: The final composition of profiles and local overrides for specific hardware.
4. **Local Overlay**: Machine-specific identity (hostname, user, password) kept outside of Git.

For a deeper look into how these layers are implemented, see the [System Design](./composition) guide.
