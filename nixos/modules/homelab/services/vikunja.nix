{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.vikunja) {
    users.groups.vikunja = { };
    users.users.vikunja = {
      isSystemUser = true;
      group = "vikunja";
      home = "/srv/data/vikunja";
      createHome = false;
    };

    services.vikunja = {
      enable = true;
      frontendScheme = "https";
      frontendHostname = cfg.vikunja.domain;
      port = 3456;
      environmentFiles = [ cfg.vikunja.environmentFile ];
      # Real mkOption default upstream (/var/lib/vikunja/vikunja.db); a plain
      # override at normal priority wins without needing mkForce.
      database.path = "/srv/data/vikunja/vikunja.db";
      settings = {
        # Both of these are assigned directly (not via mkOption/mkDefault) in
        # the upstream module's own config block, so a plain override
        # collides with it; mkForce is required for both.
        files.basepath = lib.mkForce "/srv/data/vikunja/files";
        # The pinned nixos-raspberrypi nixpkgs has no `address` option for
        # this module; "service.interface" is hardcoded to bind all
        # interfaces (":<port>") upstream, so bind to loopback here instead,
        # matching every other homelab backend (forgejo/openspeedtest/beszel).
        service.interface = lib.mkForce "127.0.0.1:3456";
      };
    };

    systemd.services.vikunja = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # sqlite DB and attached files live on the encrypted /srv volume, which
      # isn't mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      unitConfig.ConditionPathExists = cfg.vikunja.environmentFile;
      serviceConfig = {
        # DynamicUser's runtime-allocated UID can't be pre-chowned onto
        # /srv/data/vikunja by storage.nix, so pin a static system user.
        DynamicUser = lib.mkForce false;
        User = "vikunja";
        Group = "vikunja";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/srv/data/vikunja" ];
      };
    };
  };
}
