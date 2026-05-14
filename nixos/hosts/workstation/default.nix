{ lib, ... }:
{
  imports = [
    ../../profiles/workstation.nix
  ];

  networking.hostName = "workstation";

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
