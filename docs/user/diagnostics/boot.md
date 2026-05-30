# ⏱️ Boot Time Diagnostics

Use this page when the installed workstation feels slow, especially during boot. Run these commands on the installed machine.

## 📊 Analyzing Total Boot Time

Start with the total boot summary:

```sh
systemd-analyze
```

**Expected result:** systemd prints firmware, bootloader, kernel, initrd, and userspace timing.
_(Note: Manual LUKS passphrase entry pauses the boot process and will inflate the total time. This is not an OS tuning problem and should be judged separately)._

## 🐢 Finding Slow Services

Find the slowest individual units:

```sh
systemd-analyze blame
```

**Expected result:** The slowest systemd units are listed first. Long-running services become visible without guessing.

## ⛓️ Inspecting the Critical Path

A service might take a long time to start, but if it runs in parallel with others, it might not actually delay the boot. Inspect the critical path to find what actually blocked the system from reaching the login prompt:

```sh
systemd-analyze critical-chain
```

**Expected result:** The dependency chain that delayed the boot is visible.

## ⚠️ Checking Boot Warnings

Check warnings specifically from the current boot:

```sh
journalctl -b -p warning
```

**Expected result:** Current boot warnings are listed. Repeated hardware, filesystem, network, or graphics warnings can explain slow boot or session startup.

## 🩺 Common Quick Checks

| Symptom               | Command                           | What to look for                                                             |
| --------------------- | --------------------------------- | ---------------------------------------------------------------------------- |
| Network delays        | `systemctl status NetworkManager` | NetworkManager should be active; boot should not wait for online networking. |
| Slow graphical login  | `systemctl status greetd`         | `greetd` should be active and not repeatedly restarting.                     |
| DNS issues after boot | `resolvectl status`               | DNS servers and DNS-over-TLS state should be visible.                        |
| Time sync issues      | `timedatectl status`              | System clock and NTP state should be sane.                                   |

Do not tune the system blindly based on these commands. Collect the output first, then change the smallest specific setting that explains the measured problem in your NixOS configuration.
