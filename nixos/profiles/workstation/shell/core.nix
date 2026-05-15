{ pkgs, lib, ... }:
{
  programs.zsh.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    zsh
    nushell
    starship
    tmux
    fastfetch
  ];
}
