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

      nixosConfigurations.guest = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nixos/hosts/guest/default.nix
        ];
      };

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
        guest-vm = self.nixosConfigurations.guest.config.system.build.vm;
      };
    };
}
