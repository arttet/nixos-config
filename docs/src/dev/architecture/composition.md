# 📜 System Design & Composition

In this platform, a "system" is not a static list of packages. It is a dynamic **product composition** built by layering NixOS modules. This ensures that the headless core remains secure and lean, while the graphical product adds rich functionality on top.

## 🧱 The Composition Policy

We follow a strict "No Leakage" policy between layers:

1. **Headless Baseline**: The `workstation` profile must remain fully functional without any X11 or Wayland dependencies. It owns security, filesystem, and network stack logic.
2. **Graphical Layer**: `workstation-gui` imports the headless baseline and adds the UI stack (Hyprland, Wayland tools, fonts).
3. **Application Layer**: Desktop applications (Browsers, Office, Communication) are scoped strictly to the GUI profile. They must not appear in the core system modules.

## 🧩 Module Structure

To keep the codebase maintainable, modules are organized by their technical domain:

- `nixos/modules/core/`: Essential platform logic (Boot, Security, Users).
- `nixos/modules/storage/`: Filesystem and disk encryption (Disko).
- `nixos/profiles/`: Large-scale system shapes.

### Best Practice: Explicit Imports

We avoid "Nix magic" like global auto-discovery of modules. Every module used by a profile must be explicitly imported in its `default.nix`. This makes the system structure searchable and easy to audit.

## 📦 Package Selection Policy

We prioritize software that aligns with the following criteria:

- **Wayland Native**: Preferred over X11 whenever possible.
- **Minimal State**: Favor tools that keep configuration in the user's home (managed by dotfiles) rather than system-wide global state.
- **Explicit Unfree**: Unfree packages (like Chrome or Zoom) are permitted in `workstation-gui` but must be declared explicitly to maintain awareness of the system's licensing posture.
