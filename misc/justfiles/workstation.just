[doc('Build the workstation system closure')]
[no-cd]
build:
    nix build .#nixosConfigurations.workstation.config.system.build.toplevel --no-link

[doc('Validate the workstation profile')]
[no-cd]
test: build
    nix eval .#nixosConfigurations.workstation.config.services.qemuGuest.enable --apply 'enabled: if enabled then throw "workstation must not enable qemuGuest" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernelParams --apply 'params: if builtins.elem "console=ttyS0,115200n8" params then throw "workstation must not include VM serial console settings" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable GRUB"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.device --apply 'device: if device == "nodev" then "ok" else throw "workstation GRUB must target UEFI nodev"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.efiSupport --apply 'enabled: if enabled then "ok" else throw "workstation GRUB must enable EFI support"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.useOSProber --apply 'enabled: if enabled then throw "workstation must disable OS prober" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.initrd.systemd.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable systemd initrd"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.efi.canTouchEfiVariables --apply 'enabled: if enabled then "ok" else throw "workstation must allow EFI variable updates"'
    nix eval .#nixosConfigurations.workstation.config.services.openssh.enable --apply 'enabled: if enabled then throw "workstation must not enable SSH by default" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.users.users.root.hashedPassword --apply 'password: if password == "!" then "ok" else throw "workstation root password must be locked"'
    nix eval .#nixosConfigurations.workstation.config.system.stateVersion --apply 'version: if version == "25.11" then "ok" else throw "workstation stateVersion must be 25.11"'
    nix eval .#nixosConfigurations.workstation.config.hardware.enableRedistributableFirmware --apply 'enabled: if enabled then "ok" else throw "workstation must enable redistributable firmware"'
    nix eval .#nixosConfigurations.workstation.config.nix.gc.automatic --apply 'enabled: if enabled then "ok" else throw "workstation must enable automatic nix gc"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.auto-optimise-store --apply 'enabled: if enabled then "ok" else throw "workstation must enable store optimisation"'
    nix eval .#nixosConfigurations.workstation.config.platform.tuning.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable platform tuning"'
    nix eval .#nixosConfigurations.vm.config.platform.tuning.enable --apply 'enabled: if enabled then throw "vm must keep workstation tuning disabled" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.systemd.services.NetworkManager-wait-online.enable --apply 'enabled: if enabled then throw "workstation must not wait for network-online during boot" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.timeout --apply 'timeout: if timeout == 2 then "ok" else throw "workstation GRUB timeout must be 2 seconds"'
    nix eval .#nixosConfigurations.workstation.config.powerManagement.cpuFreqGovernor --apply 'governor: if governor == "powersave" then "ok" else throw "workstation must use powersave governor"'
    nix eval .#nixosConfigurations.workstation.config.zramSwap.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable zram"'
    nix eval .#nixosConfigurations.workstation.config.zramSwap.memoryPercent --apply 'percent: if percent == 25 then "ok" else throw "workstation zram memoryPercent must be 25"'
    nix eval .#nixosConfigurations.workstation.config.zramSwap.algorithm --apply 'algorithm: if algorithm == "zstd" then "ok" else throw "workstation zram algorithm must be zstd"'
    nix eval .#nixosConfigurations.workstation.config.services.earlyoom.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable earlyoom"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."vm.swappiness" == 10 then "ok" else throw "workstation swappiness must be 10"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."vm.vfs_cache_pressure" == 50 then "ok" else throw "workstation vfs_cache_pressure must be 50"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."net.core.default_qdisc" == "fq" then "ok" else throw "workstation default qdisc must be fq"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."net.ipv4.tcp_congestion_control" == "bbr" then "ok" else throw "workstation TCP congestion control must be bbr"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."net.ipv4.tcp_fastopen" == 3 then "ok" else throw "workstation tcp_fastopen must be 3"'
    nix eval .#nixosConfigurations.workstation.config.services.fstrim.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable fstrim"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.max-jobs --apply 'value: if value == "auto" then "ok" else throw "workstation nix max-jobs must be auto"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.cores --apply 'value: if value == 0 then "ok" else throw "workstation nix cores must be 0"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.experimental-features --apply 'features: if builtins.sort (a: b: a < b) features == [ "flakes" "nix-command" ] then "ok" else throw "workstation nix experimental features must stay minimal"'
    nix eval .#nixosConfigurations.workstation.config.platform.storage.enable --apply 'enabled: if enabled then throw "workstation storage layout must stay opt-in" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.platform.storage.swapFilePath --apply 'path: if path == "/swap/swapfile" then "ok" else throw "unexpected workstation swapfile path"'
    nix eval .#nixosConfigurations.workstation.config.platform.storage.swapSizeMiB --apply 'size: if size == 8192 then "ok" else throw "unexpected workstation swapfile size"'
    nix build .#checks.x86_64-linux.workstation-storage-layout
    @echo "Workstation evaluation, closure build, boot model, tuning, storage options, and VM-only separation passed."

[doc('Print real-hardware workstation tuning validation commands')]
[no-cd]
runtime-checks:
    @echo "Run these commands on installed real hardware:"
    @echo "systemd-analyze"
    @echo "systemd-analyze blame"
    @echo "systemd-analyze critical-chain"
    @echo "journalctl -b -p warning"
    @echo "sysctl net.ipv4.tcp_congestion_control"
    @echo "sysctl net.core.default_qdisc"
    @echo "sysctl net.ipv4.tcp_fastopen"
    @echo "sysctl vm.swappiness"
    @echo "sysctl vm.vfs_cache_pressure"
    @echo "journalctl --disk-usage"
