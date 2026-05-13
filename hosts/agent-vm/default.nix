# hosts/agent-vm/default.nix
{ lib, ... }:
let
  userOverlay = builtins.getEnv "HOME" + "/.nixos-local/user.nix";
  hwConfig = "/etc/nixos/hardware-configuration.nix";
in
{
  imports = [
    ../../profiles/agent.nix
    ../../hosts/common/disk.nix
  ]
  ++ lib.optional (builtins.pathExists userOverlay) (/. + userOverlay)
  ++ lib.optional (builtins.pathExists hwConfig) (/. + hwConfig);

  disko.devices.disk.main.device = "/dev/vda";
  networking.hostName = "agent-vm";
}
