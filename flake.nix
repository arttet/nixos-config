{
  description = "NixOS Configuration: personal reproducible infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    walker.url = "github:abenz1267/walker";
    walker.inputs.nixpkgs.follows = "nixpkgs";
    walker.inputs.systems.follows = "systems";
    yazi.url = "github:sxyazi/yazi";
    yazi.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    {
      self,
      disko,
      home-manager,
      nixpkgs,
      treefmt-nix,
      zen-browser,
      walker,
      yazi,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      inherit (nixpkgs) lib;
      version = "0.1.0";
      revision = if self ? rev then self.shortRev else "dev";
      fullVersion = "${version}-${revision}";
      build = {
        inherit version revision fullVersion;
      };
      cleanSource = nixpkgs.lib.cleanSourceWith {
        src = nixpkgs.lib.cleanSource ./.;
        filter =
          path: type:
          let
            rel = nixpkgs.lib.removePrefix "/" (nixpkgs.lib.removePrefix (toString ./.) (toString path));
          in
          rel != "docs"
          && rel != "target"
          && !(nixpkgs.lib.hasPrefix "docs/" rel)
          && !(nixpkgs.lib.hasPrefix "target/" rel)
          && type != "symlink";
      };
      treefmtEval = import ./formatter.nix {
        inherit pkgs treefmt-nix;
      };
      localPathOrNull =
        path: required:
        if path == "" then
          null
        else if required then
          if nixpkgs.lib.hasPrefix "/" path then /. + path else ./. + "/${path}"
        else
          let
            resolved = if nixpkgs.lib.hasPrefix "/" path then /. + path else ./. + "/${path}";
            check = builtins.tryEval (builtins.pathExists resolved);
          in
          if check.success && check.value then resolved else null;
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
      moduleArgs = localOverlayArgs // {
        inherit
          build
          home-manager
          zen-browser
          walker
          yazi
          ;
      };
      workstationStorageExample = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = moduleArgs;
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
      policyChecks = import ./nixos/checks/policy.nix {
        inherit
          lib
          pkgs
          self
          workstationStorageLayout
          ;
      };
    in
    {
      lib.build = build;

      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system}.default = self.nixosConfigurations.default.config.system.build.toplevel;
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          check-jsonschema
          dprint
          just
          nushell
          openssl
        ];
      };

      apps.${system} = {
        version = {
          type = "app";
          program = "${pkgs.writeShellScript "nixos-config-version" ''
            printf '%s\n' '${fullVersion}'
          ''}";
          meta.description = "Print the nixos-config build version";
        };

        disko = {
          type = "app";
          program = "${disko.packages.${system}.default}/bin/disko";
          meta.description = "Run the locked nix-community disko CLI";
        };

      };

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = moduleArgs;
        modules = [
          disko.nixosModules.disko
          ./nixos/hosts/vm/default.nix
        ];
      };

      nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = moduleArgs;
        modules = [
          disko.nixosModules.disko
          ./nixos/hosts/workstation/default.nix
        ];
      };

      nixosConfigurations.default = self.nixosConfigurations.desktop;

      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = moduleArgs;
        modules = [
          disko.nixosModules.disko
          ./nixos/hosts/desktop/default.nix
        ];
      };

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
        deadnix = pkgs.runCommand "deadnix" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
          cd ${cleanSource}
          deadnix --fail .
          touch $out
        '';
        statix = pkgs.runCommand "statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
          cd ${cleanSource}
          statix check .
          touch $out
        '';
        json-schemas = pkgs.runCommand "json-schemas" { nativeBuildInputs = [ pkgs.check-jsonschema ]; } ''
          cd ${cleanSource}
          check-jsonschema --check-metaschema schemas/*.schema.json
          check-jsonschema --schemafile schemas/platform-state.v1.schema.json schemas/fixtures/platform-state.*.valid.json
          for fixture in schemas/fixtures/platform-state.*.invalid.json; do
            if check-jsonschema --schemafile schemas/platform-state.v1.schema.json "$fixture" >/dev/null 2>&1; then
              echo "invalid platform state fixture $fixture unexpectedly passed schema validation" >&2
              exit 1
            fi
          done
          touch $out
        '';
        workstation-kernel-policy = pkgs.writeText "workstation-kernel-policy.txt" (
          assert
            self.nixosConfigurations.workstation.config.boot.kernelPackages.kernel.outPath
            == pkgs.linuxPackages_latest.kernel.outPath;
          "workstation uses pkgs.linuxPackages_latest\n"
        );
        workstation-secure-boot-policy = pkgs.writeText "workstation-secure-boot-policy.txt" (
          assert self.nixosConfigurations.workstation.config.boot.loader.grub.enable;
          assert builtins.elem "--disable-shim-lock"
            self.nixosConfigurations.workstation.config.boot.loader.grub.extraGrubInstallArgs;
          assert builtins.elem "--modules=tpm"
            self.nixosConfigurations.workstation.config.boot.loader.grub.extraGrubInstallArgs;
          assert builtins.elem pkgs.sbctl
            self.nixosConfigurations.workstation.config.environment.systemPackages;
          assert builtins.elem pkgs.efibootmgr
            self.nixosConfigurations.workstation.config.environment.systemPackages;
          assert builtins.elem pkgs.sbsigntool
            self.nixosConfigurations.workstation.config.environment.systemPackages;
          assert builtins.elem pkgs.grub2
            self.nixosConfigurations.workstation.config.environment.systemPackages;
          assert !(builtins.elem pkgs.sbctl self.nixosConfigurations.vm.config.environment.systemPackages);
          assert
            !(builtins.elem pkgs.efibootmgr self.nixosConfigurations.vm.config.environment.systemPackages);
          assert
            !(builtins.elem pkgs.sbsigntool self.nixosConfigurations.vm.config.environment.systemPackages);
          "workstation uses GRUB with sbctl Secure Boot support\n"
        );
        workstation-storage-layout = pkgs.writeText "workstation-storage-layout.json" (
          assert workstationStorageLayout.disk.workstation.device == "/dev/disk/by-id/workstation-example";
          assert workstationStorageLayout.disk.workstation.content.type == "gpt";
          assert workstationStorageLayout.disk.workstation.content.partitions.ESP.size == "512M";
          assert
            workstationStorageLayout.disk.workstation.content.partitions.ESP.content.mountpoint == "/boot/efi";
          assert workstationStorageLayout.disk.workstation.content.partitions.boot.size == "512M";
          assert
            workstationStorageLayout.disk.workstation.content.partitions.boot.content.mountpoint == "/boot";
          assert workstationStorageLayout.disk.workstation.content.partitions.luks.size == "100%";
          assert workstationStorageLayout.disk.workstation.content.partitions.luks.content.type == "luks";
          assert
            workstationStorageLayout.disk.workstation.content.partitions.luks.content.name == "cryptroot";
          assert
            workstationStorageLayout.disk.workstation.content.partitions.luks.content.extraFormatArgs == [
              "--type"
              "luks2"
            ];
          assert
            workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.type == "btrfs";
          assert
            workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.subvolumes."@root".mountpoint
            == "/";
          assert
            workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.subvolumes."@swap".mountpoint
            == "/swap";
          builtins.toJSON workstationStorageLayout
        );
      }
      // policyChecks;
    };
}
