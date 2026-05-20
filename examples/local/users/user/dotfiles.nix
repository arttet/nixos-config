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
  dotfilesModule = userSources.dotfilesModule or null;
  dotfilesRoot = userSources.dotfilesRoot or null;

  hasDotfilesModule = dotfilesModule != null && builtins.pathExists dotfilesModule;
  hasDotfilesRoot = dotfilesRoot != null && builtins.pathExists dotfilesRoot;
in
{
  imports = [
    home-manager.nixosModules.home-manager
  ];

  assertions =
    lib.optional (!hasDotfilesModule) {
      assertion = hasDotfilesRoot;
      message = "userSources.dotfilesRoot must point to the directory that contains dotfiles, or userSources.dotfilesModule must point to a Nix module";
    }
    ++ lib.optional (!(userSources ? dotfiles) || dotfiles == null) {
      assertion = false;
      message = "userSources.dotfiles must point to an existing dotfiles repository";
    }
    ++ lib.optional (dotfiles != null) {
      assertion = builtins.pathExists dotfiles;
      message = "userSources.dotfiles must point to an existing dotfiles repository";
    }
    ++ lib.optional (dotfilesModule != null) {
      assertion = builtins.pathExists dotfilesModule;
      message = "userSources.dotfilesModule must point to an existing Nix module";
    }
    ++ lib.optional (dotfilesRoot != null) {
      assertion = builtins.pathExists dotfilesRoot;
      message = "userSources.dotfilesRoot must point to an existing dotfiles directory";
    };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.sharedModules =
    lib.optional hasDotfilesModule dotfilesModule
    ++ lib.optional (!hasDotfilesModule && hasDotfilesRoot) (
      { config, ... }:
      let
        link = config.lib.file.mkOutOfStoreSymlink;
      in
      {
        home.file = {
          ".config/alacritty".source = link (dotfilesRoot + "/.config/alacritty");
          ".config/bash".source = link (dotfilesRoot + "/.config/bash");
          ".config/fastfetch".source = link (dotfilesRoot + "/.config/fastfetch");
          ".config/nushell" = {
            source = link (dotfilesRoot + "/.config/nushell");
            force = true;
          };
          ".config/nvim".source = link (dotfilesRoot + "/.config/nvim");
          ".config/shell".source = link (dotfilesRoot + "/.config/shell");
          ".config/starship".source = link (dotfilesRoot + "/.config/starship");
          ".config/tmux".source = link (dotfilesRoot + "/.config/tmux");
          ".config/wezterm".source = link (dotfilesRoot + "/.config/wezterm");
          ".config/yazi".source = link (dotfilesRoot + "/.config/yazi");
          ".config/zsh".source = link (dotfilesRoot + "/.config/zsh");
          ".zshrc".source = link (dotfilesRoot + "/.zshrc");
        };
      }
    );
  home-manager.extraSpecialArgs = {
    inherit dotfilesRoot userSources;
  };

  home-manager.users.${userName} = {
    home.username = userName;
    home.homeDirectory = userHome;
    home.stateVersion = "25.11";
    home.enableNixpkgsReleaseCheck = false;

    programs.home-manager.enable = true;
  };
}
