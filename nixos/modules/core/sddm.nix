{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.sddm;
  cursorPackage = pkgs.catppuccin-cursors.mochaBlue;
  cursorName = "catppuccin-mocha-blue-cursors";
in
{
  options.platform.sddm.enable = lib.mkEnableOption "SDDM Wayland login manager";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.greetd.enable;
        message = "platform.sddm cannot be enabled together with greetd";
      }
      {
        assertion = config.programs.uwsm.enable;
        message = "platform.sddm requires programs.uwsm.enable = true";
      }
    ];

    services.displayManager = {
      defaultSession = "hyprland-uwsm";
      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm;
        theme = "sddm-astronaut-theme";
        extraPackages = [ pkgs.sddm-astronaut ];
        settings = {
          General.GreeterEnvironment = lib.concatStringsSep "," [
            "QT_WAYLAND_SHELL_INTEGRATION=layer-shell"
            "XCURSOR_PATH=${cursorPackage}/share/icons"
            "XCURSOR_SIZE=24"
            "XCURSOR_THEME=${cursorName}"
          ];
          Theme = {
            CursorTheme = cursorName;
            CursorSize = 24;
          };
        };
        wayland = {
          enable = true;
          compositor = "kwin";
        };
      };
    };

    systemd.services.display-manager.environment = {
      XCURSOR_PATH = "${cursorPackage}/share/icons";
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = cursorName;
    };

    environment.systemPackages = [
      cursorPackage
      pkgs.sddm-astronaut
    ];
  };
}
