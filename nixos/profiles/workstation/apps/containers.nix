{ pkgs, lib, ... }:
{
  virtualisation.docker.enable = lib.mkDefault true;

  systemd.services.containerd.wantedBy = lib.mkForce [ ];
  systemd.services.docker.wantedBy = lib.mkForce [ ];
  systemd.sockets.docker.wantedBy = lib.mkForce [ ];

  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.docker-buildx
  ];
}
