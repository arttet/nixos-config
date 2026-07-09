{ workstation, vm, ... }:
[
  {
    assertion = workstation.platform.tuning.enable;
    message = "workstation must enable platform tuning";
  }
  {
    assertion = !vm.platform.tuning.enable;
    message = "vm must keep workstation tuning disabled";
  }
  {
    assertion = workstation.powerManagement.cpuFreqGovernor == "powersave";
    message = "workstation must use powersave governor";
  }
  {
    assertion = workstation.zramSwap.enable;
    message = "workstation must enable zram";
  }
  {
    assertion = workstation.zramSwap.memoryPercent == 25;
    message = "workstation zram memoryPercent must be 25";
  }
  {
    assertion = workstation.zramSwap.algorithm == "zstd";
    message = "workstation zram algorithm must be zstd";
  }
  {
    assertion = workstation.services.earlyoom.enable;
    message = "workstation must enable earlyoom";
  }
  {
    assertion = workstation.boot.kernel.sysctl."vm.swappiness" == 10;
    message = "workstation swappiness must be 10";
  }
  {
    assertion = workstation.boot.kernel.sysctl."vm.vfs_cache_pressure" == 50;
    message = "workstation vfs_cache_pressure must be 50";
  }
  {
    assertion = workstation.boot.kernel.sysctl."net.core.default_qdisc" == "fq";
    message = "workstation default qdisc must be fq";
  }
  {
    assertion = workstation.boot.kernel.sysctl."net.ipv4.tcp_congestion_control" == "bbr";
    message = "workstation TCP congestion control must be bbr";
  }
  {
    assertion = workstation.boot.kernel.sysctl."net.ipv4.tcp_fastopen" == 3;
    message = "workstation tcp_fastopen must be 3";
  }
  {
    assertion = workstation.services.fstrim.enable;
    message = "workstation must enable fstrim";
  }
]
