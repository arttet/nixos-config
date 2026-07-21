{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.forgejo) {
    assertions = [
      {
        assertion = cfg.services.podman;
        message = "homelab Forgejo requires homelab.services.podman.";
      }
    ];

    virtualisation.oci-containers.containers.forgejo = {
      image = "codeberg.org/forgejo/forgejo:16";
      ports = [
        "127.0.0.1:3001:3000"
        "2222:22"
      ];
      volumes = [
        "/srv/data/forgejo:/data"
      ];
      environment = {
        USER_UID = "1000";
        USER_GID = "1000";
        FORGEJO__database__DB_TYPE = "sqlite3";
        FORGEJO__server__DOMAIN = cfg.forgejo.domain;
        FORGEJO__server__ROOT_URL = "https://${cfg.forgejo.domain}/";
        FORGEJO__server__SSH_DOMAIN = cfg.forgejo.domain;
        FORGEJO__server__SSH_PORT = "2222";
        FORGEJO__service__DISABLE_REGISTRATION = "true";
        FORGEJO__actions__ENABLED = "true";
      };
      extraOptions = [
        "--network=homelab"
        "--memory=1024m"
        "--health-cmd=curl -sf http://localhost:3000/api/healthz || exit 1"
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    systemd.services.podman-forgejo = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "podman-network-homelab.service"
      ];
      requires = [
        "homelab-storage.target"
        "podman-network-homelab.service"
      ];
    };
  };
}
