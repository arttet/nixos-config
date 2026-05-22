{ lib, ... }:
{
  # Keep a committed non-login placeholder; real users come from platform.state.
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
