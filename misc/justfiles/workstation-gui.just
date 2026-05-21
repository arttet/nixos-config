[doc('Build the graphical workstation system closure')]
[no-cd]
build:
    nix build .#nixosConfigurations.workstation-gui.config.system.build.toplevel --no-link

[doc('Validate the graphical workstation profile')]
[no-cd]
test: build
    nix build .#checks.x86_64-linux.workstation-gui-policy --no-link
    @echo "Workstation GUI validation passed."

[doc('Print real-hardware graphical workstation power validation commands')]
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
