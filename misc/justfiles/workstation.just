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
    nix eval .#nixosConfigurations.workstation.config.platform.bootUx.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable graphical boot UX"'
    nix eval .#nixosConfigurations.vm.config.platform.bootUx.enable --apply 'enabled: if enabled then throw "vm must keep graphical boot UX disabled" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.plymouth.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable Plymouth for graphical LUKS prompt"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernelParams --apply 'params: if builtins.elem "splash" params && !(builtins.elem "quiet" params) then "ok" else throw "workstation must enable splash without forcing quiet boot"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.efi.canTouchEfiVariables --apply 'enabled: if enabled then "ok" else throw "workstation must allow EFI variable updates"'
    nix eval .#nixosConfigurations.workstation.config.services.xserver.enable --apply 'enabled: if enabled then throw "workstation must remain headless" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.services.openssh.enable --apply 'enabled: if enabled then throw "workstation must not enable SSH by default" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.networking.firewall.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable firewall"'
    nix eval .#nixosConfigurations.workstation.config.networking.firewall.allowedTCPPorts --apply 'ports: if ports == [] then "ok" else throw "workstation must not open TCP ports by default"'
    nix eval .#nixosConfigurations.workstation.config.networking.firewall.allowedUDPPorts --apply 'ports: if ports == [] then "ok" else throw "workstation must not open UDP ports by default"'
    nix eval .#nixosConfigurations.workstation.config.users.users.root.hashedPassword --apply 'password: if password == "!" then "ok" else throw "workstation root password must be locked"'
    nix eval .#nixosConfigurations.workstation.config.users.users.void.extraGroups --apply 'groups: if groups == [] then "ok" else throw "void placeholder user must not have admin groups"'
    nix eval .#nixosConfigurations.workstation.config.system.stateVersion --apply 'version: if version == "25.11" then "ok" else throw "workstation stateVersion must be 25.11"'
    nix build .#checks.x86_64-linux.workstation-kernel-policy
    nix eval .#nixosConfigurations.workstation.config.hardware.enableRedistributableFirmware --apply 'enabled: if enabled then "ok" else throw "workstation must enable redistributable firmware"'
    nix eval .#nixosConfigurations.workstation.config.hardware.cpu.intel.updateMicrocode --apply 'enabled: if enabled then "ok" else throw "workstation must enable Intel microcode updates"'
    nix eval .#nixosConfigurations.workstation.config.hardware.cpu.amd.updateMicrocode --apply 'enabled: if enabled then "ok" else throw "workstation must enable AMD microcode updates"'
    nix eval .#nixosConfigurations.workstation.config.nix.gc.automatic --apply 'enabled: if enabled then "ok" else throw "workstation must enable automatic nix gc"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.auto-optimise-store --apply 'enabled: if enabled then "ok" else throw "workstation must enable store optimisation"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.trusted-users --apply 'users: if builtins.elem "root" users && builtins.elem "@wheel" users then "ok" else throw "workstation trusted-users must include root and @wheel"'
    nix eval .#nixosConfigurations.workstation.config.system.autoUpgrade.enable --apply 'enabled: if enabled then throw "workstation must keep auto-upgrades disabled" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.i18n.defaultLocale --apply 'locale: if locale == "en_US.UTF-8" then "ok" else throw "workstation locale must be en_US.UTF-8"'
    nix eval .#nixosConfigurations.workstation.config.console.keyMap --apply 'keymap: if keymap == "us" then "ok" else throw "workstation console keymap must be us"'
    nix eval .#nixosConfigurations.workstation.config.platform.network.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable platform network policy"'
    nix eval .#nixosConfigurations.vm.config.platform.network.enable --apply 'enabled: if enabled then throw "vm must keep workstation network policy disabled" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.networking.networkmanager.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable NetworkManager"'
    nix eval .#nixosConfigurations.workstation.config.networking.networkmanager.dns --apply 'dns: if dns == "systemd-resolved" then "ok" else throw "workstation NetworkManager must use systemd-resolved"'
    nix eval .#nixosConfigurations.workstation.config.services.resolved.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable systemd-resolved"'
    nix eval .#nixosConfigurations.workstation.config.services.resolved.settings.Resolve.DNSSEC --apply 'mode: if mode == "true" then "ok" else throw "workstation resolved dnssec must be true"'
    nix eval .#nixosConfigurations.workstation.config.services.resolved.settings.Resolve.DNSOverTLS --apply 'mode: if mode == "true" then "ok" else throw "workstation resolved dnsovertls must be true"'
    nix eval .#nixosConfigurations.workstation.config.services.resolved.settings.Resolve.Domains --apply 'domains: if domains == [ "~." ] then "ok" else throw "workstation resolved domains must route through explicit DNS policy"'
    nix eval .#nixosConfigurations.workstation.config.services.resolved.settings.Resolve.FallbackDNS --apply 'dns: if dns == [ "1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" ] then "ok" else throw "workstation fallback DNS must use Cloudflare DoT endpoints"'
    nix eval .#nixosConfigurations.workstation.config.services.timesyncd.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable timesyncd"'
    nix eval .#nixosConfigurations.workstation.config.environment.systemPackages --apply 'packages: let names = map (pkg: pkg.pname or pkg.name) packages; in if builtins.elem "helix" names && builtins.elem "vim" names && builtins.elem "btop" names && !(builtins.elem "htop" names) then "ok" else throw "workstation package baseline must include helix/vim/btop and exclude htop"'
    nix eval .#nixosConfigurations.workstation.config.platform.security.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable platform security"'
    nix eval .#nixosConfigurations.vm.config.platform.security.enable --apply 'enabled: if enabled then throw "vm must keep workstation security disabled" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.security.sudo.enable --apply 'enabled: if enabled then throw "workstation must disable sudo" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.security.doas.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable doas"'
    nix eval .#nixosConfigurations.workstation.config.security.doas.extraRules --apply 'rules: if builtins.any (rule: rule.groups == [ "wheel" ] && rule.noPass == false && rule.persist == false && rule.keepEnv == false) rules then "ok" else throw "workstation doas rules must include minimal wheel-only password-required rule"'
    nix eval .#nixosConfigurations.workstation.config.security.protectKernelImage --apply 'enabled: if enabled then "ok" else throw "workstation must protect kernel image"'
    nix eval .#nixosConfigurations.workstation.config.security.forcePageTableIsolation --apply 'enabled: if enabled then "ok" else throw "workstation must force page table isolation"'
    nix eval .#nixosConfigurations.workstation.config.boot.tmp.useTmpfs --apply 'enabled: if enabled then "ok" else throw "workstation /tmp must use tmpfs"'
    nix eval .#nixosConfigurations.workstation.config.boot.tmp.cleanOnBoot --apply 'enabled: if enabled then "ok" else throw "workstation /tmp must be cleaned on boot"'
    nix eval .#nixosConfigurations.workstation.config.platform.security.disableThunderbolt --apply 'enabled: if enabled then "ok" else throw "workstation must disable Thunderbolt by default"'
    nix eval .#nixosConfigurations.workstation.config.boot.blacklistedKernelModules --apply 'modules: if builtins.elem "thunderbolt" modules then "ok" else throw "workstation must blacklist Thunderbolt by default"'
    nix eval .#nixosConfigurations.workstation.config.services.journald.storage --apply 'storage: if storage == "persistent" then "ok" else throw "workstation journald storage must be persistent"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."kernel.perf_event_paranoid" == 3 then "ok" else throw "workstation perf_event_paranoid must be 3"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernel.sysctl --apply 'sysctl: if sysctl."user.max_user_namespaces" == 0 then "ok" else throw "workstation user namespaces must be disabled by upstream sysctl"'
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
    @echo "resolvectl status"
    @echo "resolvectl query example.com"
    @echo "timedatectl status"
    @echo "journalctl -b -p warning"
    @echo "journalctl -b -1"
    @echo "nft list ruleset"
    @echo "doas true"
    @echo "doas id"
    @echo "doas nixos-rebuild switch --flake .#workstation"
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
