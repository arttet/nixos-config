# modules/services/xray.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.xray;
in
{
  options.services.xray = {
    enable = mkEnableOption "xray";
    settingsFile = mkOption {
      type = types.path;
      description = "Path to xray config JSON";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.xray = {
      description = "Xray Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.xray}/bin/xray -config ${cfg.settingsFile}";
        Restart = "on-failure";
        User = "xray";
        Group = "xray";
        AmbientCapabilities = [
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_ADMIN"
        ];
        CapabilityBoundingSet = [
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_ADMIN"
        ];
      };
    };

    users.users.xray = {
      isSystemUser = true;
      group = "xray";
    };
    users.groups.xray = { };
  };
}
