{
  lib,
  pkgs,
  self,
  home-manager,
}:

let
  vm = self.nixosConfigurations.vm.config;
  workstation = self.nixosConfigurations.workstation.config;
  desktop = self.nixosConfigurations.desktop.config;
  desktopHome = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = desktop.home-manager.sharedModules ++ [
      {
        home = {
          username = "policy";
          homeDirectory = "/home/policy";
          stateVersion = "25.11";
        };
      }
    ];
  };

  mkPolicy =
    name: checks:
    pkgs.writeText "${name}.txt" (
      lib.concatMapStringsSep "\n" (
        check: if check.assertion then "ok: ${check.message}" else throw check.message
      ) checks
      + "\n"
    );

  hasPackage =
    name: packages:
    builtins.any (
      pkg:
      let
        pname = pkg.pname or "";
        full = pkg.name or "";
      in
      pname == name || full == name || builtins.match "${name}-.*" full != null
    ) packages;

  packageName = pkg: pkg.pname or (pkg.name or "");
  packageNames = packages: map packageName packages;
  hasAllPackages = packages: required: builtins.all (name: hasPackage name packages) required;
  findPackage =
    name: packages:
    builtins.foldl' (
      found: pkg:
      if found != null then
        found
      else if hasPackage name [ pkg ] then
        pkg
      else
        null
    ) null packages;
  contains = needle: text: builtins.length (builtins.split needle text) > 1;
in
{
  inherit
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
}
