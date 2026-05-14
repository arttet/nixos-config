{ lib, ... }:
{
  imports = [
    ../modules/core/users.nix
    ../modules/core/local-overlay.nix
  ];

  networking.hostName = lib.mkDefault "nixos";
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  networking.firewall.enable = true;

  system.stateVersion = "25.05";
}
