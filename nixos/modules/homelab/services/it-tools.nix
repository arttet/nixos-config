{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.itTools) {
    assertions = [
      {
        assertion = cfg.services.podman;
        message = "homelab IT Tools requires homelab.services.podman.";
      }
    ];

    # Stateless: every tool runs client-side in the browser, nothing is
    # persisted or account-gated server-side, so this needs no /srv volume
    # and no auth beyond LAN CIDR + Caddy (same posture as Gatus/OpenSpeedTest).
    virtualisation.oci-containers.containers.it-tools = {
      image = "corentinth/it-tools:latest";
      ports = [ "127.0.0.1:8082:80" ];
      extraOptions = [
        "--network=homelab"
        # nginx's entrypoint chowns /var/cache/nginx/client_temp to the
        # nginx user at startup; --cap-drop=ALL blocks that (confirmed on
        # hardware: "chown(...) failed (1: Operation not permitted)").
        "--memory=256m"
        # curl's presence in this nginx-based image is unconfirmed; if
        # `podman ps` shows the container permanently "(unhealthy)" instead
        # of reflecting real state, check `podman exec it-tools which curl`
        # and switch to wget or drop this block if it's missing.
        "--health-cmd=curl -sf http://localhost:80/ || exit 1"
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    systemd.services.podman-it-tools = {
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
