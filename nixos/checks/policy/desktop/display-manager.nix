{
  workstation,
  desktop,
  packageName,
  contains,
  hasPackage,
  ...
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
      desktop.platform.virtualConsole.enable
      && desktop.services.kmscon.enable
      && desktop.services.kmscon.hwRender
      && desktop.services.kmscon.useXkbConfig
      && desktop.services.kmscon.term == "xterm-256color"
      && contains "font-size=16" desktop.services.kmscon.extraConfig
      && builtins.length desktop.services.kmscon.fonts == 1
      && (builtins.head desktop.services.kmscon.fonts).name == "IosevkaTerm Nerd Font";
    message = "desktop must enable kmscon with IosevkaTerm Nerd Font";
  }
  {
    assertion =
      builtins.elem "kmsconvt@tty1.service" desktop.systemd.targets.getty.wants
      && builtins.elem "kmsconvt@tty1.service" desktop.systemd.services.display-manager.after
      && contains "/bin/sleep 1" (
        toString desktop.systemd.services."kmsconvt@".serviceConfig.ExecStartPost
      )
      && desktop.systemd.services.display-manager.conflicts == [ ];
    message = "desktop must wait for kmscon to reserve tty1 before SDDM allocates its VT";
  }
]
