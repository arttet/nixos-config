# Recovery

The recovery model is rebuild-first.

If a VM is broken, delete its state and rebuild it. If a real machine is
broken in a future milestone, the platform should provide enough documented
state to recreate it rather than preserve unknown drift.

For future workstation installs, recovery starts from the official NixOS ISO:
boot the ISO in UEFI mode, review the disk state, mount or recreate the system
according to the documented storage model, and rebuild from the repository flake.

Any command that repartitions, formats, or encrypts a real disk is destructive.
Review the disk device with `lsblk` before running such commands.
