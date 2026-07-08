{ workstation, pkgs, ... }:
[
  {
    assertion =
      workstation.boot.kernelPackages.kernel.outPath == pkgs.linuxPackages_latest.kernel.outPath;
    message = "workstation uses pkgs.linuxPackages_latest";
  }
  {
    assertion = workstation.hardware.enableRedistributableFirmware;
    message = "workstation must enable redistributable firmware";
  }
  {
    assertion = workstation.hardware.cpu.intel.updateMicrocode;
    message = "workstation must enable Intel microcode updates";
  }
  {
    assertion = workstation.hardware.cpu.amd.updateMicrocode;
    message = "workstation must enable AMD microcode updates";
  }
]
