{
  home-manager,
  homelabPolicySystem,
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

  workstationChecks = import ./workstation {
    inherit
      vm
      workstation
      pkgs
      packageNames
      workstationStorageLayout
      ;
  };

  desktopChecks = import ./desktop {
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

  homelabChecks = import ./homelab-rpi5.nix {
    inherit (homelabPolicySystem) config;
    inherit lib;
  };
in
{
  vm-policy = mkPolicy "vm-policy" vmChecks;
  workstation-policy = mkPolicy "workstation-policy" workstationChecks;
  desktop-policy = mkPolicy "desktop-policy" desktopChecks;
  homelab-rpi5-policy = mkPolicy "homelab-rpi5-policy" homelabChecks;
}
