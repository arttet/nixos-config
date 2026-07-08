{
  desktop,
  workstation,
  vm,
  lib,
  hasPackage,
  packageName,
  ...
}:
[
  {
    assertion = desktop.boot.kernel.sysctl."user.max_user_namespaces" > 0;
    message = "desktop must allow browser sandbox user namespaces";
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
    assertion =
      desktop.programs.wireshark.enable
      && packageName desktop.programs.wireshark.package == "wireshark-qt";
    message = "desktop must enable Wireshark packet capture with the full GUI package";
  }
]
