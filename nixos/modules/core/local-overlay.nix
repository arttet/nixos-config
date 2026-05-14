{
  lib,
  localHardwareConfig ? null,
  localSystemOverlay ? null,
  localUserOverlay ? null,
  pkgs,
  ...
}:
{
  imports =
    lib.optional (localUserOverlay != null && builtins.pathExists localUserOverlay) localUserOverlay
    ++ lib.optional (
      localSystemOverlay != null && builtins.pathExists localSystemOverlay
    ) localSystemOverlay
    ++ lib.optional (
      localHardwareConfig != null && builtins.pathExists localHardwareConfig
    ) localHardwareConfig;

  users.defaultUserShell = pkgs.nushell;
}
