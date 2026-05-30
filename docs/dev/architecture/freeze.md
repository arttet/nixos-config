# Workstation Freeze

`workstation-gui` is the V1 workstation freeze candidate. It is a product
composition built on top of the headless `workstation` foundation, not a
replacement for it.

The freeze is about boundaries and repeatability. The platform should be
installable, auditable, recoverable, and useful as a daily workstation without
turning the repository into a dotfiles or desktop theme repository.

## Frozen Architecture

The V1 workstation composition freezes these contracts:

- `workstation` remains the secure headless base.
- `workstation-gui` is the graphical workstation product target.
- `vm` remains a disposable local validation target.
- GUI software lives under `nixos/profiles/workstation/`.
- Boot, storage, security, DNS, firewall, logging, GC, and upgrade policy are
  core platform responsibilities.
- Plymouth owns early boot UX and the graphical LUKS passphrase prompt.
- Personal UX, editor settings, shell aliases, AGS widgets, browser profiles,
  themes, and wallpapers are outside this repository.

GUI layers must not change the storage layout, boot model, recovery model,
rollback model, core security policy, DNS policy, or upgrade policy.

## Layer Ownership

Each workstation layer owns one responsibility:

| Layer                    | Responsibility                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------ |
| `base.nix`               | Headless workstation core and platform policy                                        |
| `shell/`                 | CLI and TUI tools only                                                               |
| `gui/core.nix`           | Login/session foundation, DBus, polkit, PipeWire, portals, Thunar, Rofi, MIME        |
| `gui/hyprland.nix`       | Hyprland compositor ecosystem and minimal runtime defaults                           |
| `gui/wayland-tools.nix`  | Wayland-native clipboard, screenshots, notifications, network applet, media controls |
| `gui/power.nix`          | Desktop-facing power information service                                             |
| `gui/desktop-shell.nix`  | AGS/Astal runtime support only                                                       |
| `gui/fonts.nix`          | Font packages and fontconfig defaults                                                |
| `apps/terminals.nix`     | Terminal runtime packages                                                            |
| `apps/editors.nix`       | Editor runtime packages                                                              |
| `apps/browsers.nix`      | Browser packages and browser MIME defaults                                           |
| `development/`           | Language tooling, split by language                                                  |
| `apps/containers.nix`    | Docker workstation runtime                                                           |
| `apps/communication.nix` | Communication applications                                                           |
| `apps/productivity.nix`  | Documents, notes, office, and PDF workflow                                           |
| `apps/security.nix`      | Workstation security and password applications                                       |
| `apps/internet.nix`      | Internet/network clients                                                             |
| `apps/media.nix`         | Minimal media applications                                                           |

Package ownership should stay in the layer that describes the package's primary
purpose. Cross-layer duplication is avoided unless the headless base needs a
small operational tool before GUI is installed. Helix is the current intentional
exception: it exists in the headless base as a recovery-friendly editor and is
also part of the editor baseline inherited by `workstation-gui`.

## Dependency Audit

The V1 composition intentionally includes some large application families:

- Firefox/Chromium-derived browsers: Zen Browser, Brave, Google Chrome, and Tor Browser.
- Electron-style applications: VS Code, Obsidian, Zoom, and communication tools.
- Docker and container tooling.
- Cloud and vendor account clients.
- Selected security tooling.
- VLC as the minimal video player.

These dependencies are accepted because `workstation-gui` is a real daily-use
workstation target. They must remain workstation-scoped and must not leak into
`workstation`, `vm`, or future service profiles.

GNOME and KDE desktop environments are not baseline dependencies. Individual
GTK or Qt libraries may appear through applications, portals, Thunar, or GUI
toolkits; that does not make the system a GNOME or KDE desktop. XWayland is
enabled only as an explicit compatibility exception for applications that still
need it. It is not an X11 desktop/session.

## Runtime Model

The graphical runtime is intentionally minimal:

- `greetd` and `tuigreet` provide the login flow.
- Hyprland is the Wayland compositor.
- Hardware graphics support is enabled only in the GUI target.
- PipeWire and WirePlumber provide audio runtime.
- UPower provides desktop-facing power information.
- XDG portals provide desktop integration.
- Mako provides notifications.
- NetworkManager applet tooling provides graphical network editing.
- `wl-clipboard` and `cliphist` provide clipboard workflow.
- `grim` and `slurp` provide screenshots.
- `hypridle` and `hyprlock` provide idle and lock support.
- Thunar is the minimal GUI file manager.
- Yazi remains the terminal-first file manager.

The runtime baseline is operational, not personalized. Personal keymaps,
advanced Hyprland configuration, AGS widgets, panels, launchers, themes, and
wallpapers belong in a dotfiles or desktop-shell repository.

## Browser Strategy

Browser categories are explicit:

- Zen Browser is the preferred target and is integrated through a pinned flake input.
- Brave is the stable fallback.
- Google Chrome is the compatibility browser.
- Tor Browser is the privacy browser.
- Yandex Browser is deferred and not part of the V1 baseline.

The fallback browser path is mandatory. The workstation must remain usable even
if an external or optional browser integration is unavailable in the pinned
package set.

## Editors And Development

Editor packages are installed without personal configuration:

- Neovim
- Helix
- VS Code
- Zed
- Vim

Language tooling is split by language so future changes can be reviewed in a
small scope:

- C/C++
- Rust
- Go
- JavaScript/TypeScript
- Python

Global project-specific tooling is intentionally avoided. For example, ESLint
belongs to JavaScript projects, not the operating system baseline.

## Security Revalidation

The V1 freeze keeps the security baseline intact:

- firewall enabled by default
- SSH disabled on `workstation`
- root login disabled
- `doas` used for explicit privilege escalation
- no passwordless escalation
- explicit DNS policy through systemd-resolved
- persistent bounded journald
- manual upgrades only
- no secrets, real usernames, hostnames, keys, or hardware config in git

GUI layers must not weaken these rules.

## CI Contract

CI validates that the platform builds and that policy checks still hold:

- flake checks and formatting
- documentation build
- VM build and validation
- headless workstation build and policy tests
- graphical workstation build and policy tests

CI is intentionally headless. It does not launch Hyprland, require GPU
acceleration, test real DNS performance, validate battery behavior, partition
disks, or prove real hardware installation success.

Heavy system closures are built by dedicated jobs rather than through
`nix flake check`. This keeps validation deterministic and avoids building the
large graphical closure twice on GitHub's limited ephemeral runner disk.
Nix jobs use Magic Nix Cache, and the graphical workstation job frees
preinstalled GitHub runner toolchains before building the full desktop closure.

## Freeze Decision

The current repository is a V1 workstation freeze candidate when the following
commands pass in the target environment:

```sh
just check
just docs build
just workstation build
just workstation test
just workstation-gui build
just workstation-gui test
```

Useful runtime inspection after installation:

```sh
nix path-info -Sh .#nixosConfigurations.workstation-gui.config.system.build.toplevel
systemctl status greetd
systemctl --user status pipewire
journalctl -b
hyprctl version
docker version
```
