{ ... }:
{
  imports = [
    ../../profiles/homelab-rpi5.nix
  ];
  sdImage.expandOnBoot = true;
}
