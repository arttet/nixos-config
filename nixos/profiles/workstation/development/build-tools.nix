{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.mold
    pkgs.sccache
  ];
}
