# Profiles

Profiles describe supported runtime shapes. A profile is not a private machine
identity. Real users, hostnames, keys, hardware state, and secrets remain local.

| Profile | Purpose | State model | GUI | Status |
| --- | --- | --- | --- | --- |
| `workstation` | Personal development environment for future real hardware. | Persistent | No | Active build target |
| `vm` | Local QEMU mirror of `workstation` for runtime validation. | Disposable | No | Active runtime target |

Stage 003 keeps the workstation console-only. Laptop-specific, desktop, VPN, and
encrypted installation profiles remain out of scope.

Continue with [Workstation](workstation.md) and [VM](vm.md).
