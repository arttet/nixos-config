{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.greetd;
  tuigreet = if builtins.hasAttr "tuigreet" pkgs then pkgs.tuigreet else pkgs.greetd.tuigreet;
  uwsm = lib.getExe config.programs.uwsm.package;
in
{
  options.platform.greetd.enable = lib.mkEnableOption "greetd with the tuigreet fallback";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.displayManager.sddm.enable;
        message = "platform.greetd cannot be enabled together with SDDM";
      }
      {
        assertion = config.programs.uwsm.enable;
        message = "platform.greetd requires programs.uwsm.enable = true";
      }
    ];

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${lib.getExe tuigreet} --time --remember --cmd '${uwsm} start hyprland-uwsm.desktop'";
        user = "greeter";
      };
    };
  };
}
