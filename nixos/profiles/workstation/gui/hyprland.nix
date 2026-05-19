{ pkgs, lib, ... }:
let
  sessionMenu = pkgs.writeTextFile {
    name = "workstation-session-menu";
    executable = true;
    destination = "/bin/workstation-session-menu";
    text = ''
      #!${lib.getExe pkgs.nushell}

      let action = ["lock" "logout" "reboot" "shutdown"] | str join "\n" | ^rofi -dmenu -p "session"

      match $action {
        "lock" => { ^hyprlock }
        "logout" => { ^hyprctl dispatch exit }
        "reboot" => { ^systemctl reboot }
        "shutdown" => { ^systemctl poweroff }
        _ => { null }
      }
    '';
  };
in
{
  programs.hyprland = {
    enable = lib.mkDefault true;
    xwayland.enable = lib.mkDefault true;
  };

  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-hyprland
  ];

  environment.systemPackages = [
    pkgs.hyprland
    pkgs.hyprpaper
    pkgs.hypridle
    pkgs.hyprlock
    pkgs.hyprpicker
    pkgs.xdg-desktop-portal-hyprland
    sessionMenu
  ];

  environment.etc."xdg/hypr/hyprland.conf".text = ''
    # Minimal platform fallback. Personal Hyprland config belongs to dotfiles.
    # This file provides operational defaults only.
    monitor=,preferred,auto,1

    exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once=systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    exec-once=mako
    exec-once=wl-paste --type text --watch cliphist store
    exec-once=wl-paste --type image --watch cliphist store
    exec-once=hypridle
    exec-once=udiskie --tray

    env = XDG_CURRENT_DESKTOP,Hyprland
    env = XDG_SESSION_DESKTOP,Hyprland
    env = XDG_SESSION_TYPE,wayland

    input {
      kb_layout = us
      follow_mouse = 1
      touchpad {
        natural_scroll = yes
      }
    }

    general {
      gaps_in = 4
      gaps_out = 8
      border_size = 2
    }

    decoration {
      rounding = 6
    }

    bind = SUPER, Return, exec, ghostty || alacritty || wezterm
    bind = SUPER, D, exec, rofi -show drun
    bind = SUPER, B, exec, zen || zen-browser || brave || google-chrome-stable || tor-browser
    bind = SUPER, E, exec, thunar
    bind = SUPER, A, exec, pavucontrol
    bind = SUPER SHIFT, E, exec, ghostty -e yazi || alacritty -e yazi || wezterm start yazi
    bind = SUPER, Q, killactive
    bind = SUPER SHIFT, R, exec, hyprctl reload
    bind = SUPER, L, exec, hyprlock
    bind = SUPER SHIFT, P, exec, workstation-session-menu

    bind = SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
    bind = SUPER, Print, exec, dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")" && mkdir -p "$dir" && grim -g "$(slurp)" "$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
    bind = , Print, exec, dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")" && mkdir -p "$dir" && grim "$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"

    bind = SUPER, 1, workspace, 1
    bind = SUPER, 2, workspace, 2
    bind = SUPER, 3, workspace, 3
    bind = SUPER, 4, workspace, 4
    bind = SUPER, 5, workspace, 5
    bind = SUPER, 6, workspace, 6
    bind = SUPER, 7, workspace, 7
    bind = SUPER, 8, workspace, 8
    bind = SUPER, 9, workspace, 9
    bind = SUPER, 0, workspace, 10
    bind = SUPER SHIFT, 1, movetoworkspace, 1
    bind = SUPER SHIFT, 2, movetoworkspace, 2
    bind = SUPER SHIFT, 3, movetoworkspace, 3
    bind = SUPER SHIFT, 4, movetoworkspace, 4
    bind = SUPER SHIFT, 5, movetoworkspace, 5
    bind = SUPER SHIFT, 6, movetoworkspace, 6
    bind = SUPER SHIFT, 7, movetoworkspace, 7
    bind = SUPER SHIFT, 8, movetoworkspace, 8
    bind = SUPER SHIFT, 9, movetoworkspace, 9
    bind = SUPER SHIFT, 0, movetoworkspace, 10

    bindel = , XF86AudioRaiseVolume, exec, pamixer -i 5
    bindel = , XF86AudioLowerVolume, exec, pamixer -d 5
    bindel = , XF86AudioMute, exec, pamixer -t
    bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
    bindl = , XF86AudioPlay, exec, playerctl play-pause
    bindl = , XF86AudioNext, exec, playerctl next
    bindl = , XF86AudioPrev, exec, playerctl previous
  '';

  environment.etc."xdg/hypr/hypridle.conf".text = ''
    general {
      lock_cmd = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
      timeout = 300
      on-timeout = loginctl lock-session
    }

    listener {
      timeout = 600
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on
    }
  '';

  environment.etc."xdg/hypr/hyprlock.conf".text = ''
    background {
      color = rgb(111111)
    }

    input-field {
      size = 280, 56
      position = 0, -40
      halign = center
      valign = center
    }
  '';
}
