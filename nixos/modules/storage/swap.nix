{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.storage;
in
{
  options.platform.storage = {
    swapFilePath = lib.mkOption {
      type = lib.types.str;
      default = "/swap/swapfile";
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

  config.systemd.services.prepare-btrfs-swap = lib.mkIf cfg.enable {
    description = "Prepare Btrfs NOCOW directory for swapfile";
    before = [ "swap-swapfile.swap" ];
    wantedBy = [ "swap-swapfile.swap" ];
    path = [
      pkgs.coreutils
      pkgs.e2fsprogs
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /swap
      chattr +C /swap || true
    '';
  };
}
