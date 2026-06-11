{
  config,
  pkgs,
  lib,
  walker,
  ...
}:
let
  graphicalSessionService =
    {
      description,
      execStart,
      after ? [ "graphical-session.target" ],
      busName ? null,
      path ? [ ],
      type ? "simple",
      environment ? { },
    }:
    {
      inherit description after path;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = lib.mkMerge [
        {
          Type = type;
          ExecStart = execStart;
          Restart = "on-failure";
          RestartSec = 1;
        }
        (lib.mkIf (busName != null) {
          BusName = busName;
        })
        (lib.mkIf (environment != { }) {
          Environment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
        })
      ];
    };
in
{
  services.hypridle.enable = lib.mkDefault true;
  systemd.user.services.hypridle.serviceConfig = {
    Restart = lib.mkDefault "on-failure";
    RestartSec = lib.mkDefault 1;
  };

  programs.nm-applet = {
    enable = lib.mkDefault true;
    indicator = lib.mkDefault true;
  };
  systemd.user.services.nm-applet = {
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Restart = lib.mkDefault "on-failure";
      RestartSec = lib.mkDefault 1;
    };
  };

  environment.systemPackages = [
    walker.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.elephant
    pkgs.hypridle
    pkgs.hyprpolkitagent
    pkgs.networkmanagerapplet
  ];

  systemd.user.services.elephant = graphicalSessionService {
    description = "Elephant data provider service for Walker";
    execStart = "${lib.getExe pkgs.elephant} --config /etc/xdg/elephant";
    # Elephant providers execute arbitrary desktop files via shell;
    # they need bash in PATH and access to system-wide applications.
    environment = {
      PATH = "${pkgs.bash}/bin:/run/current-system/sw/bin";
    };
  };

  environment.etc."xdg/elephant/elephant.toml".text = ''
    ignored_providers = ["archlinuxpkgs"]
  '';

  environment.etc."xdg/elephant/desktopapplications.toml".text = ''
    auto_detect_launch_prefix = false
    launch_prefix = "${lib.getExe' config.programs.uwsm.package "uwsm-app"} -- "
  '';

  systemd.user.services.walker =
    (graphicalSessionService {
      description = "Walker Launcher Service";
      after = [
        "graphical-session.target"
        "elephant.service"
      ];
      execStart = "${
        lib.getExe walker.packages.${pkgs.stdenv.hostPlatform.system}.default
      } --gapplication-service";
      busName = "dev.benz.walker";
      path = [ pkgs.elephant ];
      type = "dbus";
    })
    // {
      requires = [ "elephant.service" ];
    };

  systemd.user.services.mako = graphicalSessionService {
    description = "Mako notification daemon";
    execStart = lib.getExe pkgs.mako;
  };

  systemd.user.services.opensnitch-ui = graphicalSessionService {
    description = "OpenSnitch application firewall UI";
    execStart = "${lib.getExe pkgs.opensnitch-ui} --background";
  };

  systemd.user.services.cliphist-text = graphicalSessionService {
    description = "Store text clipboard history";
    execStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch ${lib.getExe pkgs.cliphist} store";
  };

  systemd.user.services.cliphist-image = graphicalSessionService {
    description = "Store image clipboard history";
    execStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch ${lib.getExe pkgs.cliphist} store";
  };

  systemd.user.services.hyprpolkitagent = graphicalSessionService {
    description = "Hyprland polkit authentication agent";
    execStart = lib.getExe pkgs.hyprpolkitagent;
  };

  systemd.user.services.udiskie = graphicalSessionService {
    description = "UDisks tray agent";
    execStart = "${lib.getExe' pkgs.udiskie "udiskie"} --tray";
  };

  systemd.user.services.wlsunset = graphicalSessionService {
    description = "Wayland color temperature adjustment";
    execStart = "${lib.getExe pkgs.wlsunset} -t 5000 -T 6500";
  };
}
