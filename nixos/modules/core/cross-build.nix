{ config, lib, ... }:
let
  cfg = config.platform.crossBuild;
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
    boot.binfmt.emulatedSystems = cfg.emulatedSystems;
    boot.binfmt.preferStaticEmulators = true;
  };
}
