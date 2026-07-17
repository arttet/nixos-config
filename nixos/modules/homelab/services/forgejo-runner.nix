{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.forgejoRunner) {
    assertions = [
      {
        assertion = cfg.services.podman && cfg.services.forgejo;
        message = "homelab Forgejo runner requires homelab.services.podman and homelab.services.forgejo.";
      }
    ];

    virtualisation.oci-containers.containers.forgejo-runner = {
      image = "code.forgejo.org/forgejo/runner:12";
      volumes = [
        "/srv/data/forgejo-runner:/data"
        "/run/podman/podman.sock:/var/run/docker.sock"
        # Caddy's "tls internal" vhosts are signed by its own local root CA;
        # trust it so the runner's TLS check of git.pi.lan succeeds instead
        # of falling back to --insecure. Mount the world-readable copy
        # preStart makes below, not Caddy's own 0600 root.crt directly.
        "/run/forgejo-runner-ca.crt:/etc/ssl/certs/caddy-local-ca.crt:ro"
      ];
      environment = {
        DOCKER_HOST = "unix:///var/run/docker.sock";
        SSL_CERT_FILE = "/etc/ssl/certs/caddy-local-ca.crt";
      };
      environmentFiles = [ cfg.forgejo.runnerEnvironmentFile ];
      cmd = [
        "forgejo-runner"
        "--config"
        "/data/config.yml"
        "daemon"
      ];
      extraOptions = [
        "--network=homelab"
        # The image's default non-root user can't open the bind-mounted
        # /run/podman/podman.sock (owned by root on the host). Running as
        # root here doesn't raise the container's actual privilege: holding
        # that socket already grants root-equivalent control of the host.
        "--user=0:0"
        # The homelab network disables aardvark-dns (see podman-network-homelab),
        # so containers inherit the host's resolv.conf verbatim; its 127.0.0.1
        # entry is unreachable from inside the container netns. Resolve the
        # Forgejo domain straight to the host running AdGuard/Caddy instead.
        "--add-host=${cfg.forgejo.domain}:host-gateway"
        # forgejo-runner exposes no HTTP endpoint to probe; fall back to a
        # process-liveness check, the pattern the runner community uses.
        "--health-cmd=pgrep forgejo-runner || exit 1"
        "--health-interval=30s"
        "--health-timeout=5s"
        "--health-retries=3"
        "--health-start-period=30s"
      ];
    };

    systemd.services.podman-forgejo-runner = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "podman-network-homelab.service"
        "podman-forgejo.service"
        "podman.socket"
      ];
      requires = [
        "homelab-storage.target"
        "podman-network-homelab.service"
        "podman.socket"
      ];
      # Caddy keeps its local CA certificate at mode 0600, unreadable to the
      # runner container's own user; copy it out to a world-readable path
      # each start instead of loosening permissions on Caddy's data dir.
      preStart = ''
        install -D -m 0644 \
          /persist/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt \
          /run/forgejo-runner-ca.crt
      '';
    };
  };
}
