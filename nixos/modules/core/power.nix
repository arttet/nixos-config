{ config, lib, ... }:
let
  cfg = config.platform.power;
in
{
  options.platform.power = {
    enable = lib.mkEnableOption "workstation power and battery policy";

    chargeLimit = {
      start = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 75;
        description = "Battery charge threshold where charging may resume.";
      };

      stop = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 80;
        description = "Battery charge threshold where charging should stop.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.chargeLimit.start < cfg.chargeLimit.stop;
        message = "platform.power.chargeLimit.start must be lower than platform.power.chargeLimit.stop.";
      }
    ];

    services.upower = {
      enable = lib.mkDefault true;
      usePercentageForPolicy = lib.mkDefault true;
      percentageLow = lib.mkDefault 20;
      percentageCritical = lib.mkDefault 10;
      percentageAction = lib.mkDefault 5;
      criticalPowerAction = lib.mkDefault "PowerOff";
    };

    services.power-profiles-daemon.enable = lib.mkForce false;

    services.tlp = {
      enable = lib.mkDefault true;
      settings = {
        START_CHARGE_THRESH_BAT0 = lib.mkDefault cfg.chargeLimit.start;
        STOP_CHARGE_THRESH_BAT0 = lib.mkDefault cfg.chargeLimit.stop;
        START_CHARGE_THRESH_BAT1 = lib.mkDefault cfg.chargeLimit.start;
        STOP_CHARGE_THRESH_BAT1 = lib.mkDefault cfg.chargeLimit.stop;

        CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkDefault "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = lib.mkDefault "power";
        CPU_BOOST_ON_AC = lib.mkDefault 1;
        CPU_BOOST_ON_BAT = lib.mkDefault 0;
        PLATFORM_PROFILE_ON_AC = lib.mkDefault "balanced";
        PLATFORM_PROFILE_ON_BAT = lib.mkDefault "low-power";
        RUNTIME_PM_ON_AC = lib.mkDefault "on";
        RUNTIME_PM_ON_BAT = lib.mkDefault "auto";
      };
    };

    services.logind.settings.Login = {
      HandleLidSwitch = lib.mkDefault "suspend";
      HandleLidSwitchExternalPower = lib.mkDefault "lock";
      HandleLidSwitchDocked = lib.mkDefault "ignore";
      HandlePowerKey = lib.mkDefault "poweroff";
    };

    systemd.sleep.settings.Sleep = {
      AllowHibernation = lib.mkDefault false;
      AllowHybridSleep = lib.mkDefault false;
      AllowSuspendThenHibernate = lib.mkDefault false;
    };
  };
}
