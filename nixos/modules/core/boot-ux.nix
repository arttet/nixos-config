{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.bootUx;
in
{
  options.platform.bootUx = {
    enable = lib.mkEnableOption "graphical boot UX for workstation-class systems";

    quiet = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Hide kernel and systemd boot status during normal graphical boot.";
    };

    earlyGraphicsDrivers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "amdgpu"
          "i915"
          "nouveau"
        ]
      );
      default = [ "amdgpu" ];
      description = "DRM drivers loaded in initrd so Plymouth can render immediately after the boot loader. Defaults to amdgpu; override in a host overlay if you have Intel iGPU (i915) or Nouveau.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = lib.mkDefault true;
      themePackages = lib.mkDefault [
        (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "splash" ]; })
      ];
      theme = lib.mkDefault "splash";
    };

    boot.consoleLogLevel = lib.mkIf cfg.quiet (lib.mkDefault 3);

    boot.kernelParams = lib.mkIf cfg.quiet [
      "quiet"
      "fbcon=nodefer"
      "plymouth.ignore-serial-consoles"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
    ];

    boot.initrd.kernelModules = cfg.earlyGraphicsDrivers;
  };
}
