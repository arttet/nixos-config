{
  home-manager,
  lib,
  userHome,
  userName,
  userSources,
  ...
}:
let
  dotfiles = userSources.dotfiles or null;
  dotfilesModule = userSources.dotfilesModule;
  dotfilesRoot = userSources.dotfilesRoot;
  hasDotfilesModule = dotfilesModule != null && builtins.pathExists dotfilesModule;
  hasDotfilesRoot = dotfilesRoot != null && builtins.pathExists dotfilesRoot;
in
{
  imports = [
    home-manager.nixosModules.home-manager
  ]
  ++ lib.optional hasDotfilesModule dotfilesModule;

  assertions = lib.optional (!hasDotfilesModule) {
    assertion = hasDotfilesRoot;
    message = "userSources.dotfilesRoot must point to the directory that contains dotfiles, or userSources.dotfilesModule must point to a Nix module";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.${userName} = {
    home.username = userName;
    home.homeDirectory = userHome;
    home.stateVersion = "25.11";
    home.enableNixpkgsReleaseCheck = false;

    programs.home-manager.enable = true;

    home.file = lib.optionalAttrs (!hasDotfilesModule && hasDotfilesRoot) {
      ".config/alacritty".source = dotfilesRoot + "/.config/alacritty";
      ".config/bash".source = dotfilesRoot + "/.config/bash";
      ".config/fastfetch".source = dotfilesRoot + "/.config/fastfetch";
      ".config/nushell" = {
        source = dotfilesRoot + "/.config/nushell";
        force = true;
      };
      ".config/nvim".source = dotfilesRoot + "/.config/nvim";
      ".config/shell".source = dotfilesRoot + "/.config/shell";
      ".config/starship".source = dotfilesRoot + "/.config/starship";
      ".config/tmux".source = dotfilesRoot + "/.config/tmux";
      ".config/wezterm".source = dotfilesRoot + "/.config/wezterm";
      ".config/yazi".source = dotfilesRoot + "/.config/yazi";
      ".config/zsh".source = dotfilesRoot + "/.config/zsh";
      ".zshrc".source = dotfilesRoot + "/.zshrc";
    };
  };
}
