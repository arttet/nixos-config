{
  lib,
  pkgs,
  self,
  workstationStorageLayout,
}:

let
  vm = self.nixosConfigurations.vm.config;
  workstation = self.nixosConfigurations.workstation.config;
  desktop = self.nixosConfigurations.desktop.config;

  mkPolicy =
    name: checks:
    pkgs.writeText "${name}.txt" (
      lib.concatMapStringsSep "\n" (
        check: if check.assertion then "ok: ${check.message}" else throw check.message
      ) checks
      + "\n"
    );

  hasPackage =
    name: packages:
    builtins.any (
      pkg:
      let
        pname = pkg.pname or "";
        full = pkg.name or "";
      in
      pname == name || full == name || builtins.match "${name}-.*" full != null
    ) packages;

  packageName = pkg: pkg.pname or (pkg.name or "");
  packageNames = packages: map packageName packages;
  hasAllPackages = packages: required: builtins.all (name: hasPackage name packages) required;
  contains = needle: text: builtins.length (builtins.split needle text) > 1;

  requiredGuiRuntimePackages = [
    "hyprland"
    "hyprpaper"
    "hypridle"
    "hyprlock"
    "hyprpicker"
    "xdg-desktop-portal-hyprland"
    "ags"
    "mako"
    "network-manager-applet"
    "wl-clipboard"
    "cliphist"
    "grim"
    "slurp"
    "pamixer"
    "playerctl"
    "brightnessctl"
    "yazi"
    "thunar"
    "xdg-user-dirs"
  ];

  requiredGuiApplicationPackages = [
    "zen-browser"
    "brave"
    "google-chrome"
    "tor-browser"
    "ghostty"
    "alacritty"
    "wezterm"
    "neovim"
    "helix"
    "vscode"
    "zed-editor"
    "zsh"
    "nushell"
    "starship"
    "tmux"
    "lazygit"
    "gh"
    "fastfetch"
    "fzf"
    "ripgrep"
    "fd"
    "bat"
    "eza"
    "zoxide"
    "cmake"
    "ninja"
    "clang"
    "llvm"
    "lldb"
    "gdb"
    "pkg-config"
    "rustup"
    "rust-analyzer"
    "go"
    "gopls"
    "delve"
    "golangci-lint"
    "nodejs"
    "bun"
    "pnpm"
    "typescript"
    "python3"
    "uv"
    "ruff"
    "pyright"
    "docker"
    "docker-compose"
    "docker-buildx"
    "telegram-desktop"
    "zoom"
    "obsidian"
    "libreoffice"
    "zathura"
    "gnupg"
    "keepassxc"
    "sudo"
    "veracrypt"
    "cloudflare-warp"
    "protonmail-desktop"
    "proton-pass"
    "yandex-disk"
    "imv"
    "vlc"
    "transmission"
  ];

  requiredGuiFontPackages = [
    "inter"
    "noto-fonts"
    "noto-fonts-cjk-sans"
    "noto-fonts-color-emoji"
  ];
