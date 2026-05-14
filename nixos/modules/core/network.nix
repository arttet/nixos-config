{ config, lib, ... }:
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
    networking.networkmanager = {
      enable = lib.mkDefault true;
      dns = lib.mkDefault "systemd-resolved";
    };

    services.resolved = lib.mkIf cfg.dns.enable {
      enable = lib.mkDefault true;
      settings.Resolve = {
        DNSSEC = lib.mkDefault "true";
        DNSOverTLS = lib.mkDefault "true";
        Domains = lib.mkDefault [ "~." ];
        FallbackDNS = lib.mkDefault [
          "1.1.1.1#cloudflare-dns.com"
          "1.0.0.1#cloudflare-dns.com"
        ];
      };
    };
  };
}
