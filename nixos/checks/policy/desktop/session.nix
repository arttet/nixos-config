{
  desktop,
  workstation,
  vm,
  contains,
  desktopHome,
  hasPackage,
  packageName,
  ...
}:
[
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
]
