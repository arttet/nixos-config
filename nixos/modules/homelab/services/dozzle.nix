{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.dozzle) {
    assertions = [
      {
        assertion = cfg.services.podman;
        message = "homelab Dozzle requires homelab.services.podman.";
      }
    ];

    virtualisation.oci-containers.containers.dozzle = {
      image = "amir20/dozzle:latest";
      volumes = [
        "/run/podman/podman.sock:/var/run/docker.sock:ro"
        "/srv/data/dozzle:/data"
      ];
      ports = [ "127.0.0.1:8081:8080" ];
      # Dozzle exposes every other container's live stdout/stderr; require its
      # own login rather than relying on LAN+Caddy alone, since that's a much
      # broader blast radius than the repo's no-auth services (Gatus,
      # OpenSpeedTest) expose. Credentials live in /data/users.yml, generated
      # interactively after storage unlock (see homelab-rpi5.md), never in Nix
      # or platform state.
      environment.DOZZLE_AUTH_PROVIDER = "simple";
      extraOptions = [
        "--network=homelab"
        # Reading the podman socket already grants root-equivalent visibility
        # into every container on the host; running the container itself as
        # root adds no further privilege (same reasoning as the socket mount
        # in forgejo-runner.nix).
        "--user=0:0"
        "--cap-drop=ALL"
        "--memory=128m"
        # Dozzle's image has no shell at all (confirmed: `sh` doesn't exist),
        # so a plain "--health-cmd=dozzle healthcheck" string gets wrapped in
        # `/bin/sh -c` by podman and fails outright. JSON-array (exec) form
        # bypasses the shell; confirmed working via
        # `podman exec dozzle /dozzle healthcheck`.
        ''--health-cmd=["/dozzle", "healthcheck"]''
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    systemd.services.podman-dozzle = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "podman-network-homelab.service"
      ];
      requires = [
        "homelab-storage.target"
        "podman-network-homelab.service"
      ];
      # DOZZLE_AUTH_PROVIDER=simple makes Dozzle fatal-exit at startup if this
      # file doesn't exist yet, rather than just starting with zero users —
      # without this gate the unit crash-loops until the operator provisions
      # it (see homelab-rpi5.md), same reasoning as Vikunja/Speed Test
      # Tracker's environmentFile gates.
      unitConfig.ConditionPathExists = "/srv/data/dozzle/users.yml";
    };
  };
}
