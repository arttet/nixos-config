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
        # Containers don't resolve each other by name, and aardvark-dns
        # binding the bridge gateway on :53 conflicts with AdGuard listening
        # on 0.0.0.0:53.
        ${pkgs.podman}/bin/podman network create homelab --disable-dns
      fi
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.services.podman) {
    users.groups.podman = { };

    # Raspberry Pi kernels don't delegate the memory cgroup controller by
    # default; without it, crun fails to write `memory.max` for any
    # container started with a --memory limit.
    boot.kernelParams = [
      "cgroup_enable=memory"
      "cgroup_memory=1"
    ];

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
      # Keep container storage (overlay layers, volumes) off the SD card and
      # on the encrypted disk instead; requires podman itself to wait for
      # homelab-storage.target, same as every other disk-backed service.
      containers.storage.settings.storage.graphroot = "/srv/containers/storage";
    };

    systemd.tmpfiles.rules = [
      "d /srv 0755 root root -"
    ];

    systemd.sockets.podman = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
    };
    systemd.services.podman = {
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
    };

    systemd.services.podman-network-homelab = {
      description = "Create the homelab Podman network";
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "podman.service"
      ];
      requires = [ "homelab-storage.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${ensureNetwork}/bin/podman-network-homelab";
      };
    };
  };
}
