{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.platform.homelab;
  influxTokenFile = "/srv/data/scrutiny/web/influx-admin-token";
  influxPasswordFile = "/srv/data/scrutiny/web/influx-admin-password";
  influxOrg = "homelab";
  influxBucket = "scrutiny";
in
{
  config = lib.mkIf (cfg.enable && cfg.services.scrutiny) {
    users.groups.scrutiny = { };
    users.users.scrutiny = {
      isSystemUser = true;
      group = "scrutiny";
      home = "/srv/data/scrutiny/web";
      createHome = false;
    };

    services.scrutiny = {
      enable = true;
      settings = {
        web.listen = {
          host = "127.0.0.1";
          # Upstream default (0.0.0.0:8080) collides with Gatus's loopback
          # 8080; moved here instead.
          port = 8084;
        };
        web.influxdb = {
          host = "127.0.0.1";
          org = influxOrg;
          bucket = influxBucket;
          # The upstream module rejects an attrset here (its type is `null or
          # string`), so we use a placeholder and inject the real token from the
          # file in a preStart step after the upstream module generates
          # /run/scrutiny/config.yaml. The placeholder is not a secret.
          token = "__INFLUX_ADMIN_TOKEN__";
        };
        # collector.enable defaults to cfg.enable (auto-on) and needs no
        # device list — smartctl/smartd auto-detect attached block devices.
        # Real caveat, not fixable in Nix: the Pi boots from SD (no SMART
        # support) and /srv sits on whatever backs the LUKS container; SMART
        # over USB depends entirely on that enclosure's SAT-passthrough
        # support. Verify what Scrutiny actually finds on real hardware.
      };
      # Upstream defaults the collector timer to "daily", which leaves the
      # dashboard empty for up to a day after boot; hourly keeps SMART data
      # fresh without meaningful load (attributes change slowly). The timer
      # is Persistent, so a run missed while /srv was locked fires on unlock.
      collector.schedule = "hourly";
    };

    systemd.services.scrutiny = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "influxdb2.service"
      ];
      requires = [ "homelab-storage.target" ];
      environment.SCRUTINY_WEB_DATABASE_LOCATION = lib.mkForce "/srv/data/scrutiny/web/scrutiny.db";
      unitConfig.ConditionPathExists = influxTokenFile;
      serviceConfig = {
        # DynamicUser's runtime-allocated UID can't be pre-chowned onto
        # /srv/data/scrutiny/web by storage.nix; pin the static user above
        # instead (upstream defines no static user at all).
        DynamicUser = lib.mkForce false;
        User = "scrutiny";
        Group = "scrutiny";
        # StateDirectory would otherwise create/use an unused, SD-backed
        # /var/lib/scrutiny; SCRUTINY_WEB_DATABASE_LOCATION above already
        # redirects the database to /srv.
        StateDirectory = lib.mkForce [ ];
      };

      # Run after the upstream preStart that generates $RUNTIME_DIRECTORY/config.yaml.
      preStart = lib.mkAfter ''
        token_file=${lib.escapeShellArg influxTokenFile}
        token_value="$(${pkgs.coreutils}/bin/cat "$token_file")"
        ${pkgs.gnused}/bin/sed -i \
          "s|__INFLUX_ADMIN_TOKEN__|$token_value|" \
          "$RUNTIME_DIRECTORY/config.yaml"
      '';
    };

    # InfluxDB2 stores its bolt + engine on /srv via a bind mount created by
    # homelab-storage-unlock (/srv/data/scrutiny/influxdb2 -> /var/lib/influxdb2),
    # so the upstream unit's default ExecStart and StateDirectory stay intact.
    # This is cleaner than the previous ExecStart override, which broke the
    # module's provision/preStart logic and made the $STATE_DIRECTORY path
    # unreliable.
    services.influxdb2 = {
      enable = true;
      settings = {
        "http-bind-address" = "127.0.0.1:8086";
      };
      provision = {
        enable = true;
        initialSetup = {
          organization = influxOrg;
          bucket = influxBucket;
          username = "admin";
          passwordFile = influxPasswordFile;
          tokenFile = influxTokenFile;
        };
      };
    };

    systemd.services.influxdb2 = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [
        "homelab-storage.target"
        "network.target"
      ];
      requires = [ "homelab-storage.target" ];
      unitConfig.ConditionPathExists = [
        influxPasswordFile
        influxTokenFile
      ];
    };
  };
}
