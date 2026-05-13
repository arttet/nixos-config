# profiles/vpn-server.nix
{ ... }:
{
  imports = [
    ../profiles/base.nix
    ../modules/services/xray.nix
  ];

  # Services configuration
  services = {
    xray = {
      enable = true;
      settingsFile = "/etc/xray/config.json";
    };

    # nginx fallback — if connection does not look like VLESS,
    # serve real content so the port appears to be a normal HTTPS site
    nginx = {
      enable = true;
      virtualHosts."_" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8080;
            ssl = false;
          }
        ];
        locations."/" = {
          return = "200 'OK'";
          extraConfig = "add_header Content-Type text/plain;";
        };
      };
    };
  };

  # Firewall: only 443 exposed
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 443 ];
  };
}
