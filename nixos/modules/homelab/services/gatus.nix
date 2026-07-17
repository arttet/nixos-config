{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  endpoint =
    { name, url }:
    {
      inherit name url;
      interval = "60s";
      conditions = [ "[STATUS] == 200" ];
    };
in
{
  config = lib.mkIf (cfg.enable && cfg.services.gatus) {
    users.groups.gatus = { };
    users.users.gatus = {
      isSystemUser = true;
      group = "gatus";
      home = "/srv/data/gatus";
      createHome = false;
    };

    services.gatus = {
      enable = true;
      settings = {
        # "web.address" is not a typed NixOS option in the pinned
        # nixos-raspberrypi nixpkgs — it's a freeform passthrough key Gatus's
        # own YAML config understands directly.
        web = {
          address = "127.0.0.1";
          port = 8080;
        };
        # Without this, Gatus keeps check history in memory only; every
        # restart (and every ephemeral-root reboot) would wipe it. Persist
        # to the encrypted /srv volume instead of the SD-backed StateDirectory.
        storage = {
          type = "sqlite";
          path = "/srv/data/gatus/gatus.db";
        };
        endpoints = [
          (endpoint {
            name = "Dashboard";
            url = "https://${cfg.domain}";
          })
        ]
        ++ lib.optional cfg.services.adguard (endpoint {
          name = "AdGuard Home";
          url = "https://${cfg.adguard.domain}";
        })
        ++ lib.optional cfg.services.beszel (endpoint {
          name = "Beszel";
          url = "https://${cfg.beszel.domain}";
        })
        ++ lib.optional cfg.services.forgejo (endpoint {
          name = "Forgejo";
          url = "https://${cfg.forgejo.domain}/api/healthz";
        })
        ++ lib.optional cfg.services.vikunja (endpoint {
          name = "Vikunja";
          url = "https://${cfg.vikunja.domain}";
        })
        ++ lib.optional cfg.services.openspeedtest (endpoint {
          name = "OpenSpeedTest";
          url = "https://${cfg.openspeedtest.domain}";
        });
      };
    };

    # Caddy's "tls internal" vhosts are signed by its own local root CA; trust
    # it so Gatus's own HTTPS checks against *.pi.lan succeed instead of
    # failing the TLS handshake in ~1ms on every endpoint (same underlying
    # fix as forgejo-runner.nix). This must be a separate root-run oneshot,
    # not gatus.service's own preStart: that unit's User/Group is "gatus"
    # (set upstream), which can't read Caddy's 0600 root.crt.
    systemd.services.gatus-ca = {
      description = "Copy Caddy's local CA for Gatus's own TLS verification";
      before = [ "gatus.service" ];
      requiredBy = [ "gatus.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = "${pkgs.coreutils}/bin/install -D -m 0644 /persist/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt /run/gatus-ca.crt";
      };
    };

    systemd.services.gatus = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # sqlite history file lives on the encrypted /srv volume, which isn't
      # mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "gatus-ca.service"
      ];
      requires = [
        "homelab-storage.target"
        "gatus-ca.service"
      ];
      environment.SSL_CERT_FILE = "/run/gatus-ca.crt";
      serviceConfig = {
        # DynamicUser's runtime-allocated UID can't be pre-chowned onto
        # /srv/data/gatus by storage.nix, so pin it to the static system user
        # above instead (upstream already names User/Group "gatus", so no
        # further override needed there).
        DynamicUser = lib.mkForce false;
        # Upstream's StateDirectory would otherwise leave an unused,
        # SD-backed /var/lib/gatus directory around; nothing should write
        # there once storage/endpoints are redirected to /srv.
        StateDirectory = lib.mkForce [ ];
        ReadWritePaths = [ "/srv/data/gatus" ];
      };
    };
  };
}
