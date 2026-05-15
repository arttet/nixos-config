# Migration Handbook: From Mutable to Declarative

Transitioning to NixOS is not just about switching distributions; it's a fundamental shift from a **machine-centric** model to a **configuration-centric** model.

In a traditional "mutable" system (like Fedora, Ubuntu, or Arch), state accumulates over years. Configurations drift, random packages are installed and forgotten, and the system becomes a "snowflake" that is impossible to reproduce exactly.

In the NixOS Platform model, the system is a pure function of its configuration.

## 🎯 The Goal

After the transition:
- The system is built entirely from a Git repository.
- Every rebuild is reproducible.
- Rollbacks are a standard, built-in operation.
- A new machine = `git clone` + `nixos-install`.
- System configuration is strictly separated from local identity and secrets.
- **System drift disappears.**

## 📋 Pre-Migration Inventory

Before you wipe your current drive, you must separate what belongs to the "system" and what belongs to "you".

### 1. Hardware & System Level
These will be codified into NixOS modules:
- Partitioning & Encryption layout.
- Kernel parameters and tuning.
- System-level services (Docker, SSH, Tailscale).
- Global fonts and locales.
- Hardware-specific firmware (NVIDIA, Wi-Fi, Bluetooth).

### 2. User & Identity Level
These will live in local overlays or Home Manager:
- Real usernames and hashed passwords.
- Authorized SSH keys.
- Private VPN tokens or API keys.
- Personal dotfiles and application settings.

### 3. The "Garbage"
**Do not migrate everything.** Leave behind:
- Randomly installed binaries in `/usr/local/bin`.
- Accumulated state in old config files.
- Temporary hacks that are no longer needed.

## 🛠 The Installation Ritual

The physical installation is the "ceremony" where you commit your hardware to the declarative model.

1. **Boot the Installer:** Use a standard NixOS ISO.
2. **Partitioning:** We use a LUKS2 + Btrfs layout. Btrfs subvolumes (`@root`, `@home`, `@nix`, `@log`, `@swap`) are natural fits for the NixOS generation model.
3. **Generate Hardware Config:** Run `nixos-generate-config` to capture the physical device IDs, then move them into your repository's hardware layer.
4. **Clone & Install:** Clone your platform repository and run `nixos-install --flake .#workstation`.
5. **Reboot:** You are now running a declarative system.

## 🔄 Iterative Codification

The real migration happens **after** the first boot. You don't try to describe everything at once. You build your platform in stages:

- **Stage 1: Core:** Boot, Network, SSH, Browser, Git.
- **Stage 2: Developer Tooling:** Compilers, Docker, Debuggers.
- **Stage 3: Desktop:** Desktop Environment, Fonts, Audio.
- **Stage 4: Tuning:** Performance, Power management.
- **Stage 5: Hardening:** Secure Boot, USBGuard, Sandboxing.

## 🧠 Changing Your Mindset

On a traditional system, you think: *"How do I configure this laptop?"*
On NixOS, you think: *"How do I describe this platform?"*

You might feel "empty" at first because there is no accumulated junk. But soon, you will find it impossible to go back. The peace of mind that comes from knowing exactly what is in your system, and being able to roll back any mistake in seconds, is the ultimate Developer Experience.
