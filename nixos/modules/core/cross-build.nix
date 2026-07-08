{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.crossBuild;
  # binfmt cannot register (and asserts against) the host's own architecture, so an
  # aarch64-linux host must drop aarch64-linux from the emulated set. Keep the option
  # value as declared; only filter what reaches boot.binfmt.
  foreignSystems = lib.filter (system: system != pkgs.stdenv.hostPlatform.system) cfg.emulatedSystems;
in
{
  options.platform.crossBuild = {
    enable = lib.mkEnableOption "QEMU user-mode emulation for building foreign-architecture derivations locally";

    emulatedSystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "aarch64-linux" ];
      description = "Systems registered for local QEMU binfmt emulation (also added to nix.settings.extra-platforms).";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.binfmt.emulatedSystems = foreignSystems;
    boot.binfmt.preferStaticEmulators = true;
  };
}
