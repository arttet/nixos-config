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
      group,
      # selfh.st icon slug (https://selfh.st/icons), rendered via CDN with an
      # automatic fallback to `icon` (emoji) on load failure — best-effort,
      # a wrong/missing slug degrades silently, never breaks the page.
      img ? null,
    }:
    {
      inherit
        name
        purpose
        icon
        color
        host
        group
        img
        ;
    };
  dashboardServices =
    lib.optional cfg.services.adguard (dashboardService {
      name = "DNS";
      purpose = "AdGuard Home";
      icon = "🛡️";
      color = "blue";
      host = cfg.adguard.domain;
      group = "Network & Monitoring";
      img = "adguard-home";
    })
    ++ lib.optional cfg.services.beszel (dashboardService {
      name = "Monitoring";
      purpose = "Beszel";
      icon = "📊";
      color = "green";
      host = cfg.beszel.domain;
      group = "Network & Monitoring";
      img = "beszel";
    })
    ++ lib.optional cfg.services.gatus (dashboardService {
      name = "Status";
      purpose = "Gatus";
      icon = "🚦";
      color = "cyan";
      host = cfg.gatus.domain;
      group = "Network & Monitoring";
      img = "gatus";
    })
    ++ lib.optional cfg.services.forgejo (dashboardService {
      name = "Git";
      purpose = "Forgejo";
      icon = "🐙";
      color = "orange";
      host = cfg.forgejo.domain;
      group = "Development";
      img = "forgejo";
    })
    ++ lib.optional cfg.services.vikunja (dashboardService {
      name = "Tasks";
      purpose = "Vikunja";
      icon = "📋";
      color = "pink";
      host = cfg.vikunja.domain;
      group = "Development";
      img = "vikunja";
    })
    ++ lib.optional cfg.services.openspeedtest (dashboardService {
      name = "Speed Test";
      purpose = "OpenSpeedTest";
      icon = "⚡";
      color = "purple";
      host = cfg.openspeedtest.domain;
      group = "Tools";
      img = "openspeedtest";
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
    {
      name = "waiting.html";
      path = ./dashboard/waiting.html;
    }
  ];
  # Every reverse-proxied vhost shares this body: proxy to the backend, and
  # fall back to the static "storage not unlocked" page (served from the same
  # linkFarm as the dashboard) if it's unreachable — e.g. before
  # homelab-storage-unlock has started it. No Caddy restart is needed once
  # the backend comes up: reverse_proxy has no health-check state to reset,
  # it just tries the real connection again on the next request.
  #
  # The CORS header exists solely so the dashboard (served from cfg.domain)
  # can read the real HTTP status code of a cross-origin health-check fetch.
  # Without it, the dashboard would have to fetch with mode:"no-cors", whose
  # opaque response hides the status entirely — a 502 from the fallback page
  # above and a real 200 look identical, so every service reports "up" the
  # moment Caddy itself answers, storage unlocked or not. Set it after the
  # backend response so it also replaces wildcard CORS headers emitted by
  # services such as Beszel and Actual, leaving one valid dashboard origin.
  # This only exposes numeric status to our own dashboard origin, not response
  # bodies or cookies (health-check fetches never send credentials).
  proxyVhost = port: ''
    tls internal
    header >Access-Control-Allow-Origin "https://${cfg.domain}"
    reverse_proxy 127.0.0.1:${toString port}
    import homelab_fallback
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.services.caddy) {
    systemd.tmpfiles.rules = [
      "d /persist/var/lib/caddy 0750 caddy caddy -"
    ];

    services.caddy = {
      enable = true;
      dataDir = "/persist/var/lib/caddy";
      # Caddy's local CA otherwise tries to install itself into the host's
      # system trust store (via certutil/tee) on every start; that's a
      # Debian/Ubuntu-oriented convenience NixOS doesn't lay out the same
      # way, so it always fails harmlessly. TLS itself doesn't need this —
      # "tls internal" works purely from Caddy's own CA regardless — so just
      # stop it from trying.
      globalConfig = ''
        skip_install_trust
      '';
      # Defines (homelab_fallback), imported by every reverse-proxied vhost
      # below: catches a backend being unreachable (e.g. storage not unlocked
      # yet) and serves the static waiting page instead of a raw 502.
      extraConfig = ''
        (homelab_fallback) {
          handle_errors {
            @unreachable expression {err.status_code} >= 500
            handle @unreachable {
              root * ${dashboard}
              rewrite * /waiting.html
              file_server
            }
          }
        }
      '';
      virtualHosts = {
        "${cfg.domain}".extraConfig = ''
          tls internal
          root * ${dashboard}
          file_server
        '';
        "${cfg.forgejo.domain}".extraConfig = proxyVhost 3001;
        "${cfg.openspeedtest.domain}".extraConfig = proxyVhost 3002;
        "${cfg.beszel.domain}".extraConfig = proxyVhost 8090;
        "${cfg.gatus.domain}".extraConfig = proxyVhost 8080;
        "${cfg.vikunja.domain}".extraConfig = proxyVhost 3456;
      }
      // lib.optionalAttrs cfg.services.adguard {
        "${cfg.adguard.domain}".extraConfig = proxyVhost 3000;
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
