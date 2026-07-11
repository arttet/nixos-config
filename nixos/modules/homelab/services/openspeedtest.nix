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
        "--cap-drop=ALL"
        "--memory=128m"
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
