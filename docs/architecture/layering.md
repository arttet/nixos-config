# Layering

The platform uses layers to avoid mixing public infrastructure with private
machine state.

Public NixOS modules define reusable behavior. Host targets compose profiles.
Local overlays provide identity. Generated build output remains disposable.

This keeps the repository useful without turning it into a record of one
machine's accidental state.
