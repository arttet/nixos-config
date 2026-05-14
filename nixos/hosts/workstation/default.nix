{ lib, ... }:
{
  imports = [
    ../../profiles/workstation.nix
  ];

  networking.hostName = "workstation";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub.devices = lib.mkDefault [ "nodev" ];
}
