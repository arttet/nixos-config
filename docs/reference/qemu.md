# QEMU

QEMU is the runtime for the local guest VM.

The guest target is headless and disposable. It exists to validate NixOS changes
before real hardware is involved.

The local VM uses QEMU user-mode networking. ICMP tools such as `ping` may fail
even when TCP networking works. Use `curl` from the guest or SSH forwarding from
the host for practical network validation.
