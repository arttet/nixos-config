# 💿 Install Workstation

This is the clean-hardware installation runbook for the workstation.

The flow is destructive: the selected disk is repartitioned and formatted. The
installer asks for the target disk and requires an exact disk-path confirmation
before it applies the storage layout.

## ⚠️ Before Booting the Installer

Prepare the machine before starting this guide:

- Back up important data from the target disk.
- Download the official [Minimal NixOS ISO](https://nixos.org/download).
- Prepare a bootable USB drive. [Ventoy](https://www.ventoy.net/) is recommended for this.
- Disable Secure Boot in firmware settings.
- Make sure the machine can reach the network from the live ISO.
- Identify which physical disk will be erased.

This guide assumes those preparation steps are done by the user. The detailed
procedure starts from the booted NixOS live environment.

## 🌐 Boot and Network

Boot the official Minimal NixOS ISO in UEFI mode.

If the machine needs Wi-Fi, connect with NetworkManager:

```sh
nmcli device wifi connect SSID_NAME hidden yes --ask
```

Verify network access:

```sh
ping -c 3 nixos.org
```

Expected result:

- DNS resolves `nixos.org`.
- The command receives replies.

## ⚡ Start the Installer

Run the installer from the live environment:

```sh
curl -sL github.com/arttet/nixos-config/raw/main/install.sh | bash
```

The entrypoint clones or updates the repository under `/tmp/nixos-config`, then
starts the Nushell installer:

```sh
nu scripts/install/bootstrap.nu --apply
```

## 💬 Interactive Setup Wizard

The wizard asks for:

| Prompt | Meaning |
| --- | --- |
| Install id | Local install workspace name under `/tmp/nix-config-install/` |
| Target | System variant to install; keep `default` for the normal workstation |
| Username | Initial local user |
| User password | Initial login password for that user |
| Hostname | Machine hostname |
| Timezone | NixOS timezone, such as `Etc/UTC` |
| Disk | Target disk device to repartition and format |
| Action | `dry-run` or `apply` |

Keep the target as `default` for a normal workstation install. The flake default
points to the graphical workstation. Do not switch to another target unless you
are deliberately testing a development workflow.

Disk discovery prints available disks from `lsblk` and matching
`/dev/disk/by-id/` entries when available. Review the disk carefully. The
installer will ask you to type the exact selected disk path before formatting.

## ⚙️ What Apply Does

When `apply` is selected and disk confirmation succeeds, the installer:

1. Generates a temporary disko config at `/tmp/workstation-disko.nix`.
2. Runs `disko` to partition and format the disk.
3. Runs `nixos-generate-config --root /mnt`.
4. Writes the local user overlay to `/mnt/root/.nix-config-local/user.nix`.
5. Writes the local password hash file to
   `/mnt/root/.nix-config-local/user.passwd`.
6. Installs the default workstation target with
   `nixos-install --impure --no-root-passwd`.

The generated local overlay contains the hostname, timezone, initial user, user
shell, `wheel` membership, and a reference to the password hash file. The
password hash itself is stored separately in `user.passwd`, not inside the Nix
overlay.

Both files are local machine state and must not be committed to the repository.

After the installer completes, reboot:

```sh
reboot
```

## ✅ First Boot Checks

After booting the installed workstation, log in as the local user created by the
installer.

Run each check separately:

| Check | Command | Expected result |
| --- | --- | --- |
| UEFI boot | `test -d /sys/firmware/efi` | Command exits successfully |
| Mounted filesystems | `findmnt` | Installed filesystems are visible |
| Swap | `swapon --show` | Swap is available |
| Network | `systemctl status NetworkManager` | NetworkManager is active |
| Login manager | `systemctl status greetd` | `greetd` is active |
| Session type | `echo $XDG_SESSION_TYPE` | Output is `wayland` |
| Hyprland version | `hyprctl version` | Hyprland responds |
| Displays | `hyprctl monitors` | Connected monitors are listed |
| Desktop portal | `systemctl --user status xdg-desktop-portal-hyprland` | User portal is available |
| Audio | `pactl info` | PipeWire/Pulse compatibility responds |
| Privilege escalation | `doas true` | `doas` prompts and exits successfully |
| Default rebuild | `doas nixos-rebuild switch --flake .#` | Default workstation rebuilds and activates |
