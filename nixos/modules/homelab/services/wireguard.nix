{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.wireguard) {
    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
