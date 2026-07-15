{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  passwordHashFile = "/persist/etc/homelab/adguard-password.hash";
  yaml = pkgs.formats.yaml { };
  publicConfig = yaml.generate "adguardhome-public.yaml" {
    http.address = "0.0.0.0:3000";
    dns = {
      bind_hosts = [ "0.0.0.0" ];
      port = 53;
      upstream_dns = cfg.adguard.upstreamDns;
      querylog_enabled = true;
      querylog_file_enabled = false;
    };
    dhcp.enabled = false;
    schema_version = 29;
  };
  renderConfig = pkgs.writeTextFile {
    name = "render-adguardhome-config";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu

      destination="/var/lib/adguardhome/AdGuardHome.yaml"
      mkdir -p "$(${pkgs.coreutils}/bin/dirname "$destination")"
      ${pkgs.coreutils}/bin/chown adguard:adguard "$(${pkgs.coreutils}/bin/dirname "$destination")"
      ${pkgs.coreutils}/bin/chmod 700 "$(${pkgs.coreutils}/bin/dirname "$destination")"

      # Only seed the initial config once: AdGuardHome owns this file after
      # first start (schema migrations, UI-driven settings changes), so
      # re-rendering it on every boot would silently wipe those.
      if [ -f "$destination" ]; then
        exit 0
      fi

      if [ ! -f "${passwordHashFile}" ]; then
        printf 'AdGuard administrator password hash file is missing at %s\n' "${passwordHashFile}" >&2
        printf 'Please run "doas homelab-adguard-password-set" first to generate it.\n' >&2
        exit 1
      fi
      hash="$(${pkgs.coreutils}/bin/cat ${passwordHashFile} | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [ -z "$hash" ]; then
        printf 'AdGuard administrator password hash is empty\n' >&2
        exit 1
      fi
      case "$hash" in
        '$2'*) ;;
        *)
          printf 'AdGuard administrator password must be a bcrypt hash\n' >&2
          exit 1
          ;;
      esac
      ${pkgs.coreutils}/bin/cat ${publicConfig} > "$destination"
      {
        printf 'users:\n'
        printf '  - name: admin\n'
        printf '    password: "%s"\n' "$hash"
      } >> "$destination"
      ${pkgs.coreutils}/bin/chown adguard:adguard "$destination"
      ${pkgs.coreutils}/bin/chmod 600 "$destination"
    '';
  };
  setPassword = pkgs.writeTextFile {
    name = "homelab-adguard-password-set";
    destination = "/bin/homelab-adguard-password-set";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu

      hash_file="${passwordHashFile}"
      generated="$(${pkgs.apacheHttpd}/bin/htpasswd -nBC 12 admin)"
      hash="$(printf '%s\n' "$generated" | ${pkgs.gnused}/bin/sed 's/^admin://;s/^[[:space:]]*//;s/[[:space:]]*$//')"
      case "$hash" in
        '$2'*) ;;
        *)
          printf 'htpasswd did not produce a bcrypt verifier\n' >&2
          exit 1
          ;;
      esac
      mkdir -p "$(${pkgs.coreutils}/bin/dirname "$hash_file")"
      ${pkgs.coreutils}/bin/chmod 700 "$(${pkgs.coreutils}/bin/dirname "$hash_file")"
      printf '%s\n' "$hash" > "$hash_file"
      ${pkgs.coreutils}/bin/chmod 600 "$hash_file"
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.services.adguard) {
    environment.systemPackages = [ setPassword ];

    users.groups.adguard = { };
    users.users.adguard = {
      isSystemUser = true;
      group = "adguard";
      home = "/var/lib/adguardhome";
      createHome = false;
    };
    networking.firewall.extraInputRules = ''
      ip saddr ${cfg.lanCidr} udp dport 53 accept
      ip saddr ${cfg.lanCidr} tcp dport { 53, 3000 } accept
    '';

    services.resolved.extraConfig = ''
      DNS=127.0.0.1 1.1.1.1 8.8.8.8
      DNSStubListener=no
    '';
    environment.etc."resolv.conf".source = lib.mkForce "/run/systemd/resolve/resolv.conf";

    systemd.services.adguardhome-config = {
      description = "Render immutable AdGuard Home configuration";
      before = [ "adguardhome.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        UMask = "0077";
        ExecStart = "${renderConfig}";
      };
    };

    systemd.services.adguardhome = {
      description = "AdGuard Home DNS server";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "adguardhome-config.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "adguardhome-config.service" ];
      serviceConfig = {
        Type = "simple";
        User = "adguard";
        Group = "adguard";
        ExecStart = "${pkgs.adguardhome}/bin/AdGuardHome --no-check-update --config /var/lib/adguardhome/AdGuardHome.yaml --work-dir /var/lib/adguardhome";
        Restart = "on-failure";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        NoNewPrivileges = true;
      };
    };
  };
}
