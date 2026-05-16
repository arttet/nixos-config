# 🏗️ System Architecture

This section documents the technical design and internal layers of the NixOS Configuration. It covers how we handle everything from low-level disk encryption to high-level application policies.

## Key Design Areas

### 🏛️ [Architecture Overview](./layers)
The high-signal comparison of platform profiles and their technical boundaries.

### 📜 [System Design & Composition](./composition)
How modules, profiles, and host configurations interact while keeping secrets and local state separate from Git.

### 🛡️ [Security & Network](./security)
Detailed look at the hardening policies, firewall settings, and network stack tuning.

### 💾 [Storage & Data](./storage)
Documentation on the Btrfs subvolume layout, LUKS2 encryption, and swap management.

### 🖼️ [Boot UX](./boot)
How we manage the GRUB bootloader, Plymouth splash screens, and kernel parameters.

### 🚀 [System Tuning](./tuning)
Performance optimizations, sysctl tweaks, and hardware-specific adjustments.

### ❄️ [Product Freeze](./freeze)
Design details on how we ensure environment stability and prevent accidental configuration drift.
