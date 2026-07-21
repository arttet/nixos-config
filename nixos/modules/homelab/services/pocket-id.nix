{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.pocketId) {
    services.pocket-id = {
      enable = true;
      dataDir = "/srv/data/pocket-id";
      settings = {
        APP_URL = "https://${cfg.pocketId.domain}";
        TRUST_PROXY = true;
      };
    };

    systemd.services.pocket-id = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # sqlite database lives on the encrypted /srv volume, which isn't
      # mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      # No DynamicUser/User/Group/ProtectSystem/ReadWritePaths override here,
      # unlike most other native homelab services: this module never used
      # DynamicUser to begin with (static "pocket-id" user by default) and
      # already sets ProtectSystem=strict + ReadWritePaths=[cfg.dataDir]
      # upstream, so pointing dataDir at /srv above is already sufficient.
    };
  };
}
