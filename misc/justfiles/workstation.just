[doc('Build the workstation system closure')]
[no-cd]
build:
    nix build .#nixosConfigurations.workstation.config.system.build.toplevel --no-link

[doc('Validate the workstation profile')]
[no-cd]
test: build
    nix build .#checks.x86_64-linux.workstation-policy --no-link
    @echo "Workstation evaluation, closure build, boot model, tuning, storage options, and VM-only separation passed."

[doc('Print real-hardware workstation tuning validation commands')]
[no-cd]
runtime-checks:
    @echo "Run these commands on installed real hardware:"
    @echo "systemd-analyze"
    @echo "systemd-analyze blame"
    @echo "systemd-analyze critical-chain"
    @echo "resolvectl status"
    @echo "resolvectl query example.com"
    @echo "timedatectl status"
    @echo "journalctl -b -p warning"
    @echo "journalctl -b -1"
    @echo "nft list ruleset"
    @echo "doas true"
    @echo "doas id"
    @echo "just switch workstation"
    @echo "doas nixos-rebuild switch --rollback"
    @echo "sysctl net.ipv4.tcp_congestion_control"
    @echo "sysctl net.core.default_qdisc"
    @echo "sysctl net.ipv4.tcp_fastopen"
    @echo "sysctl vm.swappiness"
    @echo "sysctl vm.vfs_cache_pressure"
    @echo "journalctl --disk-usage"

[doc('Print real-hardware workstation DNS validation commands')]
[no-cd]
dns-report:
    @echo "Run these commands on installed real hardware:"
    @echo "resolvectl status"
    @echo "resolvectl query example.com"

[doc('Print real-hardware workstation network validation commands')]
[no-cd]
network-report:
    @echo "Run these commands on installed real hardware:"
    @echo "systemctl status NetworkManager"
    @echo "systemctl status firewall"
    @echo "nft list ruleset"
    @echo "sysctl net.ipv4.tcp_congestion_control"
    @echo "sysctl net.core.default_qdisc"

[doc('Print real-hardware workstation log validation commands')]
[no-cd]
logs-report:
    @echo "Run these commands on installed real hardware:"
    @echo "journalctl -b"
    @echo "journalctl -b -1"
    @echo "journalctl -b -p warning"
    @echo "journalctl --disk-usage"
