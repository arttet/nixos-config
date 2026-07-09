{ desktop, ... }:
[
  {
    assertion = desktop.platform.grubTheme.enable;
    message = "desktop must enable GRUB theme";
  }
  {
    assertion =
      builtins.elem "quiet" desktop.boot.kernelParams
      && builtins.elem "fbcon=nodefer" desktop.boot.kernelParams
      && builtins.elem "plymouth.ignore-serial-consoles" desktop.boot.kernelParams
      && builtins.elem "loglevel=3" desktop.boot.kernelParams
      && builtins.elem "udev.log_level=3" desktop.boot.kernelParams
      && builtins.elem "vt.global_cursor_default=0" desktop.boot.kernelParams
      && !(builtins.elem "systemd.show_status=false" desktop.boot.kernelParams)
      && !(builtins.elem "rd.systemd.show_status=false" desktop.boot.kernelParams);
    message = "desktop must use quiet graphical boot parameters";
  }
  {
    assertion =
      desktop.platform.bootUx.earlyGraphicsDrivers == [ "amdgpu" ]
      && builtins.elem "amdgpu" desktop.boot.initrd.kernelModules
      && !(builtins.elem "i915" desktop.boot.initrd.kernelModules)
      && !(builtins.elem "nouveau" desktop.boot.initrd.kernelModules);
    message = "desktop must load amdgpu in initrd for early Plymouth DRM (override in host overlay for Intel/Nvidia)";
  }
  {
    assertion = desktop.boot.plymouth.theme == "splash";
    message = "desktop must preserve the configured Plymouth splash theme";
  }
]
