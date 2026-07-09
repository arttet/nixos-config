{
  config,
  lib,
  ...
}:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf cfg.enable {
    networking = {
      useDHCP = false;
      interfaces = {
        "${cfg.lanInterface}".useDHCP = true;
        eth0.useDHCP = lib.mkDefault true;
      };
      nftables.enable = true;
      firewall.trustedInterfaces = [ ];
    };

    services.resolved = {
      enable = true;
      extraConfig = ''
        MulticastDNS=yes
      '';
    };
  };
}
