{ lib, ... }:
{
  imports = [
    ../../profiles/server.nix
  ];

  networking.hostName = lib.mkDefault "server";
  system.stateVersion = lib.mkDefault "25.11";
}
