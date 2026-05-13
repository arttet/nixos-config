{ pkgs, lib, ... }:
{
  imports = [
    ../modules/core/users.nix
    ../modules/core/local-overlay.nix
  ];

  networking.hostName = lib.mkDefault "nixos";
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    curl
    gitMinimal
    iputils
    just
    nushell
    vim
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  networking.firewall.enable = true;

  system.stateVersion = "25.05";
}
