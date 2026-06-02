{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.grubTheme;

  resolutionToGfxmode = {
    "1080p" = "1920x1080";
    "2k" = "2560x1440";
    "4k" = "3840x2160";
  };

  themePackage = pkgs.graphite-grub-theme.overrideAttrs (_oldAttrs: {
    inherit (cfg) variant resolution fontSize;
  });
in
{
  options.platform.grubTheme = {
    enable = lib.mkEnableOption "custom GRUB theme";

    theme = lib.mkOption {
      type = lib.types.enum [ "graphite" ];
      default = "graphite";
      description = "GRUB theme name. Future: elegant-forest, elegant-mojave, etc.";
    };

    variant = lib.mkOption {
      type = lib.types.enum [
        "default"
        "nord"
      ];
      default = "default";
      description = "Color variant of the theme.";
    };

    resolution = lib.mkOption {
      type = lib.types.enum [
        "1080p"
        "2k"
        "4k"
      ];
      default = "1080p";
      description = "Screen resolution variant.";
    };

    fontSize = lib.mkOption {
      type = lib.types.enum [
        "16"
        "24"
        "32"
        "48"
      ];
      default = "16";
      description = "GRUB menu font size. Available sizes depend on the theme package.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.loader.grub.enable;
        message = "platform.grubTheme requires boot.loader.grub.enable = true";
      }
    ];

    boot.loader.grub = {
      theme = lib.mkForce "${themePackage}/share/grub/themes/graphite";
      splashImage = lib.mkForce "${themePackage}/share/grub/themes/graphite/background.png";
      font = lib.mkForce "${themePackage}/share/grub/themes/graphite/dejavu_sans_${cfg.fontSize}.pf2";
      gfxmodeEfi = lib.mkDefault resolutionToGfxmode.${cfg.resolution};
      gfxmodeBios = lib.mkDefault resolutionToGfxmode.${cfg.resolution};
      extraConfig = ''
        # Load Terminus font for terminal mode (classic monospace look)
        loadfont ''${prefix}/theme/terminus-14.pf2
      '';
    };
  };
}
