{ workstation, vm, ... }:
[
  {
    assertion = !workstation.services.qemuGuest.enable;
    message = "workstation must not enable qemuGuest";
  }
  {
    assertion = !(builtins.elem "console=ttyS0,115200n8" workstation.boot.kernelParams);
    message = "workstation must not include VM serial console settings";
  }
  {
    assertion = workstation.boot.loader.grub.enable;
    message = "workstation must enable GRUB";
  }
  {
    assertion = workstation.boot.loader.grub.device == "nodev";
    message = "workstation GRUB must target UEFI nodev";
  }
  {
    assertion = workstation.boot.loader.grub.efiSupport;
    message = "workstation GRUB must enable EFI support";
  }
  {
    assertion = !workstation.boot.loader.grub.useOSProber;
    message = "workstation must disable OS prober";
  }
  {
    assertion = workstation.boot.loader.grub.configurationLimit == 10;
    message = "workstation GRUB must keep 10 boot generations";
  }
  {
    assertion = workstation.boot.initrd.systemd.enable;
    message = "workstation must enable systemd initrd";
  }
  {
    assertion = workstation.platform.bootUx.enable;
    message = "workstation must enable graphical boot UX";
  }
  {
    assertion = !vm.platform.bootUx.enable;
    message = "vm must keep graphical boot UX disabled";
  }
  {
    assertion = workstation.boot.plymouth.enable;
    message = "workstation must enable Plymouth for graphical LUKS prompt";
  }
  {
    assertion =
      builtins.elem "splash" workstation.boot.kernelParams
      && !(builtins.elem "quiet" workstation.boot.kernelParams);
    message = "workstation must enable splash without forcing quiet boot";
  }
  {
    assertion = workstation.boot.loader.efi.canTouchEfiVariables;
    message = "workstation must allow EFI variable updates";
  }
  {
    assertion = workstation.boot.loader.timeout == 2;
    message = "workstation GRUB timeout must be 2 seconds";
  }
]
