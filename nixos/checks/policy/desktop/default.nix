{
  self,
  lib,
  unstablePkgs,
  vm,
  workstation,
  desktop,
  desktopHome,
  hasPackage,
  hasAllPackages,
  findPackage,
  packageName,
  packageNames,
  contains,
  requiredGuiRuntimePackages,
  requiredGuiApplicationPackages,
  requiredGuiFontPackages,
}:
let
  args = {
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
builtins.concatLists [
  (import ./display-manager.nix args)
  (import ./boot.nix args)
  (import ./hyprland.nix args)
  (import ./session.nix args)
  (import ./power.nix args)
  (import ./audio.nix args)
  (import ./security-tools.nix args)
  (import ./virtualization.nix args)
  (import ./packages.nix args)
]
