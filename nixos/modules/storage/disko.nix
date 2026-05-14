{ config, lib, ... }:
let
  cfg = config.platform.storage;
  btrfsMountOptions = [
    "compress=zstd"
    "noatime"
    "discard=async"
  ];

  workstationDiskLayout = {
    disk.workstation = {
      type = "disk";
      device = cfg.diskDevice;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = [
                "umask=0077"
              ];
            };
          };

          boot = {
            size = "512M";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/boot";
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              extraFormatArgs = [
                "--type"
                "luks2"
              ];
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = btrfsMountOptions;
                  };

                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = btrfsMountOptions;
                  };

                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = btrfsMountOptions;
                  };

                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = btrfsMountOptions;
                  };

                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = btrfsMountOptions;
                  };
                };
              };
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
    disko.devices = lib.mkIf cfg.enable workstationDiskLayout;
  };
}
