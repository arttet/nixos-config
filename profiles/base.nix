# profiles/base.nix
{ pkgs, lib, ... }:
{
  imports = [
    ../modules/core/users.nix
    ../modules/core/agent-user.nix
  ];

  networking.hostName = lib.mkDefault "nixos";
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    nushell
  ];

  services.openssh.enable = true;
  networking.firewall.enable = true;

  # Default values for agent user
  mySystem.agentUser.name = lib.mkDefault null;

  system.stateVersion = "23.11";
}
