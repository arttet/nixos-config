# Runtime

Runtime docs describe how to build, start, stop, inspect, and test local NixOS
targets.

Installation prepares the host environment. Runtime commands operate on built
systems.

## Active Runtime

The repository currently keeps one active runtime target:

| Target | Purpose | State |
| --- | --- | --- |
| `vm` | Local QEMU mirror of `workstation` for runtime validation. | Disposable |

Continue with [VM](vm.md).
