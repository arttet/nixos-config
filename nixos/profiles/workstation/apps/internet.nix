{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.cloudflare-warp
    pkgs.transmission_4-gtk
    pkgs.yandex-disk
  ];
}
