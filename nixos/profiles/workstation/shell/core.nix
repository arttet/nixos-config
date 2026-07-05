{
  pkgs,
  unstablePkgs,
  lib,
  ...
}:
{
  programs.zsh.enable = lib.mkDefault true;

  environment.systemPackages = [
    pkgs.zsh
    pkgs.nushell
    pkgs.starship
    pkgs.fastfetch
    pkgs.carapace
    unstablePkgs.tmux
  ];
}
