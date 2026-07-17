{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  hasHub = pkgs ? beszel;
  hasAgent = pkgs ? "beszel-agent";
  hubPackage = if hasHub then pkgs.beszel else pkgs.hello;
  agentPackage = if hasAgent then pkgs."beszel-agent" else hubPackage;
  hubBin = lib.getExe' hubPackage "beszel-hub";
  agentBin = lib.getExe' agentPackage "beszel-agent";
in
{
  config = lib.mkIf (cfg.enable && cfg.services.beszel) {
    assertions = [
      {
        assertion = hasHub;
        message = "Beszel requires pkgs.beszel from stable nixpkgs.";
      }
    ];

    users.groups.beszel = { };
    users.users.beszel = {
      isSystemUser = true;
      group = "beszel";
      home = "/srv/data/beszel";
      createHome = false;
    };

    systemd.services.beszel = {
      description = "Beszel Hub";
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "network-online.target"
        "homelab-storage.target"
      ];
      wants = [ "network-online.target" ];
      requires = [ "homelab-storage.target" ];
      environment = {
        APP_URL = "https://${cfg.beszel.domain}";
        CHECK_UPDATES = "false";
      };
      serviceConfig = {
        ExecStart = "${hubBin} serve --http 127.0.0.1:8090 --dir /srv/data/beszel/pb_data";
        WorkingDirectory = "/srv/data/beszel";
        User = "beszel";
        Group = "beszel";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/srv/data/beszel" ];
      };
    };

    systemd.services."beszel-agent" = {
      description = "Beszel Agent";
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "network-online.target"
        "homelab-storage.target"
        "beszel.service"
        "podman.socket"
      ];
      wants = [
        "network-online.target"
        "beszel.service"
        "podman.socket"
      ];
      requires = [ "homelab-storage.target" ];
      unitConfig.ConditionPathExists = cfg.beszel.agentEnvironmentFile;
      environment = {
        DATA_DIR = "/srv/data/beszel/agent";
        DOCKER_HOST = "unix:///run/podman/podman.sock";
        HUB_URL = "http://127.0.0.1:8090";
        SERVICE_PATTERNS = "beszel*,caddy*,samba*,sshd*,gatus*,vikunja*";
      };
      serviceConfig = {
        ExecStart = agentBin;
        EnvironmentFile = cfg.beszel.agentEnvironmentFile;
        User = "beszel";
        Group = "beszel";
        SupplementaryGroups = [ "podman" ];
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/srv/data/beszel/agent" ];
      };
    };
  };
}
