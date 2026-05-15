{ lib, ... }:
{
  services.upower.enable = lib.mkDefault true;
}
