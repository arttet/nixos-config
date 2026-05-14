# Targets

The active runtime target is `vm`.

The active real-hardware profile target is `workstation`.

`workstation` is the reusable personal development environment for future real
hardware. It owns the UEFI/systemd-boot model and the opt-in storage
installation path.

`vm` imports `workstation` and adds only local QEMU runtime settings. VM state is
disposable and normal VM validation does not apply destructive disk layout
operations.

Future targets should be added deliberately. A target becomes active only when
its architecture, documentation, security boundary, and validation path are
clear.
