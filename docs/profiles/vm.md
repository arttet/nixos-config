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

Runtime commands are documented in [Runtime / VM](../runtime/vm.md).
