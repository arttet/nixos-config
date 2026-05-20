{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    yazi
    lazygit
    lazydocker
    zellij
    btop
  ];
}
