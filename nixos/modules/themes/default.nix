{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.theme;
  darkThemeVariants = [
    "nord"
    "dark"
    "frappe"
    "mocha"
    "macchiato"
  ];
  preferDarkTheme = builtins.elem cfg.variant darkThemeVariants;
  gtkThemeName =
    if cfg.name == "graphite" then
      if cfg.variant == "nord" then
        if preferDarkTheme then "Graphite-Dark-nord" else "Graphite-Light-nord"
      else if preferDarkTheme then
        "Graphite-Dark"
      else
        "Graphite-Light"
    else
      "Adwaita";
in
{
  options.platform.theme = {
    enable = lib.mkEnableOption "system-wide visual theme";

    name = lib.mkOption {
      type = lib.types.enum [
        "graphite"
        "catppuccin"
      ];
      default = "graphite";
      description = "Theme name.";
    };

    variant = lib.mkOption {
      type = lib.types.enum [
        "nord"
        "dark"
        "light"
        "frappe"
        "latte"
        "mocha"
        "macchiato"
      ];
      default = "nord";
      description = "Theme variant.";
    };
  };

  config = lib.mkIf cfg.enable {
    # System-wide GTK settings
    environment.etc."gtk-3.0/settings.ini".text = lib.generators.toINI { } {
      Settings = {
        gtk-theme-name = gtkThemeName;
        gtk-icon-theme-name = "Adwaita";
        gtk-cursor-theme-name = "Adwaita";
        gtk-font-name = "DejaVu Sans 11";
      };
    };

    # Packages
    environment.systemPackages = lib.optionals (cfg.name == "graphite") [
      pkgs.graphite-gtk-theme
    ];
  };
}
