{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.yazi
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.zellij
    pkgs.btop
  ];
}
