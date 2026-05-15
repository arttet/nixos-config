# Workstation GUI

`workstation-gui` is the graphical V1 workstation target.

It imports the headless `workstation` core and adds workstation-scoped product
layers from `nixos/profiles/workstation/`.

## Build and Test

Build the graphical target without launching a GUI:

```sh
just workstation-gui build
```

Run CI-safe validation:

```sh
just workstation-gui test
```

The test evaluates the configuration and checks that:

- headless `workstation` remains GUI-free
- `workstation-gui` enables Hyprland
- greetd starts `tuigreet`
- `tuigreet` launches Hyprland
- desktop foundations are enabled
- notifications, clipboard, screenshots, audio, brightness, idle, and lock
  defaults are wired
- minimal MIME defaults are set
- no GNOME/KDE desktop is introduced
- Waybar, EWW, Nautilus, and Dolphin are not baseline packages

## Login Flow

The GUI target uses `greetd` with `tuigreet`.

`tuigreet` starts:

```txt
Hyprland
```

This keeps the login flow small and console-friendly. GDM and SDDM are not used.

## Default UX

The platform provides a minimal operational Hyprland fallback config. It is not
a personal desktop configuration.

Default workflow:

| Action | Binding |
| --- | --- |
| Terminal | `Super` + `Enter` |
| Launcher | `Super` + `D` |
| Browser | `Super` + `B` |
| GUI file manager | `Super` + `E` |
| Yazi file manager | `Super` + `Shift` + `E` |
| Close window | `Super` + `Q` |
| Reload Hyprland | `Super` + `Shift` + `R` |
| Lock | `Super` + `L` |
| Session menu | `Super` + `Shift` + `P` |
| Clipboard history | `Super` + `V` |
| Screenshot region | `Super` + `Print` |
| Screenshot full screen | `Print` |

Media keys handle volume, brightness, and player controls through `pamixer`,
`brightnessctl`, and `playerctl`.

## Runtime Components

- Notifications: `mako`
- Clipboard: `wl-clipboard` and `cliphist`
- Screenshots: `grim` and `slurp`
- Audio: PipeWire, WirePlumber, `pamixer`, and `playerctl`
- Idle and lock: `hypridle` and `hyprlock`
- Launcher: `rofi` with Wayland support from current nixpkgs
- File managers: Yazi first, Thunar as the GUI fallback

The full application and development tooling composition is documented in the
engineering guide: [Workstation Applications](../dev/system/applications.md).

Nautilus and Dolphin are intentionally avoided to prevent GNOME/KDE stack
creep. Waybar and EWW are intentionally not used because AGS/Astal is the
target desktop shell direction.

## MIME Defaults

The GUI target sets only minimal defaults:

- Brave for web links
- Thunar for directories
- Zathura for PDF files

Personal MIME preferences belong in user configuration later.

## Desktop Shell Boundary

AGS/Astal runtime packages may be installed when available, but this repository
does not implement AGS widgets, panels, bars, themes, or shell scripts.

`nix-config` is the platform/runtime/package layer. Personal desktop shell UX
belongs in a dotfiles repo or a dedicated desktop-shell repo.

## Runtime Checks

After installing and booting real hardware, validate the graphical session:

```sh
systemctl status greetd
echo $XDG_SESSION_TYPE
hyprctl version
hyprctl monitors
systemctl --user status xdg-desktop-portal-hyprland
pactl info
makoctl mode
cliphist list
```

Expected result:

- `greetd` is active
- `XDG_SESSION_TYPE` is `wayland`
- `hyprctl` can talk to the running compositor
- the Hyprland portal is available in the user session
- PipeWire/Pulse compatibility is available through `pactl`
- notifications and clipboard helpers are callable

## Boundary

`workstation-gui` does not change storage, boot, recovery, rollback, DNS,
firewall, privilege escalation, or upgrade policy. Those belong to the
headless foundation.

The GUI target does make one application-layer security compatibility decision:
the browser layer re-enables unprivileged user namespaces for Chromium/Electron
sandboxing. The headless `workstation` target keeps them disabled.
