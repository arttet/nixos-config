{ pkgs, unstablePkgs, ... }:
{
  environment.systemPackages = [
    pkgs.yazi
    pkgs.superfile
    pkgs.lazygit
    pkgs.lazydocker
    unstablePkgs.zellij
    unstablePkgs.herdr
    pkgs.btop
    pkgs.nvtopPackages.full
    pkgs.bpftop
    pkgs.gh-dash
  ];
}
