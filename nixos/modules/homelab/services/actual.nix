{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.actual) {
    users.groups.actual = { };
    users.users.actual = {
      isSystemUser = true;
      group = "actual";
      home = "/srv/data/actual";
      createHome = false;
    };

    services.actual = {
      enable = true;
      settings = {
        hostname = "127.0.0.1";
        # 3000 is already taken by AdGuard's own web UI (see caddy.nix).
        port = 3005;
        dataDir = "/srv/data/actual";
        serverFiles = "/srv/data/actual/server-files";
        userFiles = "/srv/data/actual/user-files";
      };
    };

    systemd.services.actual = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # server/user files live on the encrypted /srv volume, which isn't
      # mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      serviceConfig = {
        # DynamicUser's runtime-allocated UID can't be pre-chowned onto
        # /srv/data/actual by storage.nix; pin the static user defined above
        # instead (upstream defines no static user at all, only
        # DynamicUser=true alongside a hardcoded User/Group name).
        DynamicUser = lib.mkForce false;
        WorkingDirectory = lib.mkForce "/srv/data/actual";
        # StateDirectory would otherwise create/use an unused, SD-backed
        # /var/lib/actual. ProtectSystem=strict (set upstream) blocks writes
        # anywhere else, so /srv needs an explicit ReadWritePaths grant.
        StateDirectory = lib.mkForce [ ];
        ReadWritePaths = [ "/srv/data/actual" ];
      };
    };
  };
}
