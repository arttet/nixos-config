# Boot UX

The workstation uses Plymouth for a graphical early boot experience and a
cleaner LUKS passphrase prompt.

This is an early boot feature. It runs before the root filesystem is unlocked
and before SDDM, Hyprland, AGS, portals, fonts, or user dotfiles are
available.

## Scope

The boot UX layer enables:

- Plymouth.
- The `splash` kernel parameter through the NixOS Plymouth module.
- Compatibility with the existing GRUB2, UEFI, and systemd initrd model.
- Manual LUKS passphrase unlock.
- Baseline Secure Boot tooling through `sbctl`, owned by the security layer.

It intentionally does not enable:

- TPM unlock.
- YubiKey unlock.
- kernel lockdown.
- automatic recovery behavior.

Those features need separate design and recovery documentation.

## Why Plymouth

Plymouth provides a graphical prompt for encrypted root unlock while keeping the
underlying model simple:

- root is still unlocked by a passphrase;
- GRUB generations remain available;
- systemd initrd remains the initrd model;
- recovery through the official NixOS ISO remains unchanged.

GRUB keeps ten boot generations for rollback room.

## Diagnostics

The NixOS Plymouth module adds `splash`. The platform does not force `quiet`.

This keeps boot diagnostics easier to access during the first real hardware
install. If a host-specific overlay later wants a quieter boot, it can add
`quiet` deliberately after hardware validation.

The graphical `desktop` target enables the quiet path by default after the
baseline workstation layer is composed. It hides the normal boot stream behind
Plymouth while preserving diagnostics in the persistent systemd journal. The
headless `workstation` target remains verbose enough for install and recovery
diagnostics.

`platform.bootUx.earlyGraphicsDrivers` defaults to `[ "amdgpu" ]` so Plymouth
can render in DRM mode immediately after the boot loader on AMD machines. Hosts
with Intel iGPU or Nouveau can override the list in their local overlay:
`platform.bootUx.earlyGraphicsDrivers = [ "i915" ];`. The platform avoids
loading multiple DRM drivers at once because that can make the initrd too large
for the fixed `/boot` partition.

If Plymouth causes trouble during boot:

1. Open the GRUB editor for the selected generation.
2. Remove `splash` from the kernel command line.
3. Boot once with the edited command line.
4. Rebuild with `platform.bootUx.enable = false;` from a local override if
   needed.

## CI Boundary

CI can validate that:

- `platform.bootUx.enable` is enabled for `workstation`;
- Plymouth is enabled;
- `splash` is present;
- `quiet` is not forced by the platform baseline;
- `vm` keeps boot UX disabled.

CI cannot validate that:

- the splash is visible on a real monitor;
- the LUKS prompt renders correctly on specific firmware/GPU combinations;
- keyboard input works before root unlock on every machine;
- HiDPI scaling is correct;
- no black screen appears before decrypt.

Those checks require real hardware.

## Handoff to the display manager

The graphical target uses the NixOS SDDM integration instead of a custom
compositor-based greeter:

1. Plymouth owns the early boot display and encrypted-root prompt.
2. The standard NixOS display-manager ordering stops Plymouth before SDDM takes
   over the display. There are no custom `plymouth quit` calls in the greeter.
3. SDDM starts its Qt6 greeter on the KWin Wayland compositor and loads
   `sddm-astronaut-theme`.
4. SDDM preselects `hyprland-uwsm`. A successful login starts the existing UWSM
   session, whose desktop entry executes `/run/current-system/sw/bin/start-hyprland`.

The graphical target reserves `tty1` for `kmscon` and starts it before SDDM.
This is necessary because the kernel virtual console only supports bitmap PSF
fonts, while `kmscon` can render the configured `IosevkaTerm Nerd Font`. SDDM
0.21 allocates the next free virtual terminal, so its Wayland greeter starts on
`tty2` while `Ctrl+Alt+F1` remains a usable text login console.

The platform keeps `services.xserver.enable = false`. This makes the SDDM
greeter Wayland-only while retaining XWayland inside the user Hyprland session
for application compatibility.

The `platform.greetd` module remains available only as a disabled,
mutually-exclusive `tuigreet` fallback. It is not part of the normal desktop
boot path.

## Real Hardware Validation

After installation, validate:

```sh
cat /proc/cmdline
systemctl status systemd-cryptsetup@cryptroot.service
journalctl -b -p warning
systemctl show getty.target -p Wants
systemctl status kmsconvt@tty1.service display-manager.service
loginctl list-sessions
```

Expected result:

- GRUB still shows NixOS generations.
- Plymouth appears during early boot.
- The LUKS passphrase prompt is visible.
- Entering the passphrase unlocks the root filesystem.
- The system continues to the normal login flow.
- `getty.target` wants `kmsconvt@tty1.service`.
- `kmsconvt@tty1.service` is active and `Ctrl+Alt+F1` opens a login prompt with
  Nerd Font glyph support.
- The SDDM greeter and the graphical user session use a VT other than `tty1`.
