{ workstation, ... }:
[
  {
    assertion = workstation.nix.gc.automatic;
    message = "workstation must enable automatic nix gc";
  }
  {
    assertion = workstation.nix.settings.auto-optimise-store;
    message = "workstation must enable store optimisation";
  }
  {
    assertion =
      builtins.elem "root" workstation.nix.settings.trusted-users
      && builtins.elem "@wheel" workstation.nix.settings.trusted-users;
    message = "workstation trusted-users must include root and @wheel";
  }
  {
    assertion = !workstation.system.autoUpgrade.enable;
    message = "workstation must keep auto-upgrades disabled";
  }
  {
    assertion = workstation.nix.settings.max-jobs == "auto";
    message = "workstation nix max-jobs must be auto";
  }
  {
    assertion = workstation.nix.settings.cores == 0;
    message = "workstation nix cores must be 0";
  }
  {
    assertion =
      builtins.sort (a: b: a < b) workstation.nix.settings.experimental-features == [
        "flakes"
        "nix-command"
      ];
    message = "workstation nix experimental features must stay minimal";
  }
]
