{
  config,
  pkgs,
  lib,
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
    pkgs.hyprpaper
    pkgs.hyprlock
    pkgs.hyprpicker
    sessionMenu
  ];

  environment.etc."xdg/hypr/hyprland.lua".text = ''
    -- Minimal platform fallback. Personal Hyprland config belongs to dotfiles.
    -- This file provides operational defaults only.

    local mod = "SUPER"

    local function app(cmd)
        return "${uwsm} app -- " .. cmd
    end

    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = 1,
    })

    hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
    hl.env("XDG_SESSION_DESKTOP", "Hyprland")
    hl.env("XDG_SESSION_TYPE", "wayland")

    hl.on("hyprland.start", function()
        hl.exec_cmd("uwsm finalize")
        hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
        hl.exec_cmd("systemctl --user restart elephant.service walker.service")
    end)

    hl.config({
        input = {
            kb_layout = "us,ru",
            kb_options = "grp:alt_shift_toggle",
            follow_mouse = 1,
            touchpad = {
                natural_scroll = true,
            },
        },
        general = {
            gaps_in = 4,
            gaps_out = 8,
            border_size = 2,
        },
        decoration = {
            rounding = 6,
        },
    })

    hl.gesture({
        fingers = 3,
        direction = "horizontal",
        action = "workspace",
    })

    hl.bind(mod .. " + Return", hl.dsp.exec_cmd(app("ghostty")))
    hl.bind(mod .. " + R", hl.dsp.exec_cmd(app("walker")))
    hl.bind(mod .. " + B", hl.dsp.exec_cmd(app("zen")))
    hl.bind(mod .. " + E", hl.dsp.exec_cmd(app("thunar")))
    hl.bind(mod .. " + A", hl.dsp.exec_cmd(app("pavucontrol")))
    hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd(app("ghostty -e yazi")))
    hl.bind(mod .. " + Q", hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
    hl.bind(mod .. " + L", hl.dsp.exec_cmd(app("hyprlock")))
    hl.bind(mod .. " + Backspace", hl.dsp.exec_cmd(app("wlogout")))
    hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd(app("workstation-session-menu")))

    for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

    hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(app("hyprshot -m region --clipboard")))
    hl.bind("Print", hl.dsp.exec_cmd(app("hyprshot -m output --clipboard")))
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
    app_launch_prefix = "${uwsm} app -- ";
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
