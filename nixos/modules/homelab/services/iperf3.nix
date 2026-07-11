{
  config,
  lib,
  ...
}:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.iperf3) {
    services.iperf3 = {
      enable = true;
      openFirewall = false;
    };
    networking.firewall.extraInputRules = ''
      ip saddr ${cfg.lanCidr} tcp dport 5201 accept
      ip saddr ${cfg.lanCidr} udp dport 5201 accept
    '';
  };
}
