# WSL2

Windows is supported through WSL2. The repository commands run inside Linux, not directly in PowerShell. We use **openSUSE Tumbleweed** as the primary development distribution because it provides a reliable, rolling-release foundation for Nix and QEMU.

## Check WSL From PowerShell

Run these commands in PowerShell to verify your WSL status:

```powershell
wsl --status
```

```powershell
wsl --version
```

If WSL is not installed, install it first and reboot Windows:

```powershell
wsl --install
```

## Install openSUSE Tumbleweed

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

## Update The Linux Environment

Inside the openSUSE shell:

```sh
sudo zypper refresh
sudo zypper update
```

Install the base tools:

```sh
sudo zypper install git just qemu qemu-tools curl xz openssh sshpass
```

## Install Nix

Install Nix inside openSUSE:

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

Enable flakes:

```sh
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
EOF
```

Restart your shell to pick up the changes.

## Lifecycle and Cleanup

Use these PowerShell commands to manage or remove the development distribution.

### Stop the Distribution

If WSL hangs or you want to free up memory:

```powershell
wsl --terminate openSUSE-Tumbleweed
```

### Completely Remove openSUSE

To delete the distribution and all files inside it (this is destructive!):

```powershell
wsl --unregister openSUSE-Tumbleweed
```
