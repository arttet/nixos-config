{
  config,
  pkgs,
  lib,
  walker,
  ...
}:
let
  sessionMenu = pkgs.writeTextFile {
    name = "workstation-session-menu";
    executable = true;
    destination = "/bin/workstation-session-menu";
    text = ''
      #!${lib.getExe pkgs.nushell}

      let action = ["lock" "logout" "reboot" "shutdown"] | str join "\n" | ^walker -d -p "session"

      match $action {
        "lock" => { ^hyprlock }
        "logout" => { ^uwsm stop }
        "reboot" => { ^systemctl reboot }
        "shutdown" => { ^systemctl poweroff }
        _ => { null }
      }
    '';
  };
  uwsm = lib.getExe config.programs.uwsm.package;
  tuigreet = if builtins.hasAttr "tuigreet" pkgs then pkgs.tuigreet else pkgs.greetd.tuigreet;
in
{
  programs.hyprland = {
    enable = lib.mkDefault true;
    withUWSM = lib.mkDefault true;
    xwayland.enable = lib.mkDefault true;
  };

  programs.uwsm = {
    enable = lib.mkDefault true;
    waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/start-hyprland";
    };
  };

  xdg.portal = {
    configPackages = [ pkgs.hyprland ];
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  services.greetd.settings.default_session.command =
    lib.mkForce "${lib.getExe tuigreet} --time --remember --cmd '${uwsm} start hyprland-uwsm.desktop'";

  environment.systemPackages = [
    walker.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.elephant
    pkgs.hyprpaper
    pkgs.hypridle
    pkgs.hyprlock
    pkgs.hyprpicker
    pkgs.hyprpolkitagent
    pkgs.networkmanagerapplet
    sessionMenu
  ];

  systemd.user.services.elephant = {
    description = "Elephant data provider service for Walker";
    partOf = [ "graphical-session.target" ];
    environment = {
      PATH = lib.mkForce (
        lib.makeBinPath [ pkgs.bash ] + ":/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
      );
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe pkgs.elephant;
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  systemd.user.services.walker = {
    description = "Walker Launcher Service";
    requires = [ "elephant.service" ];
    after = [ "elephant.service" ];
    partOf = [ "graphical-session.target" ];
    environment = {
      PATH = lib.mkForce "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${
        lib.getExe walker.packages.${pkgs.stdenv.hostPlatform.system}.default
      } --gapplication-service";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  systemd.user.targets.graphical-session.wants = [
    "elephant.service"
    "walker.service"
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
    exec-once=hyprpolkitagent
    exec-once=hypridle
    exec-once=udiskie --tray
    exec-once=nm-applet --indicator
    exec-once=wlsunset -t 5000 -T 6500

    env = XDG_CURRENT_DESKTOP,Hyprland
    env = XDG_SESSION_DESKTOP,Hyprland
    env = XDG_SESSION_TYPE,wayland

    input {
      kb_layout = us,ru
      kb_options = grp:alt_shift_toggle
      follow_mouse = 1
      touchpad {
        natural_scroll = yes
      }
    }

    gesture = 3, horizontal, workspace

    general {
      gaps_in = 4
      gaps_out = 8
      border_size = 2
    }

    decoration {
      rounding = 6
    }

    bind = SUPER, Return, exec, ghostty
    bind = SUPER, R, exec, walker
    bind = SUPER, B, exec, zen
    bind = SUPER, E, exec, thunar
    bind = SUPER, A, exec, pavucontrol
    bind = SUPER SHIFT, E, exec, ghostty -e yazi
    bind = SUPER, Q, killactive
    bind = SUPER SHIFT, R, exec, hyprctl reload
    bind = SUPER, L, exec, hyprlock
    bind = SUPER, Backspace, exec, wlogout
    bind = SUPER SHIFT, P, exec, workstation-session-menu

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

    bind = SUPER SHIFT, S, exec, hyprshot -m region --clipboard
    bind = , Print, exec, hyprshot -m output --clipboard
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

  environment.etc."wlogout/layout".text = ''
    {
      "label" : "lock",
      "action" : "hyprlock",
      "text" : "Lock",
      "keybind" : "l"
    }
    {
      "label" : "logout",
      "action" : "uwsm stop",
      "text" : "Logout",
      "keybind" : "e"
    }
    {
      "label" : "reboot",
      "action" : "systemctl reboot",
      "text" : "Reboot",
      "keybind" : "r"
    }
    {
      "label" : "shutdown",
      "action" : "systemctl poweroff",
      "text" : "Shutdown",
      "keybind" : "s"
    }
  '';

  environment.etc."walker/config.json".text = builtins.toJSON {
    app = {
      show_icon_when_single = true;
      show_sub_when_single = true;
    };
    list = {
      max_entries = 50;
      show_initial_entries = true;
    };
    search = {
      placeholder = "Search...";
    };
    builtins = {
      applications = {
        weight = 5;
      };
      clipboard = {
        weight = 3;
      };
      commands = {
        weight = 1;
      };
      emojis = {
        weight = 2;
      };
      switcher = {
        weight = 0;
      };
      custom = [
        {
          name = "session";
          placeholder = "Session...";
          cmd = "printf 'lock\nlogout\nreboot\nshutdown'";
          weight = 0;
        }
      ];
    };
    modules = [ ];
    activation_mode = {
      disabled = false;
    };
    ignore_mouse = false;
  };
}
