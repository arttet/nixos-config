# GUI Roadmap

The headless workstation foundation remains intentionally headless. GUI is introduced as a separate V1 product composition through `workstation-gui`. It must not be mixed into the headless `workstation` baseline.

## Workstation Layers

The V1 workstation is a product composition, not a flat package list. The GUI/product target is `workstation-gui` and is built by layering workstation-scoped modules from `nixos/profiles/workstation/`:

- **Desktop Foundation:** Seat management, polkit, portals, audio.
- **Hyprland Ecosystem:** Hyprland, hyprpaper, hypridle, hyprlock, hyprpicker, xdg-desktop-portal-hyprland.
- **Desktop Shell:** AGS/Astal framework. Waybar and EWW are intentionally avoided.
- **Browsers:** Zen Browser (target), Brave (fallback), Google Chrome (compatibility), Tor Browser.
- **Fonts:** Iosevka Term Nerd Font (monospace), Inter (UI), Noto Sans/Serif/Emoji.
- **Development Language Stacks:** C/C++, Rust, Go, JS/TS, Python.
- **Applications:** Yazi (files), LibreOffice (docs), VLC (media), Telegram/Zoom (comm).

The package contract is finalized in
[Workstation Applications](../system/applications.md).

### Unfree Policy

The V1 workstation product allows a narrow set of unfree packages (Brave, Chrome, Obsidian, VeraCrypt, VS Code, Zoom) because the desktop product targets real daily use.

## Hyprland & Wayland

Hyprland is the V1 workstation Wayland compositor layer. The workstation is **Wayland-first**. It does not enable an X11 desktop environment or session. XWayland is kept only as an explicit compatibility exception.

The browser layer enables unprivileged user namespaces for Chromium/Electron
sandboxing in `workstation-gui`. The headless `workstation` target keeps user
namespaces disabled.

## Login Flow

`workstation-gui` uses `greetd` with `tuigreet`. The login command starts
Hyprland directly. GDM, SDDM, GNOME, and KDE are not part of the baseline.

## Runtime Polish

The GUI target provides operational defaults only:

- `mako` for Wayland-native notifications
- `wl-clipboard` and `cliphist` for clipboard history
- `grim` and `slurp` for Wayland screenshots
- PipeWire and WirePlumber for audio
- `pamixer`, `playerctl`, and `brightnessctl` for media keys
- `hypridle` and `hyprlock` for idle and lock behavior
- Yazi as the terminal-first file manager
- Thunar as the lightweight GUI file manager fallback

Personal Hyprland configuration, AGS widgets, panels, themes, wallpapers, and
desktop shell code remain outside this repository.

## Desktop Shell

AGS/Astal remains the target desktop shell direction. The current activation
stage does not block Hyprland boot on a complete shell implementation. Waybar
and EWW remain intentionally excluded.

## GUI Boundary

GUI is a feature layer, not the operating system foundation. The headless workstation foundation owns boot, storage, security, network, rebuild, rollback, and recovery policy. GUI work must compose with those policies instead of replacing them.

### GUI Must Not Change
- storage layout
- boot architecture
- core security policy
- DNS policy
- firewall baseline
- Thunderbolt default policy
- disk encryption model
- rollback model
- recovery model
- manual upgrade strategy
- VM disposable runtime model
- USB device authorization policy

### USBGuard
USBGuard is intentionally deferred until the GUI/hardware phase has a real device inventory. Enabling it without an allowlist can block keyboards, mice, docks, recovery media, or future security tokens.

### Thunderbolt
Thunderbolt is disabled by default in the headless foundation. A host that needs it must opt in through a local host layer after hardware review.

## Review Rule
Any GUI change that touches boot, storage, DNS, privilege escalation, recovery, or VM runtime is an architecture change and must be reviewed outside the GUI feature scope.

## Pre-GUI Freeze
The headless workstation foundation was frozen before GUI work began. This means the operating system foundation is treated as a platform contract. GUI work is layered on top of it rather than changing the core storage, boot, security, network, recovery, or upgrade model.
