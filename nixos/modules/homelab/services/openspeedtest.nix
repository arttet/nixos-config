{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.openspeedtest) {
    assertions = [
      {
        assertion = cfg.services.podman;
        message = "homelab OpenSpeedTest requires homelab.services.podman.";
      }
    ];

    virtualisation.oci-containers.containers.openspeedtest = {
      image = "docker.io/openspeedtest/latest";
      ports = [ "127.0.0.1:3002:3000" ];
      extraOptions = [
        "--network=homelab"
        "--read-only"
        "--tmpfs=/etc/nginx/conf.d:mode=0777"
        "--tmpfs=/var/cache/nginx:mode=0777"
        "--tmpfs=/var/run:mode=0777"
        "--tmpfs=/tmp:mode=1777"
        "--cap-drop=ALL"
        "--memory=128m"
        "--health-cmd=curl -sf http://localhost:3000/ || exit 1"
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    systemd.services.podman-openspeedtest = {
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
