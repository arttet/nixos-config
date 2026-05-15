{ config, lib, ... }:
let
  cfg = config.platform.bootUx;
in
{
  options.platform.bootUx = {
    enable = lib.mkEnableOption "graphical boot UX for workstation-class systems";
  };

  config = lib.mkIf cfg.enable {
    boot.plymouth.enable = lib.mkDefault true;
  };
}
