# Kernel Policy

The workstation uses:

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

The actual kernel version comes from the pinned `nixpkgs` revision in
`flake.lock`. Updating the kernel is therefore a deliberate flake update, not an
implicit host mutation.

The project does not use Zen, XanMod, or a custom kernel. Runtime behavior is
tuned through the conservative `platform.tuning` module instead of switching to
a benchmark-oriented kernel.

Kernel upgrade policy:

- Update `flake.lock` deliberately.
- Build and test `vm`.
- Build `workstation`.
- Apply to real hardware only after reviewing the change.

Rollback uses normal NixOS generations. If a new kernel does not boot, select an
older generation from GRUB.
