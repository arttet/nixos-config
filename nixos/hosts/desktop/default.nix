{ lib, ... }:
{
  imports = [
    ../../profiles/workstation
  ];

  networking.hostName = "workstation";

  platform.grubTheme.variant = "nord";

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
