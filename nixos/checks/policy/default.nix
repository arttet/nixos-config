{
  home-manager,
  lib,
  pkgs,
  self,
  unstablePkgs,
  workstationStorageLayout,
}:

let
  policyLib = import ./lib.nix {
    inherit
      lib
      pkgs
      self
      home-manager
      ;
  };
  packages = import ./packages.nix;

  inherit (policyLib)
    vm
    workstation
    desktop
    desktopHome
    mkPolicy
    hasPackage
    packageName
    packageNames
    hasAllPackages
    findPackage
    contains
    ;

  inherit (packages)
    requiredGuiRuntimePackages
    requiredGuiApplicationPackages
    requiredGuiFontPackages
    ;

  vmChecks = import ./vm.nix { inherit vm; };

  workstationChecks = import ./workstation.nix {
    inherit
      vm
      workstation
      pkgs
      packageNames
      workstationStorageLayout
      ;
  };

  desktopChecks = import ./desktop.nix {
    inherit
      self
      lib
      unstablePkgs
      vm
      workstation
      desktop
      desktopHome
      hasPackage
      hasAllPackages
      findPackage
      packageName
      packageNames
      contains
      requiredGuiRuntimePackages
      requiredGuiApplicationPackages
      requiredGuiFontPackages
      ;
  };
in
{
  vm-policy = mkPolicy "vm-policy" vmChecks;
  workstation-policy = mkPolicy "workstation-policy" workstationChecks;
  desktop-policy = mkPolicy "desktop-policy" desktopChecks;
}
