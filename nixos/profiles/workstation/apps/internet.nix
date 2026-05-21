{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.cloudflare-warp
    pkgs.impala
    pkgs.transmission_4-gtk
    pkgs.yandex-disk
  ];
}
