{ pkgs, yazi, ... }:
{
  environment.systemPackages = [
    yazi.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.zellij
    pkgs.btop
  ];
}
