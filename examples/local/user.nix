{ pkgs, lib, ... }:
{
  networking.hostName = lib.mkDefault "workstation-local";
  time.timeZone = lib.mkDefault "Etc/UTC";

  users.users.example = {
    isNormalUser = true;
    shell = pkgs.nushell;
    extraGroups = [ "wheel" ];
  };
}
