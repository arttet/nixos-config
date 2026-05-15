{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fzf
    ripgrep
    fd
    bat
    eza
    zoxide
  ];
}
