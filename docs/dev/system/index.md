# 🏗️ System Architecture

This section documents the technical design and internal layers of the NixOS Platform. It covers how we handle everything from low-level disk encryption to high-level application policies.

## Key Design Areas

### 🏛️ [Architecture Overview](./architecture)
The "big picture" of how modules, profiles, and host configurations interact while keeping secrets and local state separate from Git.

### 🛡️ [Security & Network](./security)
Detailed look at the hardening policies, firewall settings, and network stack tuning.

### 💾 [Storage & Data](./storage)
Documentation on the Btrfs subvolume layout, LUKS2 encryption, and swap management.

### 🖼️ [Boot UX](./boot-ux)
How we manage the GRUB bootloader, Plymouth splash screens, and kernel parameters.

### 🚀 [System Tuning](./tuning)
Performance optimizations, sysctl tweaks, and hardware-specific adjustments.

### 📦 [Workstation Applications](./applications)
The "contract" of which packages are included in the graphical product and how we handle unfree software.

### ❄️ [Workstation Freeze](./workstation-freeze)
Design details on how we ensure environment stability and prevent accidental configuration drift.
