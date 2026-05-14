{ config, lib, ... }:
let
  cfg = config.platform.storage;
in
{
  options.platform.storage = {
    swapFilePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/swapfile";
      description = "Path to the swapfile used by workstation-style installs.";
    };

    swapSizeMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8192;
      example = 16384;
      description = "Swapfile size in MiB.";
    };
  };

  config.swapDevices = lib.mkIf cfg.enable [
    {
      device = cfg.swapFilePath;
      size = cfg.swapSizeMiB;
    }
  ];
}
