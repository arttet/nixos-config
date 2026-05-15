{ pkgs, lib, ... }:
{
  virtualisation.docker.enable = lib.mkDefault true;

  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.docker-buildx
  ];
}
