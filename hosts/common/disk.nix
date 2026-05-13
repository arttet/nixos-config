# hosts/common/disk.nix
{ lib, ... }:
{
  disko.devices.disk.main = lib.mkDefault {
    type = "disk";
    # Default device, can be overridden in host config
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            # Low priority for mountpoint to let generators win
            mountpoint = lib.mkDefault "/";
          };
        };
      };
    };
  };

  swapDevices = lib.mkDefault [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];
}
