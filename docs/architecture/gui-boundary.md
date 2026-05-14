# GUI Boundary

GUI is a feature layer, not the operating system foundation.

The headless workstation foundation owns boot, storage, security, network,
rebuild, rollback, and recovery policy. GUI work must compose with those
policies instead of replacing them.

## GUI Must Not Change

GUI work must not change:

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

## GUI May Add

Future GUI work may add:

- Wayland
- Hyprland
- seat management
- polkit
- audio
- desktop portals
- fonts
- browser
- desktop UX

## USBGuard

USBGuard is intentionally deferred until the GUI/hardware phase has a real
device inventory. Enabling it without an allowlist can block keyboards, mice,
docks, recovery media, or future security tokens. It must be introduced with a
tested whitelist and a documented recovery path.

## Thunderbolt

Thunderbolt is disabled by default in the headless foundation because it can
expose a larger DMA-facing attack surface than ordinary USB. GUI work must not
quietly re-enable it. A host that needs a Thunderbolt dock, eGPU, or USB4
workflow must opt in through a local host layer after hardware review.

## Review Rule

Any GUI change that touches boot, storage, DNS, privilege escalation, recovery,
or VM runtime is an architecture change and must be reviewed outside the GUI
feature scope.
