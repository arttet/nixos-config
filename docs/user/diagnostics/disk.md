# 💾 Disk Space Diagnostics

Over time, logs, NixOS generations, and user data will consume disk space. Use these commands to identify where space is being used.

## 📊 General Disk Usage

To see an overview of all mounted filesystems:

```sh
df -h
```

Look for the usage percentage of `/` (root), `/nix`, and `/home`.

## 📁 Identifying Large Files and Folders

To find the largest directories where user data or logs typically accumulate:

```sh
doas du -sh /home /var /root /tmp | sort -hr | head -n 15
```

Avoid running `du -sh /*` as root; traversing the entire `/nix/store` or virtual filesystems like `/proc` is extremely slow and may hang your session.

If you prefer an interactive tool, you can temporarily install and use `ncdu` or `dust`:

```sh
nix shell nixpkgs#ncdu -c ncdu /
```

## 📦 Nix Store Usage

The `/nix/store` grows every time you install new software or rebuild your system. It holds all current and past versions of software.

To see how much space the Nix store is using:

```sh
du -sh /nix/store
```

To clean up old, unused NixOS generations and free up space, see the [Maintenance & Cleanup](../operations/cleanup) guide.

## 🌲 Btrfs Specific Diagnostics

Because this platform uses Btrfs, standard `df` commands might not show the full picture regarding compression and subvolumes.

To get an accurate view of Btrfs space usage across your subvolumes:

```sh
doas btrfs filesystem df /
```

To see raw device usage vs allocated space:

```sh
doas btrfs filesystem show /
```

## 📜 Journal (Logs) Size

systemd's journal can grow large if left unchecked. The platform includes tuning to bound the log size automatically, but you can check its current usage with:

```sh
journalctl --disk-usage
```

If you need to manually clear space taken by logs:

```sh
doas journalctl --vacuum-time=7d  # Keep only the last 7 days
doas journalctl --vacuum-size=1G  # Keep only 1GB of logs
```
