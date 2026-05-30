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
- Leave Secure Boot disabled or in setup/custom mode for the first install.
  Enable it only after the installed system boots and `sbctl` keys are enrolled.
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
curl -sL https://github.com/arttet/nixos-config/raw/main/install.sh | sudo bash
```

The command runs the installer with root privileges. If the live console renders
colors poorly, use the same command with colors disabled:

```sh
curl -sL https://github.com/arttet/nixos-config/raw/main/install.sh | sudo NO_COLOR=1 bash
```

The entrypoint clones or updates the repository under
`/root/.cache/nixos-config-installer/repo`, then starts the Nushell installer:

```sh
nu scripts/install/bootstrap.nu --apply
```

The entrypoint provides `nushell`, `mkpasswd`, and `gum` through a temporary
`nix shell`. `gum` is used only for the interactive TUI. Tests and plain logs can
disable it with:

```sh
NIX_CONFIG_INSTALL_PLAIN_UI=1 NO_COLOR=1 nu scripts/install/bootstrap.nu --dry-run
```

The installer defaults to the `main` branch. To test a development branch from
the live ISO, download the entrypoint from that branch and set `BRANCH` to the
same branch:

```sh
curl -sL https://github.com/arttet/nixos-config/raw/dev/install.sh | sudo BRANCH=dev bash
```

`NIX_CONFIG_INSTALL_REPO_BRANCH` is also supported as a longer compatibility
alias.

## 💬 Interactive Setup Wizard

The wizard collects the local account, machine identity, timezone, and target
disk. No disk is formatted until the final exact disk-path confirmation.

The wizard asks for:

| Prompt        | Meaning                                                                                                          |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| Session       | Local name for this installer run; files are stored under `$HOME/.cache/nixos-config-installer/state/<session>/` |
| Profile       | System profile to install; keep `default` for the normal workstation                                             |
| User          | Human-readable account description, such as `User` or `Default User`                                             |
| Username      | Initial local Linux username, lowercase only, such as `user`; `User` is invalid                                  |
| User password | Initial login password for that user; input is hidden and repeated once                                          |
| Hostname      | Machine hostname                                                                                                 |
| Timezone      | NixOS timezone, such as `Etc/UTC`                                                                                |
| Disk          | Target disk device to repartition and format                                                                     |
| Action        | `dry-run` or `apply`                                                                                             |

When `apply` starts, the installer also asks for the LUKS passphrase that will
protect the encrypted root container. This passphrase is separate from the local
user login password.

Keep the profile as `default` for a normal workstation install. The flake
default points to the graphical workstation. Do not switch to another profile
unless you are deliberately testing a development workflow.

Disk discovery prints available disks from `lsblk` and matching
`/dev/disk/by-id/` entries when available. Review the disk carefully. The
installer will ask you to type the exact selected disk path before formatting.

## ⚙️ What Apply Does

When `apply` is selected and disk confirmation succeeds, the installer:

1. Runs pre-flight checks for UEFI mode, required commands, free `/mnt`, and
   network access to `cache.nixos.org`.
2. Generates a temporary disko config under
   `/run/nixos-config-installer/<session>/runtime/`.
3. Runs `disko` to partition and format the disk.
4. Runs `nixos-generate-config --root /mnt`.
5. Writes the local user overlay to `/mnt/root/.nix-config-local/user.nix`.
6. Writes the local password hash file to
   `/mnt/root/.nix-config-local/user.passwd`.
7. Installs the default workstation target with
   `nixos-install --impure --no-root-passwd`.

Before each external command, the installer prints the exact command and asks
for `y` or `yes` approval. It then checks the command exit code before
continuing:

| Command                                   | Comment                                                                                       |
| ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| `disko`                                   | Runs after disk confirmation with a temporary LUKS `passwordFile` generated by the installer. |
| `nixos-generate-config --root /mnt`       | Runs only after `disko` exits successfully.                                                   |
| `nixos-install --impure --no-root-passwd` | Runs only after hardware configuration and local installer state are in place.                |

The temporary LUKS password file and generated user password hash are kept under
`/run/nixos-config-installer/<session>/secrets/` and removed during the apply
flow. The installed system still receives the hashed user password at
`/mnt/root/.nix-config-local/user.passwd`, because the generated local overlay
references `/root/.nix-config-local/user.passwd` for future rebuilds.

The installer writes non-secret command and exit-code diagnostics to:

```txt
/run/nixos-config-installer/<session>/runtime/install.log
```

The `disko` and `nixos-generate-config` stdout/stderr streams are copied into
that log after each command completes. `nixos-install` keeps live output on the
console and logs command start plus exit code.

The generated local overlay contains the hostname, timezone, initial user, user
shell, `wheel` membership, and a reference to the password hash file. The
password hash itself is stored separately in `user.passwd`, not inside the Nix
overlay.

Both target files are local machine state and must not be committed to the
repository.

After the installer completes, reboot:

```sh
reboot
```

## ✅ After Installation

After booting the installed workstation, log in as the local user created by the
installer.

### 🧭 First Boot Checks

Run each check separately from the installed system. The default login shell is
Nushell, so the shell-specific checks below use Nushell syntax.

| Check                | Command                                               | Expected result                         |
| -------------------- | ----------------------------------------------------- | --------------------------------------- |
| UEFI boot            | See the Nushell command below                         | Output is `true`                        |
| Mounted filesystems  | `findmnt`                                             | Installed filesystems are visible       |
| Swap                 | `swapon --show`                                       | Swap is available                       |
| Network              | `systemctl status NetworkManager`                     | NetworkManager is active                |
| Login manager        | `systemctl status greetd`                             | `greetd` is active                      |
| Session type         | See the Nushell command below                         | Output is `wayland`                     |
| Hyprland version     | `hyprctl version`                                     | Hyprland responds                       |
| Displays             | `hyprctl monitors`                                    | Connected monitors are listed           |
| Desktop portal       | `systemctl --user status xdg-desktop-portal-hyprland` | User portal is available                |
| Audio                | `wpctl status`                                        | PipeWire/WirePlumber devices are listed |
| Privilege escalation | `doas true`                                           | `doas` prompts and exits successfully   |

Nushell commands for the shell-specific checks:

```nu
"/sys/firmware/efi" | path exists
$env.XDG_SESSION_TYPE? | default ""
```

### 🔑 Prepare Git Access

The installed system does not contain a working copy of this repository. Before
running flake rebuilds, export the resident SSH keys from the YubiKey and make
sure GitHub knows the public key.

Insert the YubiKey, then run:

```nu
^mkdir -p ~/.ssh
ssh-keygen -K
chmod 700 ~/.ssh
glob "~/.ssh/id_*" | where {|path| not ($path | str ends-with ".pub") } | each {|path| chmod 600 $path }
glob "~/.ssh/*.pub" | each {|path| chmod 644 $path }
```

If the clone step below fails with a permission error, add the exported public
SSH key from `~/.ssh/*.pub` to GitHub and try again.

### 📦 Clone the Repository

Clone the repository into the local home directory:

```nu
git clone git@github.com:arttet/nixos-config.git ~/nixos-config
cd ~/nixos-config
just setup
```

### 🔄 Rebuild from the Repository

Build and test the graphical workstation target before switching:

```nu
just build
just test
just switch
```

The default profile points to the graphical workstation. To build or test a
specific profile explicitly, pass it as an argument:

```nu
just build workstation-gui
just test workstation-gui
```

The rebuild uses the local repository and creates a new bootable generation.

### 🔐 Enable Secure Boot

Secure Boot is configured through `sbctl`, while the system intentionally keeps
GRUB for future custom boot UX work. Enable firmware Secure Boot only after the
installed system boots, Git access works, and a rebuild from the local
repository succeeds.

Prepare the firmware for key enrollment first. In many firmware menus this means
switching Secure Boot to setup/custom mode or clearing the existing Secure Boot
keys. Keep a known-good firmware recovery path before changing keys.

Create and enroll the local Secure Boot keys:

```nu
doas sbctl status
doas sbctl create-keys
doas sbctl enroll-keys -m
```

The `-m` flag keeps Microsoft certificates enrolled alongside the local keys,
which is useful for common firmware, GPU option ROMs, and removable boot media.

Rebuild once more from the repository. The GRUB install hook signs EFI artifacts
under `/boot/efi` automatically when `sbctl` keys exist:

```nu
just switch
doas sbctl verify
```

If `sbctl verify` reports unsigned EFI files that belong to the NixOS boot path,
do not enable Secure Boot yet. Rebuild again and inspect the reported paths.

After verification succeeds, enable Secure Boot in firmware and reboot.

Advanced GRUB locking is a separate hardening step. GRUB can also be configured
to require a password for unsafe edits and to verify detached signatures for
files loaded from `/boot`, but that workflow needs local GRUB password and
signing-key material and is not required for the baseline Secure Boot setup.

### 🧪 Runtime Validation

After rebooting with Secure Boot enabled in firmware, run:

```nu
doas sbctl status
doas sbctl verify
bootctl status
```

Expected result:

- Secure Boot is enabled.
- EFI boot artifacts are signed.
- `sbctl verify` reports no unsigned EFI artifacts relevant to the NixOS boot path.
- GRUB still boots the current NixOS generation normally.
