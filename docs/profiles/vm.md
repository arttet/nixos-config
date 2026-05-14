# VM Profile

The `vm` profile is the local QEMU mirror of `workstation`.

It imports `workstation`, then adds VM-only behavior:

- QEMU guest support.
- Serial console settings.
- Headless VM graphics settings.
- QEMU memory, disk, port forwarding, and runtime assumptions.
- The temporary public test user used by local VM validation.

VM state is disposable. The profile exists to validate workstation changes
before applying them to future real hardware.

The VM keeps QEMU storage settings in the VM target. It does not apply the
workstation storage layout during normal runtime commands.

The VM disables the real-hardware `platform.tuning` layer. Boot, power, ZRAM,
earlyoom, fstrim, and network tuning are validated through workstation
evaluation, not by making the local QEMU workflow heavier.

The VM may enable SSH for local validation. The workstation profile disables SSH
by default.

Runtime commands are documented in [Runtime / VM](../runtime/vm.md).
