{
  config,
  lib,
  ...
}:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.cockpit) {
    services.cockpit = {
      enable = true;
      port = 9090;
      allowed-origins = [ "https://${cfg.cockpit.domain}" ];
      settings.WebService = {
        # Caddy terminates TLS and proxies plain HTTP to cockpit on loopback.
        # ProtocolHeader lets cockpit learn the original scheme was https;
        # AllowUnencrypted stops it treating the loopback HTTP hop as insecure
        # (which otherwise yields a blank/broken page behind the proxy). The
        # connection is still only reachable from localhost + the LAN via
        # Caddy's HTTPS vhost, never unencrypted off-box.
        ProtocolHeader = "X-Forwarded-Proto";
        AllowUnencrypted = true;
      };
    };

    # Keep the management UI on loopback only; Caddy terminates TLS and proxies
    # to it. The upstream module listens on all interfaces by default.
    systemd.sockets.cockpit = {
      listenStreams = lib.mkForce [
        ""
        "127.0.0.1:9090"
      ];
    };
  };
}
