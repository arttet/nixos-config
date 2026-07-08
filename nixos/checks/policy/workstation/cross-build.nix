{ workstation, ... }:
[
  {
    assertion = workstation.platform.crossBuild.enable;
    message = "workstation must enable cross-build binfmt emulation";
  }
  {
    assertion = workstation.platform.crossBuild.emulatedSystems == [ "aarch64-linux" ];
    message = "workstation cross-build must emulate aarch64-linux by default";
  }
]
