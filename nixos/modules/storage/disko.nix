{ config, lib, ... }:
let
  cfg = config.platform.storage;

  workstationDiskLayout = {
    disk.workstation = {
      type = "disk";
      device = cfg.diskDevice;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
              ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
in
{
  options.platform.storage = {
    enable = lib.mkEnableOption "the workstation storage layout";

    diskDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/disk/by-id/nvme-example";
      description = "Disk device to use for the workstation storage layout.";
    };

    diskoLayout = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Generated disko-compatible workstation disk layout.";
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.enable || cfg.diskDevice != null;
        message = "platform.storage.diskDevice must be set when platform.storage.enable is true.";
      }
    ];

    platform.storage.diskoLayout = lib.mkIf cfg.enable workstationDiskLayout;
  };
}
