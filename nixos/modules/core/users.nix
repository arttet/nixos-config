{ lib, ... }:
{
  users.users.void = {
    isNormalUser = false;
    isSystemUser = true;
    group = "nogroup";
    home = lib.mkForce "/var/empty";
    createHome = false;
    shell = lib.mkForce null;
    extraGroups = [ ];
  };
}