in
{
  vm-policy = mkPolicy "vm-policy" [
    {
      assertion = vm.services.qemuGuest.enable;
      message = "vm must enable qemuGuest";
    }
    {
      assertion = builtins.elem "console=ttyS0,115200n8" vm.boot.kernelParams;
      message = "vm must include serial console settings";
    }
    {
      assertion = !vm.virtualisation.vmVariant.virtualisation.graphics;
      message = "vm must be headless";
    }
  ];

  workstation-policy = mkPolicy "workstation-policy" [
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
      assertion = workstation.system.stateVersion == "25.11";
      message = "workstation stateVersion must be 25.11";
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
      assertion = workstation.services.resolved.settings.Resolve.DNSOverTLS == "true";
      message = "workstation resolved dnsovertls must be true";
    }
    {
      assertion = workstation.services.resolved.settings.Resolve.Domains == [ "~." ];
      message = "workstation resolved domains must route through explicit DNS policy";
    }
    {
      assertion =
        workstation.services.resolved.settings.Resolve.FallbackDNS == [
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
        ];
      message = "workstation fallback DNS must use Cloudflare DoT endpoints";
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
  ];

  desktop-policy = mkPolicy "desktop-policy" [
    {
      assertion = !workstation.services.xserver.enable;
      message = "headless workstation must remain desktop-free";
    }
    {
      assertion = !desktop.services.xserver.enable;
      message = "desktop must not enable an X11 desktop/session";
    }
    {
      assertion = desktop.services.greetd.enable;
      message = "desktop must enable greetd";
    }
    {
      assertion =
        builtins.match ".*tuigreet.*--cmd .*uwsm start hyprland-uwsm.desktop.*" desktop.services.greetd.settings.default_session.command
        != null;
      message = "desktop greetd must launch Hyprland through UWSM";
    }
    {
      assertion = desktop.boot.kernel.sysctl."user.max_user_namespaces" > 0;
      message = "desktop must allow browser sandbox user namespaces";
    }
    {
      assertion = desktop.programs.hyprland.enable;
      message = "desktop must enable Hyprland";
    }
    {
      assertion = desktop.programs.hyprland.withUWSM;
      message = "desktop must launch Hyprland through UWSM";
    }
    {
      assertion =
        desktop.programs.uwsm.waylandCompositors.hyprland.binPath
        == "/run/current-system/sw/bin/start-hyprland";
      message = "desktop UWSM must launch Hyprland through start-hyprland";
    }
    {
      assertion = desktop.programs.hyprland.xwayland.enable;
      message = "desktop must enable XWayland only as an explicit compatibility exception";
    }
    {
      assertion =
        let
          text = desktop.environment.etc."xdg/hypr/hyprland.conf".text;
        in
        contains "SUPER, Return, exec" text
        && contains "mako" text
        && contains "cliphist" text
        && contains "gesture = 3, horizontal, workspace" text
        && contains "kb_options = grp:alt_shift_toggle" text
        && contains "pamixer" text
        && contains "brightnessctl" text
        && contains "hyprlock" text
        && contains "workstation-session-menu" text;
      message = "desktop Hyprland config must cover terminal, notifications, clipboard, touchpad gestures, keyboard layout switching, audio, brightness, lock, and session menu";
    }
    {
      assertion =
        contains "lock_cmd" desktop.environment.etc."xdg/hypr/hypridle.conf".text
        && contains "hyprlock" desktop.environment.etc."xdg/hypr/hypridle.conf".text;
      message = "desktop must provide a minimal hypridle config";
    }
    {
      assertion = contains "input-field" desktop.environment.etc."xdg/hypr/hyprlock.conf".text;
      message = "desktop must provide a minimal hyprlock config";
    }
    {
      assertion = desktop.services.dbus.enable;
      message = "desktop must enable dbus";
    }
    {
      assertion = desktop.security.polkit.enable;
      message = "desktop must enable polkit";
    }
    {
      assertion = desktop.hardware.graphics.enable;
      message = "desktop must enable hardware graphics support";
    }
    {
      assertion = !workstation.platform.power.enable;
      message = "headless workstation must not enable desktop power policy";
    }
    {
      assertion = desktop.platform.power.enable;
      message = "desktop must enable platform power policy";
    }
    {
      assertion = desktop.services.upower.enable;
      message = "desktop must enable UPower through the power layer";
    }
    {
      assertion = desktop.services.upower.criticalPowerAction == "PowerOff";
      message = "desktop low battery action must be PowerOff";
    }
    {
      assertion = desktop.services.tlp.enable;
      message = "desktop must enable TLP through the power layer";
    }
    {
      assertion = !desktop.services.power-profiles-daemon.enable;
      message = "desktop must use TLP instead of power-profiles-daemon";
    }
    {
      assertion =
        desktop.services.tlp.settings.STOP_CHARGE_THRESH_BAT0 == 80
        && desktop.services.tlp.settings.START_CHARGE_THRESH_BAT0 == 75
        && desktop.services.tlp.settings.PLATFORM_PROFILE_ON_BAT == "low-power";
      message = "desktop TLP charge and profile policy changed unexpectedly";
    }
    {
      assertion =
        desktop.systemd.sleep.settings.Sleep.AllowHibernation == false
        && desktop.systemd.sleep.settings.Sleep.AllowHybridSleep == false
        && desktop.systemd.sleep.settings.Sleep.AllowSuspendThenHibernate == false;
      message = "desktop must explicitly disable hibernation modes";
    }
    {
      assertion = desktop.services.pipewire.enable;
      message = "desktop must enable PipeWire";
    }
    {
      assertion = desktop.services.pipewire.wireplumber.enable;
      message = "desktop must enable WirePlumber";
    }
    {
      assertion = desktop.xdg.portal.enable;
      message = "desktop must enable XDG portals";
    }
    {
      assertion =
        desktop.xdg.mime.defaultApplications."inode/directory" == "thunar.desktop"
        && desktop.xdg.mime.defaultApplications."application/pdf" == "org.pwmt.zathura.desktop"
        && desktop.xdg.mime.defaultApplications."x-scheme-handler/https" == "zen.desktop";
      message = "desktop must define minimal MIME defaults";
    }
    {
      assertion = desktop.programs.thunar.enable;
      message = "desktop must enable Thunar through the NixOS module";
    }
    {
      assertion = desktop.programs.zsh.enable;
      message = "desktop must enable zsh availability";
    }
    {
      assertion = desktop.virtualisation.docker.enable;
      message = "desktop must enable Docker";
    }
    {
      assertion = hasAllPackages desktop.environment.systemPackages requiredGuiRuntimePackages;
      message = "desktop must include baseline runtime UX tools";
    }
    {
      assertion = hasAllPackages desktop.environment.systemPackages requiredGuiApplicationPackages;
      message = "desktop application and development baseline is incomplete";
    }
    {
      assertion = hasAllPackages desktop.fonts.packages requiredGuiFontPackages;
      message = "desktop font baseline is incomplete";
    }
    {
      assertion =
        let
          names = packageNames desktop.environment.systemPackages;
        in
        !(builtins.elem "waybar" names)
        && !(builtins.elem "eww" names)
        && !(builtins.elem "nautilus" names)
        && !(builtins.elem "dolphin" names);
      message = "desktop must not include Waybar, EWW, Nautilus, or Dolphin as baseline";
    }
  ];
}
