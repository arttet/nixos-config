{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  ensureNetwork = pkgs.writeTextFile {
    name = "podman-network-homelab";
    destination = "/bin/podman-network-homelab";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu

      if ! ${pkgs.podman}/bin/podman network exists homelab >/dev/null 2>&1; then
        ${pkgs.podman}/bin/podman network create homelab
      fi
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.services.podman) {
    users.groups.podman = { };

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
      };
      oci-containers.backend = "podman";
    };

    systemd.tmpfiles.rules = [
      "d /srv 0755 root root -"
    ];

    systemd.services.podman-network-homelab = {
      description = "Create the homelab Podman network";
      after = [ "podman.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${ensureNetwork}/bin/podman-network-homelab";
      };
    };
  };
}
