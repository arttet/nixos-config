# Layering

The platform uses layers to avoid mixing public infrastructure with private
machine state.

Public NixOS modules define reusable behavior. Profiles define reusable system
shapes. Host targets compose profiles. Local overlays provide identity.
Generated build output remains disposable.

The `workstation` profile owns shared console development behavior for future
real hardware. Storage modules provide the opt-in installation layout for that
hardware profile. The security, network, and tuning modules provide
conservative real-hardware defaults through `platform.security`,
`platform.network`, and `platform.tuning`. The `vm` profile imports
`workstation` and keeps QEMU-only settings out of the hardware profile.

Destructive disk operations belong to the installation path, not to default
build, CI, or VM runtime workflows.

Local overlays and generated hardware configuration form the private hardware
layer. They are imported from local paths and must not be committed.

This keeps the repository useful without turning it into a record of one
machine's accidental state.
