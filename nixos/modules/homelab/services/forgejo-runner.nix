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
      image = "code.forgejo.org/forgejo/runner:6";
      volumes = [
        "/srv/data/forgejo-runner:/data"
        "/run/podman/podman.sock:/var/run/docker.sock"
      ];
      environment = {
        DOCKER_HOST = "unix:///var/run/docker.sock";
      };
      environmentFiles = [ cfg.forgejo.runnerEnvironmentFile ];
      cmd = [
        "sh"
        "-c"
        "if [ ! -f /data/.runner ]; then echo 'not registered'; sleep infinity; else exec forgejo-runner daemon; fi"
      ];
      extraOptions = [
        "--network=homelab"
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
    };
  };
}
