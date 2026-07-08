{
  description = "NixOS Configuration: personal reproducible infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    walker.url = "github:abenz1267/walker";
    walker.inputs.nixpkgs.follows = "nixpkgs";
    walker.inputs.systems.follows = "systems";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    {
      self,
      disko,
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
      treefmt-nix,
      zen-browser,
      walker,
      systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = import systems;
      forAllSystems = lib.genAttrs supportedSystems;
      primarySystem = "x86_64-linux";

      # Vanilla nixpkgs (no overlays/config) reuses the memoized legacyPackages
      # instance instead of re-importing per call site.
      pkgsFor = system: nixpkgs.legacyPackages.${system};
      unstablePkgsFor =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "vscode" ];
        };

      pkgs = pkgsFor primarySystem;
      unstablePkgs = unstablePkgsFor primarySystem;

      version = "0.1.0";
      revision = if self ? rev then self.shortRev else "dev";
      fullVersion = "${version}-${revision}";
      build = {
        inherit version revision fullVersion;
      };
      treefmtEvalFor =
        system:
        import ./formatter.nix {
          pkgs = pkgsFor system;
          inherit treefmt-nix;
        };
      treefmtEval = treefmtEvalFor primarySystem;

      localOverlayLib = import ./nixos/lib/local-overlay.nix { inherit lib; };
      localPathOrNull = localOverlayLib.localPathOrNull ./.;
      localOverlayArgs =
        let
          envLocalState = builtins.getEnv "NIX_CONFIG_LOCAL_STATE";
          envHardwareConfig = builtins.getEnv "NIX_CONFIG_LOCAL_HARDWARE";
          useDefaultLocalState = envLocalState == "" && builtins.getEnv "USER" == "root";
          useDefaultHardwareConfig = envHardwareConfig == "" && builtins.getEnv "USER" == "root";
          defaultLocalState = "/etc/nixos/local/state.json";
          defaultHardwareConfig = "/etc/nixos/hardware-configuration.nix";
        in
        {
          localStateFile = localPathOrNull (
            if envLocalState != "" then
              envLocalState
            else if useDefaultLocalState then
              defaultLocalState
            else
              ""
          ) (envLocalState != "");
          localHardwareConfig = localPathOrNull (
            if envHardwareConfig != "" then
              envHardwareConfig
            else if useDefaultHardwareConfig then
              defaultHardwareConfig
            else
              ""
          ) (envHardwareConfig != "");
        };
      moduleArgsFor =
        system:
        localOverlayArgs
        // {
          inherit
            build
            home-manager
            zen-browser
            walker
            ;
          unstablePkgs = unstablePkgsFor system;
        };

      mkSystem =
        system: hostModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = moduleArgsFor system;
          modules = [
            disko.nixosModules.disko
            hostModule
          ];
        };
      workstationStorageExample = nixpkgs.lib.nixosSystem {
        system = primarySystem;
        specialArgs = moduleArgsFor primarySystem;
        modules = [
          disko.nixosModules.disko
          ./nixos/hosts/workstation/default.nix
          {
            platform.storage = {
              enable = true;
              diskDevice = "/dev/disk/by-id/workstation-example";
            };
          }
        ];
      };
      workstationStorageLayout = workstationStorageExample.config.platform.storage.diskoLayout;
      lintChecks = import ./nixos/checks/lint.nix {
        inherit lib pkgs;
        root = ./.;
      };
      policyChecks = import ./nixos/checks/policy {
        inherit
          home-manager
          lib
          pkgs
          self
          unstablePkgs
          workstationStorageLayout
          ;
      };
    in
    {
      lib.build = build;

      formatter = forAllSystems (system: (treefmtEvalFor system).config.build.wrapper);

      packages.${primarySystem} = {
        default = self.nixosConfigurations.default.config.system.build.toplevel;
      };

      devShells = forAllSystems (
        system:
        let
          systemPkgs = pkgsFor system;
        in
        {
          default = systemPkgs.mkShell {
            packages = with systemPkgs; [
              check-jsonschema
              dprint
              just
              nushell
              openssl
            ];
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          systemPkgs = pkgsFor system;
        in
        {
          version = {
            type = "app";
            program = "${systemPkgs.writeShellScript "nixos-config-version" ''
              printf '%s\n' '${fullVersion}'
            ''}";
            meta.description = "Print the nixos-config build version";
          };

          disko = {
            type = "app";
            program = "${disko.packages.${system}.default}/bin/disko";
            meta.description = "Run the locked nix-community disko CLI";
          };
        }
      );

      nixosConfigurations.vm = mkSystem primarySystem ./nixos/hosts/vm/default.nix;

      nixosConfigurations.workstation = mkSystem primarySystem ./nixos/hosts/workstation/default.nix;

      nixosConfigurations.default = self.nixosConfigurations.desktop;

      nixosConfigurations.desktop = mkSystem primarySystem ./nixos/hosts/desktop/default.nix;

      nixosConfigurations.desktop-aarch64 = mkSystem "aarch64-linux" ./nixos/hosts/desktop/default.nix;

      checks.${primarySystem} = {
        formatting = treefmtEval.config.build.check self;
      }
      // lintChecks
      // policyChecks;
    };
}
