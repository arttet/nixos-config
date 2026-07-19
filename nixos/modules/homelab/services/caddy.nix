{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  dashboardService =
    {
      name,
      purpose,
      icon,
      color,
      host,
    }:
    {
      inherit
        name
        purpose
        icon
        color
        host
        ;
    };
  dashboardServices =
    lib.optional cfg.services.adguard (dashboardService {
      name = "DNS";
      purpose = "AdGuard Home";
      icon = "🛡️";
      color = "blue";
      host = cfg.adguard.domain;
    })
    ++ lib.optional cfg.services.beszel (dashboardService {
      name = "Monitoring";
      purpose = "Beszel";
      icon = "📊";
      color = "green";
      host = cfg.beszel.domain;
    })
    ++ lib.optional cfg.services.gatus (dashboardService {
      name = "Status";
      purpose = "Gatus";
      icon = "🚦";
      color = "cyan";
      host = cfg.gatus.domain;
    })
    ++ lib.optional cfg.services.forgejo (dashboardService {
      name = "Git";
      purpose = "Forgejo";
      icon = "🐙";
      color = "orange";
      host = cfg.forgejo.domain;
    })
    ++ lib.optional cfg.services.vikunja (dashboardService {
      name = "Tasks";
      purpose = "Vikunja";
      icon = "📋";
      color = "pink";
      host = cfg.vikunja.domain;
    })
    ++ lib.optional cfg.services.openspeedtest (dashboardService {
      name = "Speed Test";
      purpose = "OpenSpeedTest";
      icon = "⚡";
      color = "purple";
      host = cfg.openspeedtest.domain;
    });
  dashboardConfig = (pkgs.formats.json { }).generate "dashboard-config.json" {
    services = dashboardServices;
  };
  dashboard = pkgs.linkFarm "homelab-dashboard" [
    {
      name = "index.html";
      path = ./dashboard/index.html;
    }
    {
      name = "config.json";
      path = dashboardConfig;
    }
  ];
in
{
  config = lib.mkIf (cfg.enable && cfg.services.caddy) {
    systemd.tmpfiles.rules = [
      "d /persist/var/lib/caddy 0750 caddy caddy -"
    ];

    services.caddy = {
      enable = true;
      dataDir = "/persist/var/lib/caddy";
      # NixOS does not expose the Debian-style trust-store locations Caddy's
      # automatic installer expects. TLS remains handled by Caddy's local CA;
      # trust is declared explicitly in the NixOS profiles instead.
      globalConfig = ''
        skip_install_trust
      '';
      virtualHosts = {
        "${cfg.domain}".extraConfig = ''
          tls internal
          root * ${dashboard}
          file_server
        '';
        "${cfg.forgejo.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3001
        '';
        "${cfg.openspeedtest.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3002
        '';
        "${cfg.beszel.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:8090
        '';
        "${cfg.gatus.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:8080
        '';
        "${cfg.vikunja.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3456
        '';
      }
      // lib.optionalAttrs cfg.services.adguard {
        "${cfg.adguard.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3000
        '';
      };
    };

    networking.firewall.extraInputRules = ''
      # "podman1" is the bridge interface netavark assigns to the "homelab"
      # custom network (see podman-network-homelab); the forgejo-runner
      # container reaches Caddy through it via --add-host=...:host-gateway,
      # since containers on that bridge have no other route to the LAN vhosts.
      iifname { "${cfg.lanInterface}", "podman1" } tcp dport { 80, 443 } accept
    '';
  };
}
