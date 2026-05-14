{ config, lib, ... }:
let
  cfg = config.platform.security;
in
{
  options.platform.security = {
    enable = lib.mkEnableOption "baseline workstation kernel hardening";

    disableThunderbolt = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Blacklist Thunderbolt/USB4 kernel support by default.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.journald.storage = lib.mkDefault "persistent";

    security.sudo.enable = lib.mkDefault false;
    security.doas = {
      enable = lib.mkDefault true;
      extraRules = [
        {
          groups = [ "wheel" ];
          noPass = false;
          persist = false;
          keepEnv = false;
        }
      ];
    };

    security.protectKernelImage = lib.mkDefault true;
    security.forcePageTableIsolation = lib.mkDefault true;

    boot.tmp = {
      useTmpfs = lib.mkDefault true;
      cleanOnBoot = lib.mkDefault true;
    };

    boot.blacklistedKernelModules = lib.mkIf cfg.disableThunderbolt [
      "thunderbolt"
    ];

    boot.kernel.sysctl = {
      "kernel.perf_event_paranoid" = lib.mkDefault 3;
      "user.max_user_namespaces" = lib.mkDefault 0;
    };
  };
}
