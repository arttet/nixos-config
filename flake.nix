{
  description = "NixOS Platform: personal reproducible infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = import ./nix/formatter.nix {
        inherit pkgs treefmt-nix;
      };
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/vm/default.nix
        ];
      };

      nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/workstation/default.nix
        ];
      };

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
        vm = self.nixosConfigurations.vm.config.system.build.vm;
        workstation = self.nixosConfigurations.workstation.config.system.build.toplevel;
      };
    };
}
