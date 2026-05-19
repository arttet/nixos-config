{
  home-manager,
  lib,
  userHome,
  userName,
  userSources,
  ...
}:
{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${userName} = {
    home.username = userName;
    home.homeDirectory = userHome;
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;

    home.file = lib.optionalAttrs (userSources ? dotfiles) {
      ".config".source = "${userSources.dotfiles}/.config";
      ".zshrc".source = "${userSources.dotfiles}/.zshrc";
    };
  };
}
