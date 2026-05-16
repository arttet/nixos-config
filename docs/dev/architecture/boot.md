# Boot UX

The workstation uses Plymouth for a graphical early boot experience and a
cleaner LUKS passphrase prompt.

This is an early boot feature. It runs before the root filesystem is unlocked
and before Hyprland, greetd, AGS, portals, fonts, or user dotfiles are
available.

## Scope

The boot UX layer enables:

- Plymouth.
- The `splash` kernel parameter through the NixOS Plymouth module.
- Compatibility with the existing GRUB2, UEFI, and systemd initrd model.
- Manual LUKS passphrase unlock.

It intentionally does not enable:

- TPM unlock.
- YubiKey unlock.
- Secure Boot.
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

## Diagnostics

The NixOS Plymouth module adds `splash`. The platform does not force `quiet`.

This keeps boot diagnostics easier to access during the first real hardware
install. If a host-specific overlay later wants a quieter boot, it can add
`quiet` deliberately after hardware validation.

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

## Real Hardware Validation

After installation, validate:

```sh
cat /proc/cmdline
systemctl status systemd-cryptsetup@cryptroot.service
journalctl -b -p warning
```

Expected result:

- GRUB still shows NixOS generations.
- Plymouth appears during early boot.
- The LUKS passphrase prompt is visible.
- Entering the passphrase unlocks the root filesystem.
- The system continues to the normal login flow.
