{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.protonmail-desktop
    pkgs.telegram-desktop
    pkgs.thunderbird
    pkgs.zoom-us
  ];
}
