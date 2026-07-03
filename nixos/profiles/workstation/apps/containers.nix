{ pkgs, lib, ... }:
{
  # Docker is installed but not auto-started. Start the socket manually
  # when you want to use Docker.
  #   doas systemctl start docker.socket
  virtualisation.docker.enable = lib.mkDefault true;
  systemd.services.containerd.wantedBy = lib.mkForce [ ];
  systemd.services.docker.wantedBy = lib.mkForce [ ];
  systemd.sockets.docker.wantedBy = lib.mkForce [ ];

  # Podman is installed but not auto-started. Start the socket manually
  # when you want to use Podman.
  #   doas systemctl start podman.socket
  virtualisation.podman = {
    enable = lib.mkDefault true;
    dockerCompat = lib.mkDefault false;
  };
  systemd.services.podman.wantedBy = lib.mkForce [ ];
  systemd.sockets.podman.wantedBy = lib.mkForce [ ];

  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.docker-buildx
    pkgs.podman
    pkgs.podman-compose
    pkgs.dive
    pkgs.act
  ];
}
