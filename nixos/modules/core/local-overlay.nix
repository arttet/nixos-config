{
  lib,
  localHardwareConfig ? null,
  localUserOverlay ? null,
  pkgs,
  ...
}:
{
  imports =
    lib.optional (localUserOverlay != null && builtins.pathExists localUserOverlay) localUserOverlay
    ++ lib.optional (
      localHardwareConfig != null && builtins.pathExists localHardwareConfig
    ) localHardwareConfig;

  assertions = [
    {
      assertion = localUserOverlay == null || builtins.pathExists localUserOverlay;
      message = "local user overlay is required but was not found; copy templates/local/default.nix to /etc/nixos/local/default.nix";
    }
    {
      assertion = localHardwareConfig == null || builtins.pathExists localHardwareConfig;
      message = "local hardware configuration is required but was not found; expected /etc/nixos/hardware-configuration.nix";
    }
  ];

  users.defaultUserShell = pkgs.nushell;
}
