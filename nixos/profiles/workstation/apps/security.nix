{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.gnupg
    pkgs.keepassxc
    pkgs.proton-pass
    pkgs.veracrypt
  ];
}
