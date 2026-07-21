{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.wakapi) {
    services.wakapi = {
      enable = true;
      stateDir = "/srv/data/wakapi";
      # WAKAPI_PASSWORD_SALT lives in this file (KEY=VALUE, loaded as an
      # EnvironmentFile despite the option's "File" name) — required by the
      # module's own assertions and never stored in the Nix store.
      passwordSaltFile = cfg.wakapi.environmentFile;
      settings = {
        server = {
          listen_addr = "127.0.0.1";
          # 8086 is reserved for the bundled InfluxDB2 used by Scrutiny.
          port = 8087;
        };
        # sqlite3 dialect/path key names are taken from wakapi's own
        # config.default.yml, not confirmed against the pinned package
        # version — verify on first deploy (`systemctl status wakapi`,
        # `journalctl -u wakapi`) and adjust if the app fails to start.
        db = {
          dialect = "sqlite3";
          name = "/srv/data/wakapi/wakapi.db";
        };
      };
    };

    systemd.services.wakapi = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # sqlite database lives on the encrypted /srv volume, which isn't
      # mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      unitConfig.ConditionPathExists = cfg.wakapi.environmentFile;
      serviceConfig = {
        # DynamicUser's runtime-allocated UID can't be pre-chowned onto
        # /srv/data/wakapi by storage.nix; the module already defines a
        # static "wakapi" user/group alongside DynamicUser=true, so forcing
        # DynamicUser off keeps that static identity stable across restarts.
        DynamicUser = lib.mkForce false;
        # StateDirectory would otherwise create/use an unused, SD-backed
        # /var/lib/wakapi; stateDir above already redirects WorkingDirectory
        # to /srv. ProtectSystem=full (set upstream, not "strict") doesn't
        # restrict /srv, so no ReadWritePaths override is needed here.
        StateDirectory = lib.mkForce [ ];
      };
    };
  };
}
