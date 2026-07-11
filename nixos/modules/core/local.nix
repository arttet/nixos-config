{
  lib,
  localHardwareConfig ? null,
  localStateFile ? null,
  pkgs,
  ...
}:
{
  imports = lib.optional (
    localHardwareConfig != null && builtins.pathExists localHardwareConfig
  ) localHardwareConfig;

  assertions = [
    {
      assertion = localStateFile == null || builtins.pathExists localStateFile;
      message = "local state file is required but was not found; expected /etc/nixos/local/state.json";
    }
    {
      assertion = localHardwareConfig == null || builtins.pathExists localHardwareConfig;
      message = "local hardware configuration is required but was not found; expected /etc/nixos/hardware-configuration.nix";
    }
  ];

  platform.state = lib.mkIf (localStateFile != null) {
    enable = true;
    file = localStateFile;
  };

  users.defaultUserShell = pkgs.bashInteractive;
}
