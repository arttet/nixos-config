{ pkgs, lib, ... }:
let
  userName = "user";
  userDescription = "User";
  userHome = "/home/${userName}";
  userSources = null;
  # userSources =
  #   let
  #     dotfiles = ${userHome}/.dotfiles;
  #   in
  #   {
  #     inherit dotfiles;
  #     dotfilesModule = dotfiles + "/nixos/home.nix";
  #     dotfilesRoot = dotfiles + "/dotfiles";
  #   };
in
{
  imports = lib.optional (userSources != null) ./${userName}/dotfiles.nix;

  _module.args = {
    inherit
      userDescription
      userHome
      userName
      userSources
      ;
  };

  users.users.${userName} = {
    isNormalUser = true;
    description = userDescription;
    shell = pkgs.nushell;
    hashedPasswordFile = "/etc/nixos/local/users/${userName}/${userName}.passwd";
    extraGroups = [ "wheel" ];
  };
}
