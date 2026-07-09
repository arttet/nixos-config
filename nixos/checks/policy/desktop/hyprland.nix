{
  desktop,
  contains,
  findPackage,
  ...
}:
[
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
]
