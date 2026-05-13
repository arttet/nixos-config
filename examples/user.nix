{ pkgs, ... }:
{
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
