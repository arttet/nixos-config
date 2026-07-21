{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.vaultwarden) {
    services.vaultwarden = {
      enable = true;
      # ADMIN_TOKEN lives in this file, never in the Nix store. Signups stay
      # disabled permanently; the first (and only) account is created via the
      # /admin invite flow that ADMIN_TOKEN unlocks, so there's never a
      # window where an unauthenticated LAN actor could self-register.
      environmentFile = cfg.vaultwarden.environmentFile;
      config = {
        DOMAIN = "https://${cfg.vaultwarden.domain}";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        DATA_FOLDER = "/srv/data/vaultwarden";
        WEBSOCKET_ENABLED = true;
      };
    };

    systemd.services.vaultwarden = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # vault data lives on the encrypted /srv volume, which isn't mounted
      # until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      unitConfig.ConditionPathExists = cfg.vaultwarden.environmentFile;
      serviceConfig = {
        # Upstream's StateDirectory would otherwise leave an unused,
        # SD-backed /var/lib/vaultwarden directory around; DATA_FOLDER above
        # already redirects everything to /srv. ProtectSystem=strict (set
        # upstream) blocks writes anywhere else, so /srv needs an explicit
        # ReadWritePaths grant.
        StateDirectory = lib.mkForce [ ];
        ReadWritePaths = [ "/srv/data/vaultwarden" ];
      };
    };
  };
}
