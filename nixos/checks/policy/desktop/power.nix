{ desktop, workstation, ... }:
[
  {
    assertion = !workstation.platform.power.enable;
    message = "headless workstation must not enable desktop power policy";
  }
  {
    assertion = desktop.platform.power.enable;
    message = "desktop must enable platform power policy";
  }
  {
    assertion = desktop.services.upower.enable;
    message = "desktop must enable UPower through the power layer";
  }
  {
    assertion = desktop.services.upower.criticalPowerAction == "PowerOff";
    message = "desktop low battery action must be PowerOff";
  }
  {
    assertion = desktop.services.tlp.enable;
    message = "desktop must enable TLP through the power layer";
  }
  {
    assertion = !desktop.services.power-profiles-daemon.enable;
    message = "desktop must use TLP instead of power-profiles-daemon";
  }
  {
    assertion =
      desktop.services.tlp.settings.STOP_CHARGE_THRESH_BAT0 == 80
      && desktop.services.tlp.settings.START_CHARGE_THRESH_BAT0 == 75
      && desktop.services.tlp.settings.PLATFORM_PROFILE_ON_BAT == "low-power";
    message = "desktop TLP charge and profile policy changed unexpectedly";
  }
  {
    assertion =
      desktop.systemd.sleep.settings.Sleep.AllowHibernation == false
      && desktop.systemd.sleep.settings.Sleep.AllowHybridSleep == false
      && desktop.systemd.sleep.settings.Sleep.AllowSuspendThenHibernate == false;
    message = "desktop must explicitly disable hibernation modes";
  }
]
