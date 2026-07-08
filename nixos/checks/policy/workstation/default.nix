{
  vm,
  workstation,
  pkgs,
  packageNames,
  workstationStorageLayout,
}:
let
  args = {
    inherit
      vm
      workstation
      pkgs
      packageNames
      workstationStorageLayout
      ;
  };
in
builtins.concatLists [
  (import ./boot.nix args)
  (import ./secure-boot.nix args)
  (import ./services.nix args)
  (import ./hardware.nix args)
  (import ./nix.nix args)
  (import ./locale.nix args)
  (import ./network.nix args)
  (import ./packages.nix args)
  (import ./security.nix args)
  (import ./tuning.nix args)
  (import ./storage.nix args)
  (import ./cross-build.nix args)
]
