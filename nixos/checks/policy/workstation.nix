{
  vm,
  workstation,
  pkgs,
  packageNames,
  workstationStorageLayout,
}:
[
  {
    assertion = !workstation.services.qemuGuest.enable;
    message = "workstation must not enable qemuGuest";
  }
  {
    assertion = !(builtins.elem "console=ttyS0,115200n8" workstation.boot.kernelParams);
    message = "workstation must not include VM serial console settings";
  }
  {
    assertion = workstation.boot.loader.grub.enable;
    message = "workstation must enable GRUB";
  }
  {
    assertion = workstation.boot.loader.grub.device == "nodev";
    message = "workstation GRUB must target UEFI nodev";
  }
  {
    assertion = workstation.boot.loader.grub.efiSupport;
    message = "workstation GRUB must enable EFI support";
  }
  {
    assertion = !workstation.boot.loader.grub.useOSProber;
    message = "workstation must disable OS prober";
  }
  {
    assertion = workstation.boot.loader.grub.configurationLimit == 10;
    message = "workstation GRUB must keep 10 boot generations";
  }
  {
    assertion = workstation.boot.initrd.systemd.enable;
    message = "workstation must enable systemd initrd";
  }
  {
    assertion = workstation.platform.bootUx.enable;
    message = "workstation must enable graphical boot UX";
  }
  {
    assertion = !vm.platform.bootUx.enable;
    message = "vm must keep graphical boot UX disabled";
  }
  {
    assertion = workstation.boot.plymouth.enable;
    message = "workstation must enable Plymouth for graphical LUKS prompt";
  }
  {
    assertion =
      builtins.elem "splash" workstation.boot.kernelParams
      && !(builtins.elem "quiet" workstation.boot.kernelParams);
    message = "workstation must enable splash without forcing quiet boot";
  }
  {
    assertion = workstation.boot.loader.efi.canTouchEfiVariables;
    message = "workstation must allow EFI variable updates";
  }
  {
    assertion = !workstation.services.xserver.enable;
    message = "workstation must remain headless";
  }
  {
    assertion = !workstation.services.openssh.enable;
    message = "workstation must not enable SSH by default";
  }
  {
    assertion = workstation.networking.firewall.enable;
    message = "workstation must enable firewall";
  }
  {
    assertion = workstation.networking.firewall.allowedTCPPorts == [ ];
    message = "workstation must not open TCP ports by default";
  }
  {
    assertion = workstation.networking.firewall.allowedUDPPorts == [ ];
    message = "workstation must not open UDP ports by default";
  }
  {
    assertion = workstation.users.users.root.hashedPassword == "!";
    message = "workstation root password must be locked";
  }
  {
    assertion = workstation.users.users.void.extraGroups == [ ];
    message = "void placeholder user must not have admin groups";
  }
  {
    assertion = workstation.system.stateVersion == "26.05";
    message = "workstation stateVersion must be 26.05";
  }
  {
    assertion =
      workstation.boot.kernelPackages.kernel.outPath == pkgs.linuxPackages_latest.kernel.outPath;
    message = "workstation uses pkgs.linuxPackages_latest";
  }
  {
    assertion = workstation.hardware.enableRedistributableFirmware;
    message = "workstation must enable redistributable firmware";
  }
  {
    assertion = workstation.hardware.cpu.intel.updateMicrocode;
    message = "workstation must enable Intel microcode updates";
  }
  {
    assertion = workstation.hardware.cpu.amd.updateMicrocode;
    message = "workstation must enable AMD microcode updates";
  }
  {
    assertion = workstation.nix.gc.automatic;
    message = "workstation must enable automatic nix gc";
  }
  {
    assertion = workstation.nix.settings.auto-optimise-store;
    message = "workstation must enable store optimisation";
  }
  {
    assertion =
      builtins.elem "root" workstation.nix.settings.trusted-users
      && builtins.elem "@wheel" workstation.nix.settings.trusted-users;
    message = "workstation trusted-users must include root and @wheel";
  }
  {
    assertion = !workstation.system.autoUpgrade.enable;
    message = "workstation must keep auto-upgrades disabled";
  }
  {
    assertion = workstation.i18n.defaultLocale == "en_US.UTF-8";
    message = "workstation locale must be en_US.UTF-8";
  }
  {
    assertion = workstation.console.keyMap == "us";
    message = "workstation console keymap must be us";
  }
  {
    assertion = workstation.console.font == "ter-v18n";
    message = "workstation console font must use Terminus 18";
  }
  {
    assertion = workstation.platform.network.enable;
    message = "workstation must enable platform network policy";
  }
  {
    assertion = !vm.platform.network.enable;
    message = "vm must keep workstation network policy disabled";
  }
  {
    assertion = workstation.networking.networkmanager.enable;
    message = "workstation must enable NetworkManager";
  }
  {
    assertion = workstation.networking.networkmanager.dns == "systemd-resolved";
    message = "workstation NetworkManager must use systemd-resolved";
  }
  {
    assertion = workstation.services.resolved.enable;
    message = "workstation must enable systemd-resolved";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.DNSSEC == "true";
    message = "workstation resolved dnssec must be true";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.DNSOverTLS == "false";
    message = "workstation resolved dnsovertls must be false (DoH via dnsproxy)";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.Domains == [ "~." ];
    message = "workstation resolved domains must route through explicit DNS policy";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.DNS == [ "127.0.0.1" ];
    message = "workstation resolved DNS must point to local dnsproxy";
  }
  {
    assertion =
      workstation.services.resolved.settings.Resolve.FallbackDNS == [
        "8.8.8.8"
        "8.8.4.4"
      ];
    message = "workstation fallback DNS must use Google DNS";
  }
  {
    assertion = workstation.services.dnsproxy.enable;
    message = "workstation must enable dnsproxy for DoH";
  }
  {
    assertion = workstation.services.timesyncd.enable;
    message = "workstation must enable timesyncd";
  }
  {
    assertion =
      let
        names = packageNames workstation.environment.systemPackages;
      in
      builtins.elem "helix" names
      && builtins.elem "vim" names
      && builtins.elem "btop" names
      && !(builtins.elem "htop" names);
    message = "workstation package baseline must include helix/vim/btop and exclude htop";
  }
  {
    assertion = workstation.platform.security.enable;
    message = "workstation must enable platform security";
  }
  {
    assertion = !vm.platform.security.enable;
    message = "vm must keep workstation security disabled";
  }
  {
    assertion = !workstation.security.sudo.enable;
    message = "workstation must disable sudo";
  }
  {
    assertion = workstation.security.doas.enable;
    message = "workstation must enable doas";
  }
  {
    assertion = builtins.any (
      rule:
      rule.groups == [ "wheel" ] && rule.noPass == false && rule.persist == false && rule.keepEnv == false
    ) workstation.security.doas.extraRules;
    message = "workstation doas rules must include minimal wheel-only password-required rule";
  }
  {
    assertion = workstation.security.protectKernelImage;
    message = "workstation must protect kernel image";
  }
  {
    assertion = workstation.security.forcePageTableIsolation;
    message = "workstation must force page table isolation";
  }
  {
    assertion = workstation.boot.tmp.useTmpfs;
    message = "workstation /tmp must use tmpfs";
  }
  {
    assertion = workstation.boot.tmp.cleanOnBoot;
    message = "workstation /tmp must be cleaned on boot";
  }
  {
    assertion = workstation.platform.security.disableThunderbolt;
    message = "workstation must disable Thunderbolt by default";
  }
  {
    assertion = builtins.elem "thunderbolt" workstation.boot.blacklistedKernelModules;
    message = "workstation must blacklist Thunderbolt by default";
  }
  {
    assertion = workstation.services.journald.storage == "persistent";
    message = "workstation journald storage must be persistent";
  }
  {
    assertion = !workstation.services.fail2ban.enable;
    message = "workstation must keep fail2ban disabled when ssh is off";
  }
  {
    assertion = workstation.services.fail2ban.maxretry == 5;
    message = "workstation fail2ban maxretry must be 5";
  }
  {
    assertion = workstation.services.fail2ban.daemonSettings.DEFAULT.findtime == "10m";
    message = "workstation fail2ban daemonSettings must set findtime to 10m";
  }
  {
    assertion = workstation.services.fail2ban.bantime == "1h";
    message = "workstation fail2ban bantime must be 1h";
  }
  {
    assertion = workstation.services.fail2ban.bantime-increment.enable;
    message = "workstation fail2ban must enable bantime-increment";
  }
  {
    assertion = !vm.services.fail2ban.enable;
    message = "vm must keep fail2ban disabled";
  }
  {
    assertion = workstation.boot.kernel.sysctl."kernel.perf_event_paranoid" == 3;
    message = "workstation perf_event_paranoid must be 3";
  }
  {
    assertion = workstation.boot.kernel.sysctl."user.max_user_namespaces" == 0;
    message = "workstation user namespaces must be disabled by upstream sysctl";
  }
  {
    assertion = workstation.platform.tuning.enable;
    message = "workstation must enable platform tuning";
  }
  {
    assertion = !vm.platform.tuning.enable;
    message = "vm must keep workstation tuning disabled";
  }
  {
    assertion = !workstation.systemd.services.NetworkManager-wait-online.enable;
    message = "workstation must not wait for network-online during boot";
  }
  {
    assertion = workstation.boot.loader.timeout == 2;
    message = "workstation GRUB timeout must be 2 seconds";
  }
  {
    assertion = workstation.powerManagement.cpuFreqGovernor == "powersave";
    message = "workstation must use powersave governor";
  }
  {
    assertion = workstation.zramSwap.enable;
    message = "workstation must enable zram";
  }
  {
    assertion = workstation.zramSwap.memoryPercent == 25;
    message = "workstation zram memoryPercent must be 25";
  }
  {
    assertion = workstation.zramSwap.algorithm == "zstd";
    message = "workstation zram algorithm must be zstd";
  }
  {
    assertion = workstation.services.earlyoom.enable;
    message = "workstation must enable earlyoom";
  }
  {
    assertion = workstation.boot.kernel.sysctl."vm.swappiness" == 10;
    message = "workstation swappiness must be 10";
  }
  {
    assertion = workstation.boot.kernel.sysctl."vm.vfs_cache_pressure" == 50;
    message = "workstation vfs_cache_pressure must be 50";
  }
  {
    assertion = workstation.boot.kernel.sysctl."net.core.default_qdisc" == "fq";
    message = "workstation default qdisc must be fq";
  }
  {
    assertion = workstation.boot.kernel.sysctl."net.ipv4.tcp_congestion_control" == "bbr";
    message = "workstation TCP congestion control must be bbr";
  }
  {
    assertion = workstation.boot.kernel.sysctl."net.ipv4.tcp_fastopen" == 3;
    message = "workstation tcp_fastopen must be 3";
  }
  {
    assertion = workstation.services.fstrim.enable;
    message = "workstation must enable fstrim";
  }
  {
    assertion = workstation.nix.settings.max-jobs == "auto";
    message = "workstation nix max-jobs must be auto";
  }
  {
    assertion = workstation.nix.settings.cores == 0;
    message = "workstation nix cores must be 0";
  }
  {
    assertion =
      builtins.sort (a: b: a < b) workstation.nix.settings.experimental-features == [
        "flakes"
        "nix-command"
      ];
    message = "workstation nix experimental features must stay minimal";
  }
  {
    assertion = !workstation.platform.storage.enable;
    message = "workstation storage layout must stay opt-in";
  }
  {
    assertion = workstation.platform.storage.swapFilePath == "/swap/swapfile";
    message = "unexpected workstation swapfile path";
  }
  {
    assertion = workstation.platform.storage.swapSizeMiB == 8192;
    message = "unexpected workstation swapfile size";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.device == "/dev/disk/by-id/workstation-example";
    message = "workstation storage example disk path must be stable";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.type == "gpt";
    message = "workstation storage layout must use GPT";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.partitions.ESP.size == "512M";
    message = "workstation ESP size must be 512M";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.ESP.content.mountpoint == "/boot/efi";
    message = "workstation ESP mountpoint must be /boot/efi";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.partitions.boot.size == "512M";
    message = "workstation boot partition size must be 512M";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.boot.content.mountpoint == "/boot";
    message = "workstation boot mountpoint must be /boot";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.partitions.luks.size == "100%";
    message = "workstation LUKS partition must fill remaining disk";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.type == "luks";
    message = "workstation encrypted partition must use luks";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.name == "cryptroot";
    message = "workstation encrypted partition must be named cryptroot";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.extraFormatArgs == [
        "--type"
        "luks2"
      ];
    message = "workstation encrypted partition must use LUKS2";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.type == "btrfs";
    message = "workstation encrypted filesystem must be btrfs";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.subvolumes."@root".mountpoint
      == "/";
    message = "workstation root subvolume must mount at /";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.subvolumes."@swap".mountpoint
      == "/swap";
    message = "workstation swap subvolume must mount at /swap";
  }
]
