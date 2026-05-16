# Windows WSL2

Windows is supported through WSL2. The repository commands run inside Linux, not
directly in PowerShell.

The primary WSL distribution for this platform is:

```txt
openSUSE-Tumbleweed
```

## 1. Check WSL From PowerShell

Run these commands in PowerShell.

```powershell
wsl --status
```

```powershell
wsl --version
```

```powershell
wsl --list --verbose
```

```powershell
wsl --list --online
```

If the online distribution list does not work, update WSL:

```powershell
wsl --update
```

If WSL is not installed, install it first and reboot Windows:

```powershell
wsl --install
```

## 2. Install openSUSE Tumbleweed

Install the distribution:

```powershell
wsl --install -d openSUSE-Tumbleweed
```

Make it the default distribution:

```powershell
wsl --set-default openSUSE-Tumbleweed
```

Ensure it uses WSL2:

```powershell
wsl --set-version openSUSE-Tumbleweed 2
```

Start it:

```powershell
wsl -d openSUSE-Tumbleweed
```

Useful lifecycle commands:

```powershell
wsl --terminate openSUSE-Tumbleweed
wsl --shutdown
```

## 3. Update The Linux Environment

Inside openSUSE Tumbleweed:

```sh
sudo zypper refresh
```

```sh
sudo zypper update
```

Install the base tools used by this repository:

```sh
sudo zypper install git just qemu qemu-tools curl xz openssh sshpass
```

## 4. Install Nix

Install Nix inside openSUSE Tumbleweed:

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

Restart the WSL shell, then enable flakes:

```sh
mkdir -p ~/.config/nix
```

```sh
cat > ~/.config/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
EOF
```

Restart the shell again so Nix picks up the configuration.

## 5. Enter The Repository

Clone the repository if needed:

```sh
git clone https://github.com/arttet/nixos-config.git
```

```sh
cd nixos-config
```

If the repository already exists on the Windows filesystem, enter it through the
WSL mount:

```sh
cd /mnt/c/Users/<windows-user>/Documents/GitHub/nixos-config
```

## 6. Next Step

At this point the host environment is ready.

Continue with the runtime workflow:

[VM](/user/install-vm)
