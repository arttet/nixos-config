{ pkgs, lib, ... }:
{
  users.users.user = {
    isNormalUser = true;
    description = "User";
    shell = pkgs.nushell;
    hashedPasswordFile = "/etc/nixos/local/users/user.passwd";
    extraGroups = [ "wheel" ];
  };
}
