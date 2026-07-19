[doc('Build the desktop system closure')]
[no-cd]
build:
    nix build .#nixosConfigurations.desktop.config.system.build.toplevel --no-link

[doc('Validate the desktop profile')]
[no-cd]
test: build
    nix build .#checks.x86_64-linux.desktop-policy --no-link
    @echo "Desktop validation passed."

[doc('Print real-hardware tty1 validation commands')]
[no-cd]
tty-checks:
    @echo "Run these commands on installed real hardware:"
    @echo "systemctl show getty.target -p Wants"
    @echo "systemctl status kmsconvt@tty1.service display-manager.service"
    @echo "systemctl show kmsconvt@tty1.service -p ActiveState -p SubState -p TTYPath"
    @echo "loginctl list-sessions"
    @echo "journalctl -b -u kmsconvt@tty1.service -u display-manager.service"
    @echo "Switch to tty1 with Ctrl+Alt+F1 and confirm the login prompt and Nerd Font glyphs."

[doc('Print real-hardware desktop power validation commands')]
[no-cd]
power-checks:
    @echo "Run these commands on installed real hardware:"
    @echo "upower -e"
    @echo "upower -d"
    @echo "tlp-stat -b"
    @echo "tlp-stat -s"
    @echo "tlp-stat -p"
    @echo "systemctl status tlp"
    @echo "systemctl status power-profiles-daemon"
    @echo "systemd-analyze cat-config systemd/sleep.conf"
