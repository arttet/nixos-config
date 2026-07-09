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

## 📊 Inspecting Store Usage

If the automatic cleanup above still leaves `/nix/store` larger than
expected, it helps to see _what_ is retaining the space before deleting
anything. `just top` ranks real store paths by their actual size:

```sh
just top
```

Two common causes of a bloated store to look out for in the results:

- **Duplicated toolchains from mixing nixpkgs channels.** If any packages are
  pinned to `nixpkgs-unstable` while the rest of the system uses the stable
  channel, you'll often see two separate copies of `glibc`/`gcc` and their
  dependents — nothing is shared between the two channels' closures.
- **Retained build-time dependencies.** `nix.settings.keep-outputs` and
  `keep-derivations` (see `docs/dev/architecture/tuning.md`) intentionally
  keep build dependencies around for faster rebuilds, at the cost of store
  size.

Before reaching for `just gc`, try `just optimise` first — it hard-links
identical files across store paths and can reclaim space with no risk of
losing anything.

## 🗑️ Manual Cleanup

If you are running low on disk space, you can manually trigger the garbage collector.

**Best Practice:** Always keep recent generations around just in case you need to roll back. The following command safely deletes data older than 14 days:

```sh
doas nix-collect-garbage --delete-older-than 14d
```

_(Note: Avoid deleting generations too aggressively! If you just made major changes to graphics or networking, keep at least one known-good generation until you are sure the new one is completely stable)._
