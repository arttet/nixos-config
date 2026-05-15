{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.imv
    pkgs.vlc
  ];
}
