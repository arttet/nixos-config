{ lib, ... }:

{
  networking.hostName = lib.mkForce "workstation";
  time.timeZone = lib.mkForce "Etc/UTC";
}
