# Rollback

Rollback uses NixOS generations.

For a workstation boot failure, use GRUB to select an older generation. This is
the first recovery path for kernel, bootloader, or system closure regressions.

After booting a known-good generation, inspect the failed change and rebuild from
the repository:

```sh
sudo nixos-rebuild switch --flake .#workstation
```

Disk layout and encryption changes are different from normal system rebuilds.
Do not rerun destructive disk commands during rollback unless the recovery plan
explicitly requires repartitioning or formatting.
