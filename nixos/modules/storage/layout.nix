{
  diskDevice,
  luksPasswordFile ? null,
}:
let
  btrfsMountOptions = [
    "compress=zstd"
    "noatime"
    "discard=async"
  ];

  luksContent = {
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
  }
  // (
    if luksPasswordFile == null then
      { }
    else
      {
        passwordFile = luksPasswordFile;
      }
  );
in
{
  disk.workstation = {
    type = "disk";
    device = diskDevice;
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
          content = luksContent;
        };
      };
    };
  };
}
