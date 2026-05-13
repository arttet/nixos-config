{ lib, pkgs, ... }:
let
  envOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_USER";
  home = builtins.getEnv "HOME";
  defaultOverlay = if home == "" then "" else "${home}/.nix-config-local/user.nix";
  overlayPath = if envOverlay != "" then envOverlay else defaultOverlay;
  overlayFile = /. + overlayPath;
in
{
  imports = lib.optional (overlayPath != "" && builtins.pathExists overlayFile) overlayFile;

  users.defaultUserShell = pkgs.nushell;
}
