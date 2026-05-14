{ config, lib, ... }:
let
  cfg = config.platform.tuning;
in
{
  options.platform.tuning = {
    enable = lib.mkEnableOption "conservative workstation runtime tuning";

    boot.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable boot path tuning.";
    };

    network.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable conservative network baseline tuning.";
    };

    memory.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable memory pressure tuning.";
    };

    power.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable battery-friendly power tuning.";
    };

    nix.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Nix rebuild performance tuning.";
    };

    logs.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable bounded local log retention.";
    };

    ssd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SSD maintenance tuning.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.boot.enable {
        boot.loader.timeout = lib.mkDefault 2;
        systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;
      })

      (lib.mkIf cfg.power.enable {
        powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
      })

      (lib.mkIf cfg.memory.enable {
        zramSwap = {
          enable = lib.mkDefault true;
          memoryPercent = lib.mkDefault 25;
          algorithm = lib.mkDefault "zstd";
        };

        services.earlyoom.enable = lib.mkDefault true;

        boot.kernel.sysctl = {
          "vm.swappiness" = lib.mkDefault 10;
          "vm.vfs_cache_pressure" = lib.mkDefault 50;
        };
      })

      (lib.mkIf cfg.network.enable {
        boot.kernel.sysctl = {
          "net.core.default_qdisc" = lib.mkDefault "fq";
          "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr";
          "net.ipv4.tcp_fastopen" = lib.mkDefault 3;
        };
      })

      (lib.mkIf cfg.ssd.enable {
        services.fstrim.enable = lib.mkDefault true;
      })

      (lib.mkIf cfg.nix.enable {
        nix.settings = {
          max-jobs = lib.mkDefault "auto";
          cores = lib.mkDefault 0;
          auto-optimise-store = lib.mkDefault true;
          experimental-features = lib.mkDefault [
            "nix-command"
            "flakes"
          ];
        };
      })

      (lib.mkIf cfg.logs.enable {
        services.journald.extraConfig = lib.mkDefault ''
          SystemMaxUse=4G
          RuntimeMaxUse=512M
          MaxRetentionSec=1month
        '';
      })
    ]
  );
}
