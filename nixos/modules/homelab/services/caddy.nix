{ config, lib, ... }:
let
  cfg = config.platform.homelab;
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
      };
    };

    networking.firewall.extraInputRules = ''
      iifname "${cfg.lanInterface}" tcp dport { 80, 443 } accept
    '';
  };
}
