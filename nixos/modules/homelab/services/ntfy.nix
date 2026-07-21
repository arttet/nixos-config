{
  config,
  lib,
  ...
}:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.ntfy) {
    users.groups.ntfy = { };
    users.users.ntfy = {
      isSystemUser = true;
      group = "ntfy";
      home = "/srv/data/ntfy";
      createHome = false;
    };

    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = "127.0.0.1:2586";
        base-url = "https://${cfg.ntfy.domain}";
        cache-file = "/srv/data/ntfy/cache.db";
        attachment-cache-dir = "/srv/data/ntfy/attachments";
        # Anyone who can reach ntfy can otherwise publish or subscribe to any
        # topic with no credentials; deny by default and provision a user or
        # access token interactively after storage unlock (same pattern as
        # AdGuard's password-set and Samba's smbpasswd steps).
        auth-file = "/srv/data/ntfy/auth.db";
        auth-default-access = "deny-all";
      };
    };

    systemd.services.ntfy-sh = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # cache, attachments, and auth db live on the encrypted /srv volume,
      # which isn't mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      serviceConfig = {
        # DynamicUser's runtime-allocated UID can't be pre-chowned onto
        # /srv/data/ntfy by storage.nix, so pin a static system user.
        DynamicUser = lib.mkForce false;
        # Upstream may assign User/Group directly (not via mkDefault) under a
        # different account name; mkForce guarantees this static user wins
        # regardless, matching every other homelab static-user override.
        User = lib.mkForce "ntfy";
        Group = lib.mkForce "ntfy";
        StateDirectory = lib.mkForce [ ];
        ReadWritePaths = [ "/srv/data/ntfy" ];
      };
    };
  };
}
