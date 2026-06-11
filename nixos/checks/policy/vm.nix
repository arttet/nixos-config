{ vm }:
[
  {
    assertion = vm.services.qemuGuest.enable;
    message = "vm must enable qemuGuest";
  }
  {
    assertion = builtins.elem "console=ttyS0,115200n8" vm.boot.kernelParams;
    message = "vm must include serial console settings";
  }
  {
    assertion = !vm.virtualisation.vmVariant.virtualisation.graphics;
    message = "vm must be headless";
  }
  {
    assertion = !vm.platform.grubTheme.enable;
    message = "vm must not enable GRUB theme";
  }
]
