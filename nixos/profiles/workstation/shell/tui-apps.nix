{ pkgs, unstablePkgs, ... }:
{
  environment.systemPackages = [
    pkgs.yazi
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.zellij
    unstablePkgs.herdr
    pkgs.btop
    pkgs.nvtopPackages.full
  ];
}
