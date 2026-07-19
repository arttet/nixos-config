{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.cyberchef) {
    assertions = [
      {
        assertion = cfg.services.podman;
        message = "homelab CyberChef requires homelab.services.podman.";
      }
    ];

    virtualisation.oci-containers.containers.cyberchef = {
      image = "mpepping/cyberchef:latest";
      # Confirmed on hardware: nginx actually listens on 8000 inside this
      # image, not 8080 (the port previously assumed here) — curl to 8080
      # from inside the container gets connection refused, 8000 returns 200.
      ports = [ "127.0.0.1:8085:8000" ];
      extraOptions = [
        "--network=homelab"
        "--memory=256m"
        "--health-cmd=curl -sf http://localhost:8000/ || exit 1"
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    systemd.services.podman-cyberchef = {
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
