# Workstation Applications

`workstation-gui` is the V1 workstation product target. It keeps the headless
`workstation` foundation intact and adds user-facing software through
workstation-scoped layers under `nixos/profiles/workstation/`.

This repository installs runtime packages and system integration only. It does
not own dotfiles, editor configuration, shell aliases, browser profiles, AGS
widgets, themes, or personal desktop UX.

## Browser Model

Browser categories are explicit:

- Preferred target: Zen Browser
- Stable fallback: Brave
- Compatibility browser: Google Chrome
- Privacy browser: Tor Browser
- Optional/deferred: Yandex Browser

Zen Browser is integrated through the pinned `zen-browser` flake input and is
the default browser for MIME handling. Brave, Google Chrome, and Tor Browser
provide stable fallback, compatibility, and privacy paths. Yandex Browser is
deferred and is not installed by the V1 baseline.

## Terminals

- Primary: Ghostty
- Stable fallback: Alacritty
- Additional fallback: WezTerm

Terminal configuration belongs in dotfiles. The platform only installs terminal
runtimes.

## Editors

Baseline editors:

- Neovim
- Helix
- VS Code
- Zed
- Vim

Editor settings, plugins, language-server preferences, and keymaps belong
outside this repository.

## Shell Tools

The shell tooling layer provides a clean CLI baseline:

- zsh
- nushell
- starship
- tmux
- fastfetch
- fzf
- ripgrep
- fd
- bat
- eza
- zoxide
- yazi
- lazygit
- btop

No private aliases, history policy, prompt themes, shell functions, or dotfiles
are stored here.

## Development Tooling

Language tooling is split by language:

- C/C++: cmake, ninja, llvm/clang, lldb, gdb, pkg-config
- Rust: rustup, rust-analyzer
- Go: go, gopls, delve, golangci-lint
- JavaScript/TypeScript: nodejs, bun, pnpm, typescript
- Python: python3, uv, ruff, pyright

Project-specific tooling remains project-specific. ESLint is intentionally not
an OS baseline.

## Containers

Docker is the initial workstation container runtime because it has the broadest
compatibility with common developer workflows. Podman is deferred for later
evaluation.

Local user access to Docker should be granted through local user/host policy;
the public repository must not commit a real username.

## Communication

Baseline:

- Telegram Desktop
- Zoom
- Proton Mail Desktop

Teams is not part of the V1 baseline.

## Productivity

Baseline:

- Obsidian
- LibreOffice
- Zathura

LibreOffice Draw is the initial PDF editing path. A dedicated PDF editor may be
selected later.

## Security Tools

Baseline:

- GnuPG
- KeePassXC
- Proton Pass
- VeraCrypt

YubiKey tools are deferred until hardware-backed unlock/authentication receives
its own stage. Security tools are workstation-scoped and are not part of the
headless base or VM runtime.

## Internet

Baseline:

- Cloudflare WARP
- Transmission
- Yandex Disk

These packages are workstation-scoped internet/network clients. Backup
automation and rclone-based workflows are deferred until backup/sync policy
receives its own stage.

## Media

The media layer is intentionally small:

- imv image viewer
- VLC media player

## Network And Power Runtime

The GUI target includes NetworkManager applet tooling so the user has a normal
graphical path for inspecting and editing connections. NetworkManager remains
the network backend.

UPower is enabled through a dedicated power layer. It provides a desktop-facing
power and battery information service without moving power policy into the
Hyprland or desktop foundation layers.

It is not a full creative/media-production stack.

## Fonts

Baseline:

- Iosevka Term Nerd Font
- Inter
- Noto Sans
- Noto Serif
- Noto Color Emoji

JetBrains Mono is not the default. Ioskeley Mono remains optional/deferred
unless it becomes available through a clean package path.

## Unfree Policy

The workstation product permits selected unfree packages because it is a real
daily-use workstation target.

Current unfree candidates:

- Google Chrome
- Zoom
- VS Code
- Obsidian
- VeraCrypt
- Cloudflare WARP
- Proton Mail Desktop
- Proton Pass
- Yandex Disk

This policy is scoped to `workstation-gui`. It must not become a global package
policy for every future target.
