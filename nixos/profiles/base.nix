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

  users.users.root.hashedPassword = "!";

  system.stateVersion = "25.11";
}
