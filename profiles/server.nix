# profiles/server.nix
{ ... }:
{
  imports = [
    ./base.nix
  ];

  # Server/Infrastructure services
  # Example: docker, nginx, etc.
  virtualisation.docker.enable = true;
}
