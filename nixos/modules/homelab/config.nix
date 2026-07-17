{
  config,
  lib,
  ...
}:
let
  cfg = config.platform.homelab;
  state = config.platform.state.data.homelab or { };
  stateStorage = state.storage or { };
  stateServices = state.services or { };
  stateAdguard = state.adguard or { };
  stateForgejo = state.forgejo or { };
  stateOpenSpeedTest = state.openspeedtest or { };
  stateBeszel = state.beszel or { };
  stateSamba = state.samba or { };
  stateGatus = state.gatus or { };
  stateVikunja = state.vikunja or { };
  serviceNames = [
    "adguard"
    "beszel"
    "caddy"
    "forgejo"
    "forgejoRunner"
    "gatus"
    "iperf3"
    "openspeedtest"
    "podman"
    "samba"
    "vikunja"
    "wireguard"
  ];
in
{
  options.platform.homelab = {
    enable = lib.mkEnableOption "Raspberry Pi homelab server policy";

    lanCidr = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "IPv4 CIDR allowed to reach LAN-only homelab services.";
    };

    configVersion = lib.mkOption {
      type = lib.types.str;
      default = "development";
      description = "Build version exposed by the homelab runtime status.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "pi.lan";
      description = "Base local DNS domain for the homelab.";
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "end0";
      description = "Primary LAN interface used for interface-scoped firewall policy.";
    };

    storage = {
      luksDevice = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Stable by-UUID path of the existing LUKS2 container.";
      };
      mapperName = lib.mkOption {
        type = lib.types.str;
        default = "homelab-data";
        description = "Device-mapper name used when unlocking homelab storage.";
      };
      fileSystemType = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Expected existing filesystem inside the LUKS2 container.";
      };
    };

    services = lib.genAttrs serviceNames (name: lib.mkEnableOption "the homelab ${name} service");

    adguard = {
      upstreamDns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "AdGuard Home upstream DNS resolvers.";
      };
      domain = lib.mkOption {
        type = lib.types.str;
        default = "dns.pi.lan";
        description = "AdGuard Home public virtual host served by Caddy.";
      };
    };

    forgejo = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "git.pi.lan";
        description = "Forgejo public virtual host served by Caddy.";
      };
      runnerEnvironmentFile = lib.mkOption {
        type = lib.types.str;
        default = "/srv/secrets/forgejo-runner.env";
        description = "Runtime-only Forgejo runner environment file on encrypted storage.";
      };
    };

    openspeedtest.domain = lib.mkOption {
      type = lib.types.str;
      default = "speed.pi.lan";
      description = "OpenSpeedTest public virtual host served by Caddy.";
    };

    beszel = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "monitor.pi.lan";
        description = "Beszel public virtual host served by Caddy.";
      };
      agentEnvironmentFile = lib.mkOption {
        type = lib.types.str;
        default = "/srv/secrets/beszel-agent.env";
        description = "Runtime-only Beszel agent environment file on encrypted storage.";
      };
    };

    samba.shares = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Samba share names mapped to their absolute directory paths, all served under the homelab `samba` account.";
    };

    gatus.domain = lib.mkOption {
      type = lib.types.str;
      default = "status.pi.lan";
      description = "Gatus public virtual host served by Caddy.";
    };

    vikunja = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "tasks.pi.lan";
        description = "Vikunja public virtual host served by Caddy.";
      };
      environmentFile = lib.mkOption {
        type = lib.types.str;
        default = "/srv/secrets/vikunja.env";
        description = "Runtime-only Vikunja JWT secret environment file on encrypted storage.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    platform.homelab = {
      lanCidr = lib.mkDefault (state.lanCidr or "");
      domain = lib.mkDefault (state.domain or "pi.lan");
      lanInterface = lib.mkDefault (state.lanInterface or "end0");
      storage = {
        luksDevice = lib.mkDefault (stateStorage.luksDevice or "");
        mapperName = lib.mkDefault (stateStorage.mapperName or "homelab-data");
        fileSystemType = lib.mkDefault (stateStorage.fileSystemType or "");
      };
      services = lib.genAttrs serviceNames (name: lib.mkDefault (stateServices.${name} or true));
      adguard = {
        upstreamDns = lib.mkDefault (
          stateAdguard.upstreamDns or [
            "https://cloudflare-dns.com/dns-query"
            "https://dns.google/dns-query"
          ]
        );
        domain = lib.mkDefault (stateAdguard.domain or "dns.pi.lan");
      };
      forgejo = {
        domain = lib.mkDefault (stateForgejo.domain or "git.pi.lan");
        runnerEnvironmentFile = lib.mkDefault (
          stateForgejo.runnerEnvironmentFile or "/srv/secrets/forgejo-runner.env"
        );
      };
      openspeedtest.domain = lib.mkDefault (stateOpenSpeedTest.domain or "speed.pi.lan");
      beszel = {
        domain = lib.mkDefault (stateBeszel.domain or "monitor.pi.lan");
        agentEnvironmentFile = lib.mkDefault (
          stateBeszel.agentEnvironmentFile or "/srv/secrets/beszel-agent.env"
        );
      };
      samba.shares = lib.mkDefault (
        stateSamba.shares or {
          Multimedia = "/srv/samba/shared/Multimedia";
          Artyom = "/srv/samba/shared/Artyom";
        }
      );
      gatus.domain = lib.mkDefault (stateGatus.domain or "status.pi.lan");
      vikunja = {
        domain = lib.mkDefault (stateVikunja.domain or "tasks.pi.lan");
        environmentFile = lib.mkDefault (stateVikunja.environmentFile or "/srv/secrets/vikunja.env");
      };
    };

    assertions = [
      {
        assertion = state != { };
        message = "homelab-rpi5 requires platform state homelab configuration.";
      }
      {
        assertion =
          builtins.match "([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])" cfg.lanCidr != null;
        message = "platform state homelab.lanCidr must be an IPv4 CIDR.";
      }
      {
        assertion =
          builtins.match "/dev/disk/by-uuid/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" cfg.storage.luksDevice
          != null;
        message = "homelab storage must use a stable /dev/disk/by-uuid path.";
      }
      {
        assertion =
          builtins.match "[A-Za-z0-9][A-Za-z0-9_.-]{0,126}" cfg.storage.mapperName != null
          && builtins.elem cfg.storage.fileSystemType [
            "btrfs"
            "ext4"
            "xfs"
          ];
        message = "homelab storage mapper name and filesystem type are invalid.";
      }
      {
        assertion = !cfg.services.adguard || cfg.adguard.upstreamDns != [ ];
        message = "homelab AdGuard requires at least one upstream DNS server.";
      }
      {
        assertion =
          !cfg.services.forgejoRunner
          || (
            builtins.match "/.*" cfg.forgejo.runnerEnvironmentFile != null
            && builtins.match "/nix/store/.*" cfg.forgejo.runnerEnvironmentFile == null
          );
        message = "homelab Forgejo runner environment file must be an absolute runtime path outside the Nix store.";
      }
      {
        assertion =
          !cfg.services.beszel
          || (
            builtins.match "/.*" cfg.beszel.agentEnvironmentFile != null
            && builtins.match "/nix/store/.*" cfg.beszel.agentEnvironmentFile == null
          );
        message = "homelab Beszel agent environment file must be an absolute runtime path outside the Nix store.";
      }
      {
        assertion =
          !cfg.services.vikunja
          || (
            builtins.match "/.*" cfg.vikunja.environmentFile != null
            && builtins.match "/nix/store/.*" cfg.vikunja.environmentFile == null
          );
        message = "homelab Vikunja environment file must be an absolute runtime path outside the Nix store.";
      }
      {
        assertion =
          !cfg.services.samba
          || lib.all (path: builtins.match "/.*" path != null) (lib.attrValues cfg.samba.shares);
        message = "homelab samba share paths must be absolute.";
      }
    ];
  };
}
