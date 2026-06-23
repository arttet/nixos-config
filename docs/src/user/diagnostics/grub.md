# ⚙️ GRUB & Early Boot Diagnostics

This page explains how to troubleshoot the system before the desktop or full login session loads, primarily by interacting with the GRUB bootloader.

## 🚪 Accessing the GRUB Menu

When you power on your machine, the GRUB menu should appear. If it does not appear, ensure you are booting in UEFI mode and that your boot order prioritizes the NixOS partition.

## 🛠️ Handling Early Boot Failures

If your system freezes during the boot splash screen, fails to prompt for the LUKS password, or hangs during early systemd initialization, you can modify the boot parameters temporarily from GRUB to diagnose the issue.

### 1. 🖼️ Removing the Graphical Splash

The graphical Plymouth splash screen hides underlying systemd messages. Removing it allows you to see exactly where the boot process is hanging.

1. In the GRUB menu, select the generation you want to boot.
2. Press `e` to edit the boot parameters.
3. Find the line that starts with `linux` (this contains your kernel parameters).
4. Remove the `splash` keyword from that line.
5. Press `Ctrl+X` or `F10` to boot.

You will now see the raw kernel and systemd logs scrolling during boot.

### 2. 🖥️ Bypassing Graphics Drivers (Nomodeset)

If the system hangs with a black screen immediately after selecting a GRUB entry, it is likely a graphics driver issue (e.g., NVIDIA or AMD drivers failing to initialize).

1. In the GRUB menu, press `e` on your generation.
2. Find the `linux` line.
3. Add `nomodeset` to the end of the line.
4. Press `Ctrl+X` or `F10` to boot.

This forces the kernel to use basic fallback drivers, allowing you to reach a TUI console where you can inspect logs and rebuild the system.

### 3. 🚨 Booting into Emergency Mode

If the root filesystem is corrupted or a critical service prevents the system from reaching the `multi-user` target, you can force the system to drop into a minimal shell.

1. In the GRUB menu, press `e` on your generation.
2. Find the `linux` line.
3. Add `systemd.unit=rescue.target` to the end of the line.
4. Press `Ctrl+X` or `F10` to boot.

This will drop you into a root shell before most services start.

## 💾 Persistent Changes

Changes made in the GRUB editor (`e`) are **temporary** and apply only to that specific boot.

To permanently change kernel parameters, you must edit your local NixOS configuration or overlay and rebuild the system. For example, to permanently disable the graphical boot splash, set `platform.bootUx.enable = false;` in your overlay and run `nixos-rebuild switch`.
