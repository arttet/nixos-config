# 🗺️ Roadmap

The NixOS Configuration grows incrementally. Each phase ensures the repository remains buildable, documented, and production-ready.

## 🏗️ Platform Foundation (Completed)

- **Automated Installation**: Single-command bootstrap and migration path from live ISO.
- **Product Layering**: Strict separation between the secure headless core and the rich graphical workstation.
- **Documentation Portal**: Comprehensive guide covering setup, operations, and diagnostics.
- **CI/CD Pipeline**: Automated validation of Nix flakes, formatting, and documentation.
- **Local Sandbox**: QEMU-based VM mirror for safe testing of configuration changes.

## ⚡ Active Evolution (Current Focus)

- **Hardware Profiles**: Optimization for specific device categories (Laptops vs. Desktops).
- **Automated Backups**: Orchestration of personal data and local state backups.
- **Unified Diagnostics**: Expanding the toolkit for real-time system health monitoring.

## 🚀 Strategic Horizon (Future Plans)

- **Secure Boot & TPM2**: Full hardware-backed security integration.
- **Appliance Skeleton**: Reusable foundation for dedicated VPN or server nodes.
- **Remote Orchestration**: Tools for managing multiple hosts from a single control point.

## 📍 In-Depth Strategy

### ⏳ [Deferred Features](./deferred-features)
Functionality that is planned but intentionally delayed to maintain focus on the core product stability.
