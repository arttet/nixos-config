{ config, lib, pkgs, ... }:
let
  cfg = config.platform.homelab;
  dashboard = pkgs.linkFarm "homelab-dashboard" [
    {
      name = "index.html";
      path = ./dashboard/index.html;
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
      }
      // lib.optionalAttrs cfg.services.adguard {
        "${cfg.adguard.domain}".extraConfig = ''
          tls internal
          reverse_proxy 127.0.0.1:3000
        '';
      };
    };

    networking.firewall.extraInputRules = ''
      iifname "${cfg.lanInterface}" tcp dport { 80, 443 } accept
    '';
  };
}
