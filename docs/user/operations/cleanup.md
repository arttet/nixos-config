# 🧹 Maintenance & Cleanup

Over time, your NixOS system will accumulate old configurations and packages. By default, the workstation takes care of itself by running a **weekly automatic garbage collection** that deletes data older than 14 days.

If you ever need to manually free up disk space or inspect your system's history, use the commands below.

## 🔍 Inspecting Your System

Before deleting anything, you might want to see what is currently keeping files pinned in the system.

To see all active "roots" (configurations that tell Nix not to delete a package):

```sh
nix-store --gc --print-roots
```

To view a detailed history of your system generations (the entries you see in the GRUB boot menu):

```sh
nix profile history --profile /nix/var/nix/profiles/system
```

## 🗑️ Manual Cleanup

If you are running low on disk space, you can manually trigger the garbage collector. 

**Best Practice:** Always keep recent generations around just in case you need to roll back. The following command safely deletes data older than 14 days:

```sh
doas nix-collect-garbage --delete-older-than 14d
```

*(Note: Avoid deleting generations too aggressively! If you just made major changes to graphics or networking, keep at least one known-good generation until you are sure the new one is completely stable).*
