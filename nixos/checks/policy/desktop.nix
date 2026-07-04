{
  self,
  lib,
  unstablePkgs,
  vm,
  workstation,
  desktop,
  desktopHome,
  hasPackage,
  hasAllPackages,
  findPackage,
  packageName,
  packageNames,
  contains,
  requiredGuiRuntimePackages,
  requiredGuiApplicationPackages,
  requiredGuiFontPackages,
}:
[
  {
    assertion = !workstation.services.xserver.enable;
    message = "headless workstation must remain desktop-free";
  }
  {
    assertion = !desktop.services.xserver.enable;
    message = "desktop must not enable an X11 desktop/session";
  }
  {
    assertion = desktop.platform.grubTheme.enable;
    message = "desktop must enable GRUB theme";
  }
  {
    assertion =
      desktop.platform.sddm.enable
      && desktop.services.displayManager.sddm.enable
      && !desktop.platform.greetd.enable
      && !desktop.services.greetd.enable;
    message = "desktop must use SDDM and keep the greetd fallback disabled";
  }
  {
    assertion =
      packageName desktop.services.displayManager.sddm.package == "sddm"
      && desktop.services.displayManager.sddm.wayland.enable
      && desktop.services.displayManager.sddm.wayland.compositor == "kwin"
      && desktop.services.displayManager.sddm.theme == "sddm-astronaut-theme"
      &&
        desktop.services.displayManager.sddm.settings.Theme.CursorTheme == "catppuccin-mocha-blue-cursors"
      && desktop.services.displayManager.sddm.settings.Theme.CursorSize == 24
      && contains "XCURSOR_THEME=catppuccin-mocha-blue-cursors" desktop.services.displayManager.sddm.settings.General.GreeterEnvironment
      && contains "XCURSOR_SIZE=24" desktop.services.displayManager.sddm.settings.General.GreeterEnvironment
      && contains "XCURSOR_PATH=" desktop.services.displayManager.sddm.settings.General.GreeterEnvironment
      && contains "QT_WAYLAND_SHELL_INTEGRATION=layer-shell" desktop.services.displayManager.sddm.settings.General.GreeterEnvironment
      &&
        desktop.systemd.services.display-manager.environment.XCURSOR_THEME
        == "catppuccin-mocha-blue-cursors"
      && desktop.systemd.services.display-manager.environment.XCURSOR_SIZE == "24"
      && contains "/share/icons" desktop.systemd.services.display-manager.environment.XCURSOR_PATH
      && desktop.environment.sessionVariables.XCURSOR_THEME == "catppuccin-mocha-blue-cursors"
      && desktop.environment.sessionVariables.XCURSOR_SIZE == "24"
      && contains "/share/icons" desktop.environment.sessionVariables.XCURSOR_PATH
      && hasPackage "sddm-astronaut" desktop.services.displayManager.sddm.extraPackages
      && hasPackage "sddm-astronaut" desktop.environment.systemPackages;
    message = "desktop must use SDDM Qt6 on KWin Wayland with the Catppuccin Mocha Blue cursor";
  }
  {
    assertion = desktop.services.displayManager.defaultSession == "hyprland-uwsm";
    message = "desktop SDDM must preselect the Hyprland UWSM session";
  }
  {
    assertion =
      desktop.programs.ssh.startAgent
      && desktop.programs.ssh.enableAskPassword
      && packageName desktop.programs.ssh.package == "openssh"
      && contains "/bin/ksshaskpass" desktop.programs.ssh.askPassword
      && desktop.environment.sessionVariables.SSH_AUTH_SOCK == "$XDG_RUNTIME_DIR/ssh-agent"
      && !workstation.programs.ssh.startAgent;
    message = "desktop must provide the OpenSSH agent with a graphical PIN prompt";
  }
  {
    assertion =
      builtins.elem "quiet" desktop.boot.kernelParams
      && builtins.elem "fbcon=nodefer" desktop.boot.kernelParams
      && builtins.elem "plymouth.ignore-serial-consoles" desktop.boot.kernelParams
      && builtins.elem "loglevel=3" desktop.boot.kernelParams
      && builtins.elem "udev.log_level=3" desktop.boot.kernelParams
      && builtins.elem "vt.global_cursor_default=0" desktop.boot.kernelParams
      && !(builtins.elem "systemd.show_status=false" desktop.boot.kernelParams)
      && !(builtins.elem "rd.systemd.show_status=false" desktop.boot.kernelParams);
    message = "desktop must use quiet graphical boot parameters";
  }
  {
    assertion =
      desktop.platform.bootUx.earlyGraphicsDrivers == [ "amdgpu" ]
      && builtins.elem "amdgpu" desktop.boot.initrd.kernelModules
      && !(builtins.elem "i915" desktop.boot.initrd.kernelModules)
      && !(builtins.elem "nouveau" desktop.boot.initrd.kernelModules);
    message = "desktop must load amdgpu in initrd for early Plymouth DRM (override in host overlay for Intel/Nvidia)";
  }
  {
    assertion = desktop.boot.plymouth.theme == "splash";
    message = "desktop must preserve the configured Plymouth splash theme";
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
        text = desktop.environment.etc."xdg/hypr/hyprland.lua".text;
      in
      contains "\\+ Return" text
      && contains "uwsm finalize" text
      && contains "uwsm app -- " text
      && contains "app_launch_prefix" desktop.environment.etc."walker/config.json".text
      && contains "hl.gesture" text
      && contains "kb_options = \"grp:alt_shift_toggle\"" text
      && contains "pamixer" text
      && contains "brightnessctl" text
      && contains "hyprlock" text
      && contains "wlogout" text
      && contains "hyprshot" text
      && contains "workstation-session-menu" text;
    message = "desktop Hyprland config must cover terminal, touchpad gestures, keyboard layout switching, audio, brightness, lock, wlogout, hyprshot, and session menu";
  }
  {
    assertion =
      let
        zen = findPackage "zen-browser" desktop.environment.systemPackages;
      in
      zen != null
      &&
        zen.zenTouchpadPreferences == {
          "apz.gtk.pangesture.enabled" = true;
          "browser.gesture.swipe.left" = "Browser:BackOrBackDuplicate";
          "browser.gesture.swipe.right" = "Browser:ForwardOrForwardDuplicate";
          "browser.history_swipe_animation.disabled" = false;
          "widget.disable-swipe-tracker" = false;
        };
    message = "desktop Zen package must enable native touchpad history gestures";
  }
  {
    assertion =
      let
        isRestartableGraphicalService =
          service:
          service.serviceConfig.Restart == "on-failure"
          && builtins.elem "graphical-session.target" service.wantedBy;
      in
      isRestartableGraphicalService desktop.systemd.user.services.elephant
      && contains "/bin/elephant" desktop.systemd.user.services.elephant.serviceConfig.ExecStart
      && contains "--config /etc/xdg/elephant" desktop.systemd.user.services.elephant.serviceConfig.ExecStart
      && contains "archlinuxpkgs" desktop.environment.etc."xdg/elephant/elephant.toml".text
      && contains "launch_prefix" desktop.environment.etc."xdg/elephant/desktopapplications.toml".text
      && contains "uwsm-app -- " desktop.environment.etc."xdg/elephant/desktopapplications.toml".text
      && isRestartableGraphicalService desktop.systemd.user.services.walker
      && desktop.systemd.user.services.walker.serviceConfig.Type == "dbus"
      && desktop.systemd.user.services.walker.serviceConfig.BusName == "dev.benz.walker"
      && isRestartableGraphicalService desktop.systemd.user.services.mako
      && isRestartableGraphicalService desktop.systemd.user.services."cliphist-text"
      && isRestartableGraphicalService desktop.systemd.user.services."cliphist-image"
      && isRestartableGraphicalService desktop.systemd.user.services.hyprpolkitagent
      && isRestartableGraphicalService desktop.systemd.user.services.udiskie
      && isRestartableGraphicalService desktop.systemd.user.services.wlsunset
      && isRestartableGraphicalService desktop.systemd.user.services.hypridle
      && isRestartableGraphicalService desktop.systemd.user.services.nm-applet;
    message = "desktop session daemons must be restartable graphical-session user services";
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
    assertion = hasPackage "swayosd" desktop.services.udev.packages;
    message = "desktop must install SwayOSD udev rules";
  }
  {
    assertion =
      desktopHome.config.services.swayosd.enable
      && builtins.any (contains "--top-margin 0.900000") desktopHome.config.systemd.user.services.swayosd.Service.ExecStart;
    message = "desktop Home Manager users must run SwayOSD with top margin 0.9";
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
    assertion =
      desktop.programs.nix-ld.enable && !workstation.programs.nix-ld.enable && !vm.programs.nix-ld.enable;
    message = "desktop alone must enable nix-ld compatibility";
  }
  {
    assertion =
      desktop.services.opensnitch.enable
      && desktop.services.opensnitch.settings.DefaultAction == "allow"
      && desktop.services.opensnitch.settings.InterceptUnknown
      && desktop.services.opensnitch.settings.Firewall == "nftables"
      && builtins.hasAttr "opensnitch-ui" desktop.systemd.user.services
      && desktop.systemd.user.services.opensnitch-ui.wantedBy == [ "graphical-session.target" ]
      && desktop.systemd.user.services.opensnitch-ui.partOf == [ "graphical-session.target" ]
      && lib.hasSuffix "opensnitch-ui --background" desktop.systemd.user.services.opensnitch-ui.serviceConfig.ExecStart
      && !workstation.services.opensnitch.enable
      && !vm.services.opensnitch.enable;
    message = "desktop alone must enable interactive OpenSnitch and start its UI service in the background";
  }
  {
    assertion =
      desktop.services.clamav.updater.enable
      && !desktop.services.clamav.daemon.enable
      && !desktop.services.clamav.scanner.enable
      && !desktop.services.clamav.clamonacc.enable
      && !workstation.services.clamav.updater.enable
      && !vm.services.clamav.updater.enable;
    message = "desktop alone must enable ClamAV signature updates without persistent scanning services";
  }
  {
    assertion =
      desktop.services.usbguard.enable
      && desktop.services.usbguard.implicitPolicyTarget == "block"
      && desktop.services.usbguard.presentDevicePolicy == "allow"
      && !workstation.services.usbguard.enable
      && !vm.services.usbguard.enable;
    message = "desktop alone must enable USBGuard with a default-block policy for newly plugged devices";
  }
  {
    assertion =
      desktop.systemd.timers.lynis-audit.wantedBy == [ "timers.target" ]
      && desktop.systemd.services.lynis-audit.serviceConfig.Type == "oneshot";
    message = "desktop must run Lynis as a periodic on-demand audit, not a persistent daemon";
  }
  {
    assertion =
      let
        tools = [
          "clamav"
          "yara"
          "lynis"
          "mat2"
          "opensnitch-ui"
          "nethogs"
          "nvtop"
        ];
        absentFrom = packages: builtins.all (name: !(hasPackage name packages)) tools;
      in
      absentFrom workstation.environment.systemPackages && absentFrom vm.environment.systemPackages;
    message = "desktop security and monitoring tools must not leak into workstation or vm";
  }
  {
    assertion = desktop.virtualisation.docker.enable;
    message = "desktop must enable Docker";
  }
  {
    assertion = desktop.virtualisation.podman.enable;
    message = "desktop must enable Podman";
  }
  {
    assertion = desktop.virtualisation.libvirtd.enable;
    message = "desktop must enable libvirtd";
  }
  {
    assertion = desktop.programs.virt-manager.enable;
    message = "desktop must enable virt-manager";
  }
  {
    assertion =
      desktop.programs.wireshark.enable
      && packageName desktop.programs.wireshark.package == "wireshark-qt";
    message = "desktop must enable Wireshark packet capture with the full GUI package";
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
    assertion =
      findPackage "nvtop" desktop.environment.systemPackages
      == self.nixosConfigurations.desktop.pkgs.nvtopPackages.full;
    message = "desktop must use full multi-vendor nvtop";
  }
  {
    assertion =
      findPackage "neovim" desktop.environment.systemPackages == unstablePkgs.neovim
      && findPackage "helix" desktop.environment.systemPackages == unstablePkgs.helix
      && findPackage "vscode" desktop.environment.systemPackages == unstablePkgs.vscode
      && findPackage "zed-editor" desktop.environment.systemPackages == unstablePkgs.zed-editor;
    message = "desktop must use editors from nixpkgs-unstable";
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
      && !(builtins.elem "dolphin" names)
      && !(builtins.elem "rofi" names);
    message = "desktop must not include Waybar, EWW, Nautilus, Dolphin, or Rofi as baseline";
  }
]
