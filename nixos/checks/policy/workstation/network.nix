{ workstation, vm, ... }:
[
  {
    assertion = workstation.platform.network.enable;
    message = "workstation must enable platform network policy";
  }
  {
    assertion = !vm.platform.network.enable;
    message = "vm must keep workstation network policy disabled";
  }
  {
    assertion = workstation.networking.networkmanager.enable;
    message = "workstation must enable NetworkManager";
  }
  {
    assertion = workstation.networking.networkmanager.dns == "systemd-resolved";
    message = "workstation NetworkManager must use systemd-resolved";
  }
  {
    assertion = workstation.services.resolved.enable;
    message = "workstation must enable systemd-resolved";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.DNSSEC == "true";
    message = "workstation resolved dnssec must be true";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.DNSOverTLS == "false";
    message = "workstation resolved dnsovertls must be false (DoH via dnsproxy)";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.Domains == [ "~." ];
    message = "workstation resolved domains must route through explicit DNS policy";
  }
  {
    assertion = workstation.services.resolved.settings.Resolve.DNS == [ "127.0.0.1" ];
    message = "workstation resolved DNS must point to local dnsproxy";
  }
  {
    assertion =
      workstation.services.resolved.settings.Resolve.FallbackDNS == [
        "8.8.8.8"
        "8.8.4.4"
      ];
    message = "workstation fallback DNS must use Google DNS";
  }
  {
    assertion = workstation.services.dnsproxy.enable;
    message = "workstation must enable dnsproxy for DoH";
  }
  {
    assertion = workstation.services.timesyncd.enable;
    message = "workstation must enable timesyncd";
  }
  {
    assertion = !workstation.systemd.services.NetworkManager-wait-online.enable;
    message = "workstation must not wait for network-online during boot";
  }
]
