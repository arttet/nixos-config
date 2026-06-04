{
  config,
  configsDir,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.greetd;
  uwsm = lib.getExe config.programs.uwsm.package;
  dbusRunSession = "${pkgs.dbus}/bin/dbus-run-session";

  tuigreet = if builtins.hasAttr "tuigreet" pkgs then pkgs.tuigreet else pkgs.greetd.tuigreet;

  greetdConfigs = configsDir + "/greetd";
  effectiveTheme =
    if cfg.theme != null then
      cfg.theme
    else if config.platform.theme.enable then
      config.platform.theme.name
    else
      null;
  effectiveThemeVariant =
    if cfg.theme != null then
      cfg.themeVariant
    else if config.platform.theme.enable then
      config.platform.theme.variant
    else
      cfg.themeVariant;
  darkThemeVariants = [
    "nord"
    "dark"
    "frappe"
    "mocha"
    "macchiato"
  ];
  preferDarkTheme = builtins.elem effectiveThemeVariant darkThemeVariants;
  gtkThemeName =
    if effectiveTheme == "graphite" then
      if effectiveThemeVariant == "nord" then
        if preferDarkTheme then "Graphite-Dark-nord" else "Graphite-Light-nord"
      else if preferDarkTheme then
        "Graphite-Dark"
      else
        "Graphite-Light"
    else
      "Adwaita";
  backgroundImage =
    if effectiveTheme == "graphite" && effectiveThemeVariant == "nord" then
      pkgs.runCommand "regreet-graphite-nord-background.png" { nativeBuildInputs = [ pkgs.imagemagick ]; }
        ''
          magick ${pkgs.graphite-gtk-theme}/share/backgrounds/wave-Dark-nord.jpg $out
        ''
    else
      "${pkgs.graphite-grub-theme}/share/backgrounds/graphite/nord-dark.png";
  normalUsers = lib.filterAttrs (
    _name: user: (user.enable or true) && (user.isNormalUser or false)
  ) config.users.users;
  accountsServiceSeeds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: _user: ''
      account_file=${lib.escapeShellArg "/var/lib/AccountsService/users/${name}"}
      if [ ! -e "$account_file" ]; then
        printf '%s\n' '[User]' 'SystemAccount=false' > "$account_file"
        chmod 0600 "$account_file"
      fi
    '') normalUsers
  );
in
{
  options.platform.greetd = {
    enable = lib.mkEnableOption "greetd login manager";

    greeter = lib.mkOption {
      type = lib.types.enum [
        "tuigreet"
        "regreet"
      ];
      default = "regreet";
      description = "Greeter implementation. tuigreet is minimal and reliable; regreet is graphical.";
    };

    theme = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "graphite"
          "catppuccin"
        ]
      );
      default = null;
      description = "Visual theme for ReGreet. null means default Adwaita.";
    };

    themeVariant = lib.mkOption {
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
    assertions = [
      {
        assertion = config.programs.uwsm.enable;
        message = "platform.greetd requires programs.uwsm.enable = true";
      }
    ];

    services.greetd = {
      enable = true;
      settings.default_session = lib.mkMerge [
        {
          user = "greeter";
        }
        (lib.mkIf (cfg.greeter == "tuigreet") {
          command = "${lib.getExe tuigreet} --time --remember --cmd '${uwsm} start hyprland-uwsm.desktop'";
        })
        (lib.mkIf (cfg.greeter == "regreet") {
          command = "${dbusRunSession} -- ${pkgs.hyprland}/bin/start-hyprland -- --config /etc/greetd/hyprland-greeter.lua";
        })
      ];
    };

    # regreet uses AccountsService via system D-Bus to enumerate users; without
    # this it panics at startup (expect()) before rendering anything.
    # Enabled unconditionally so `regreet --demo` works from any session.
    services.accounts-daemon.enable = true;

    # Ensure AccountsService is ready before greetd starts; otherwise regreet
    # panics trying to connect to the D-Bus interface that isn't up yet.
    systemd.services.greetd = lib.mkIf (cfg.greeter == "regreet") {
      after = [ "accounts-daemon.service" ];
      wants = [ "accounts-daemon.service" ];
    };

    system.activationScripts.regreetAccountsServiceUsers = lib.mkIf (cfg.greeter == "regreet") {
      text = ''
        install -d -m 0775 /var/lib/AccountsService/users
        ${accountsServiceSeeds}
      '';
    };

    systemd.tmpfiles.rules = lib.mkIf (cfg.greeter == "regreet") [
      "d /var/log/regreet 0755 greeter greeter -"
      "f /var/log/regreet/log 0644 greeter greeter -"
      "d /var/cache/regreet 0755 greeter greeter -"
      "d /var/lib/regreet 0755 greeter greeter -"
      "d /var/lib/regreet/config 0755 greeter greeter -"
    ];

    environment.systemPackages = lib.mkIf (cfg.greeter == "regreet") (
      [
        pkgs.regreet
        pkgs.adwaita-icon-theme
        pkgs.gsettings-desktop-schemas
      ]
      ++ lib.optionals (effectiveTheme == "graphite") [
        pkgs.graphite-gtk-theme
      ]
    );

    environment.etc."greetd/hyprland-greeter.lua" = lib.mkIf (cfg.greeter == "regreet") {
      source = greetdConfigs + "/hyprland-greeter.lua";
    };

    environment.etc."greetd/regreet.css" = lib.mkIf (cfg.greeter == "regreet") {
      text = ''
        frame:not(.background),
        infobar {
          border: none;
          box-shadow: none;
          background: none;
        }

        separator {
          min-height: 0;
          min-width: 0;
          opacity: 0;
          background: none;
          border: none;
        }
      '';
    };

    environment.etc."greetd/regreet.toml" = lib.mkIf (cfg.greeter == "regreet") {
      text = ''
        [background]
        path = "${backgroundImage}"
        fit = "Cover"

        [GTK]
        theme_name = "${gtkThemeName}"
        application_prefer_dark_theme = ${lib.boolToString preferDarkTheme}

        [commands]
        reboot = ["${pkgs.systemd}/bin/loginctl", "reboot"]
        poweroff = ["${pkgs.systemd}/bin/loginctl", "poweroff"]

        [appearance]
        greeting_msg = ""

        [widget.clock]
        format = "%A, %d %B %Y  %H:%M:%S"
        resolution = "1s"
        label_width = 600
      '';
    };
  };
}
