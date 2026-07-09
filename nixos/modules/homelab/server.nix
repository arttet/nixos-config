{ ... }:
{
  imports = [
    ./config.nix
    ./base.nix
    ./storage.nix
    ./network.nix
    ./podman.nix
    ./services/adguard.nix
    ./services/beszel.nix
    ./services/caddy.nix
    ./services/forgejo.nix
    ./services/forgejo-runner.nix
    ./services/iperf3.nix
    ./services/openspeedtest.nix
    ./services/samba.nix
    ./services/wireguard.nix
  ];
}
