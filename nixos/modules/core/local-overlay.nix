{ lib, pkgs, ... }:
let
  envUserOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_USER";
  envSystemOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_SYSTEM";
  envHardwareConfig = builtins.getEnv "NIX_CONFIG_LOCAL_HARDWARE";
  home = builtins.getEnv "HOME";
  defaultUserOverlay = if home == "" then "" else "${home}/.nix-config-local/user.nix";
  defaultSystemOverlay = if home == "" then "" else "${home}/.nix-config-local/system.nix";
  userOverlayPath = if envUserOverlay != "" then envUserOverlay else defaultUserOverlay;
  systemOverlayPath = if envSystemOverlay != "" then envSystemOverlay else defaultSystemOverlay;
  userOverlayFile = /. + userOverlayPath;
  systemOverlayFile = /. + systemOverlayPath;
  hardwareConfigFile = if envHardwareConfig == "" then null else /. + envHardwareConfig;
in
{
  imports =
    lib.optional (userOverlayPath != "" && builtins.pathExists userOverlayFile) userOverlayFile
    ++ lib.optional (systemOverlayPath != "" && builtins.pathExists systemOverlayFile) systemOverlayFile
    ++ lib.optional (
      hardwareConfigFile != null && builtins.pathExists hardwareConfigFile
    ) hardwareConfigFile;

  users.defaultUserShell = pkgs.nushell;
}
