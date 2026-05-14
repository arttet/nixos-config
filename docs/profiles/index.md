# Profiles

Profiles describe supported runtime shapes. A profile is not a private machine
identity. Real users, hostnames, keys, hardware state, and secrets remain local.

| Profile | Purpose | State model | GUI | Status |
| --- | --- | --- | --- | --- |
| `workstation` | Personal development environment for future real hardware. | Persistent | No | Active build target |
| `vm` | Local QEMU mirror of `workstation` for runtime validation. | Disposable | No | Active runtime target |

The workstation remains console-only. Laptop-specific, desktop, and VPN profiles
remain out of scope. Disk encryption is part of the workstation storage layout,
while TPM, YubiKey, and Secure Boot unlock paths remain deferred.

Continue with [Workstation](workstation.md) and [VM](vm.md).
