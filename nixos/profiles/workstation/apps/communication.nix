{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.protonmail-desktop
    pkgs.telegram-desktop
    pkgs.zoom-us
  ];
}
