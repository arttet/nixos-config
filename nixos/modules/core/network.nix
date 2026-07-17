{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.network;
in
{
  options.platform.network = {
    enable = lib.mkEnableOption "explicit workstation network baseline";

    dns.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable explicit systemd-resolved DNS policy.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dnsutils
      iputils
      openvpn
      openssl
      q
      tor
      traceroute
      wireguard-tools
    ];

    networking.networkmanager = {
      enable = lib.mkDefault true;
      dns = lib.mkDefault "systemd-resolved";
    };

    # Always-on DNS-over-HTTPS via local dnsproxy
    services.dnsproxy = {
      enable = true;
      settings = {
        upstream = [
          # pi.lan is only known to the homelab AdGuard, not to any public
          # DNS our default upstreams below actually query. dnsproxy's
          # conditional-forwarding syntax ("[/domain/]server") routes the
          # whole zone there, subdomains included, so new *.pi.lan services
          # never need a config change here again (unlike the previous
          # /etc/hosts allowlist this replaces, which needed a new line per
          # hostname).
          "[/pi.lan/]192.168.0.53"
          "https://1.1.1.1/dns-query"
          "https://1.0.0.1/dns-query"
        ];
        bootstrap = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        listen-addrs = [
          "127.0.0.1"
          "::1"
        ];
        listen-ports = [ 53 ];
        cache = true;
        cache-size = 4096;
        cache-min-ttl = 300;
        cache-max-ttl = 3600;
        # Fallback to Google DNS if Cloudflare DoH fails
        fallback = [
          "8.8.8.8:53"
          "8.8.4.4:53"
        ];
      };
    };

    # Point systemd-resolved to local dnsproxy
    services.resolved = lib.mkIf cfg.dns.enable {
      enable = lib.mkDefault true;
      settings.Resolve = {
        DNSSEC = lib.mkDefault "true";
        # DoH is handled by dnsproxy; disable DoT in resolved
        DNSOverTLS = lib.mkDefault "false";
        Domains = lib.mkDefault [ "~." ];
        DNS = lib.mkDefault [ "127.0.0.1" ];
        FallbackDNS = lib.mkDefault [
          "8.8.8.8"
          "8.8.4.4"
        ];
      };
    };

    # Ensure dnsproxy starts before resolved
    systemd.services.dnsproxy = {
      after = [ "network.target" ];
      before = [ "systemd-resolved.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
