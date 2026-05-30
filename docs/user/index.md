# 📖 User Guide

Welcome to the comprehensive guide for using and maintaining your NixOS configuration. This system gives you a fully reproducible and disposable operating system built from code.

## 📦 The Profiles

The platform is organized into three primary targets (profiles). `workstation-gui` is the default.

| Profile               | Description                                                                                                          | When to use it                                                   |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **`workstation-gui`** | Full graphical desktop environment using Hyprland (Wayland), complete with browsers, editors, and development tools. | Install this on clean hardware and use it day to day.            |
| **`workstation`**     | The headless foundation. It includes core security, networking, tuning, and CLI tools, but no graphical session.     | Use this for servers or when you need a pure console experience. |
| **`vm`**              | A headless, disposable QEMU virtual machine used for local testing and CI validation.                                | Use it to test changes locally without touching real hardware.   |

## 🗺️ Documentation Map

### ✨ Getting Started

The fastest way to understand and use the platform.

| Guide                           | Description                                       |
| :------------------------------ | :------------------------------------------------ |
| **[Overview](./index)**         | This page — a high-level map of the entire guide. |
| **[Quick Start](./quickstart)** | The 60-second path to a running system.           |

### 🚀 Installation

Everything you need to get the system running on your hardware or in a virtual environment.

| Guide                                         | Description                              |
| :-------------------------------------------- | :--------------------------------------- |
| **[Workstation](./installation/workstation)** | Detailed hardware installation runbook.  |
| **[VM](./installation/vm)**                   | Setting up a disposable testing sandbox. |

### 🛠️ Daily Operations

How to keep your system updated, backed up, and clean.

| Guide                                             | Description                                    |
| :------------------------------------------------ | :--------------------------------------------- |
| **[Overview](./operations/)**                     | Key tasks for day-to-day management.           |
| **[Updates & Rebuilds](./operations/rebuild)**    | Applying changes to your configuration.        |
| **[Maintenance & Cleanup](./operations/cleanup)** | Managing disk space and Nix generations.       |
| **[Backups](./operations/backups)**               | Protecting your personal data and local state. |
| **[Recovery & Rollbacks](./operations/recovery)** | Reverting changes when things go wrong.        |

### 🔍 Diagnostics

Technical guides for troubleshooting and understanding system health.

| Guide                                             | Description                                |
| :------------------------------------------------ | :----------------------------------------- |
| **[Overview](./diagnostics/)**                    | Technical inspection of the system layers. |
| **[GRUB & Early Boot](./diagnostics/grub)**       | Solving boot issues.                       |
| **[Boot Time](./diagnostics/boot)**               | Analyzing and optimizing startup speed.    |
| **[Disk Space](./diagnostics/disk)**              | Finding where your storage went.           |
| **[Security & Auditing](./diagnostics/security)** | Checking logs and authentication.          |
| **[Networking](./diagnostics/network)**           | Debugging connectivity and latency.        |
