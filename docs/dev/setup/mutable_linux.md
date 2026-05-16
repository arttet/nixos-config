# Mutable Linux

Developing the NixOS Configuration on a traditional, mutable Linux distribution (like Arch Linux) is a common and efficient workflow. You can run Nix side-by-side with your native package manager and use QEMU for full-system validation.

## Install Nix

Install the Nix package using your distribution's package manager. 

Example for Arch Linux:
```sh
sudo pacman -S nix
```

Enable and start the Nix daemon:

```sh
sudo systemctl enable --now nix-daemon.service
```

Add your user to the `nix-users` group to allow running Nix commands without `sudo`:

```sh
sudo usermod -aG nix-users $USER
```

*Note: You may need to log out and back in for the group change to take effect.*

## Enable Flakes

Create or edit the Nix configuration file:

```sh
mkdir -p ~/.config/nix
```

```sh
cat > ~/.config/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
EOF
```

## Install Development Tools

Install the core tools required by this repository:

```sh
sudo pacman -S just qemu-full qemu-img libvirt virt-manager
```

*Note: `qemu-full` is recommended to ensure all virtualization features are available.*
