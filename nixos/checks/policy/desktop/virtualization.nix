{ desktop, ... }:
[
  {
    assertion = desktop.virtualisation.docker.enable;
    message = "desktop must enable Docker";
  }
  {
    assertion = desktop.virtualisation.podman.enable;
    message = "desktop must enable Podman";
  }
  {
    assertion = desktop.virtualisation.libvirtd.enable;
    message = "desktop must enable libvirtd";
  }
  {
    assertion = desktop.programs.virt-manager.enable;
    message = "desktop must enable virt-manager";
  }
]
