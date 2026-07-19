{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.memos) {
    services.memos = {
      enable = true;
      dataDir = "/srv/data/memos";
      # The upstream module's `settings` default sets MEMOS_MODE/ADDR/PORT/DATA/DRIVER;
      # assigning a plain attrset here *replaces* that default set, so we must restate
      # the full set. Without MEMOS_DATA, memos resolves its DSN into a read-only
      # default path and exits silently with "unable to open database file".
      settings = {
        MEMOS_MODE = "prod";
        MEMOS_ADDR = "127.0.0.1";
        MEMOS_PORT = "5230";
        MEMOS_DATA = config.services.memos.dataDir;
        MEMOS_DRIVER = "sqlite";
        MEMOS_INSTANCE_URL = "https://${cfg.memos.domain}";
      };
    };

    systemd.services.memos = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # sqlite database lives on the encrypted /srv volume, which isn't
      # mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      serviceConfig = {
        # The upstream module exits with status 0 when migration fails (e.g. the
        # DSN points into a read-only directory), so on-failure does not help.
        Restart = "always";
        RestartSec = 60;
      };
    };
  };
}
