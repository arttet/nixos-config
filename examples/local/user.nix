{ pkgs, lib, ... }:
{
  networking.hostName = lib.mkDefault "workstation-local";
  time.timeZone = lib.mkDefault "Etc/UTC";

  users.users.example = {
    isNormalUser = true;
    home = "/home/example";
    shell = pkgs.nushell;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "<fake-ssh-public-key>"
    ];
  };
}
