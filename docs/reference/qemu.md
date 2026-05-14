# QEMU

QEMU is the runtime for the local VM.

The `vm` target is headless and disposable. It imports `workstation` and exists
to validate NixOS changes before real hardware is involved.

The local VM uses QEMU user-mode networking. ICMP tools such as `ping` may fail
even when TCP networking works. Use `curl` from the VM or SSH forwarding from
the host for practical network validation.
