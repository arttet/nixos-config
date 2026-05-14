# Layering

The platform uses layers to avoid mixing public infrastructure with private
machine state.

Public NixOS modules define reusable behavior. Profiles define reusable system
shapes. Host targets compose profiles. Local overlays provide identity.
Generated build output remains disposable.

The `workstation` profile owns shared console development behavior for future
real hardware. The `vm` profile imports `workstation` and keeps QEMU-only
settings out of the hardware profile.

This keeps the repository useful without turning it into a record of one
machine's accidental state.
