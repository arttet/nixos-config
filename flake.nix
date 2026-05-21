{
  description = "NixOS Configuration: personal reproducible infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      disko,
      home-manager,
      nixpkgs,
      treefmt-nix,
      zen-browser,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
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
        path:
        if path == "" then
          null
        else
          let
            resolved = if nixpkgs.lib.hasPrefix "/" path then /. + path else ./. + "/${path}";
            check = builtins.tryEval (builtins.pathExists resolved);
          in
          if check.success && check.value then resolved else null;
      localOverlayArgs =
        let
          envUserOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_USER";
          envSystemOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_SYSTEM";
          envHardwareConfig = builtins.getEnv "NIX_CONFIG_LOCAL_HARDWARE";
          defaultUserOverlay = "/etc/nixos/local/default.nix";
          defaultHardwareConfig = "/etc/nixos/hardware-configuration.nix";
        in
        {
          localUserOverlay = localPathOrNull (
            if envUserOverlay != "" then envUserOverlay else defaultUserOverlay
          );
          localSystemOverlay = localPathOrNull (if envSystemOverlay != "" then envSystemOverlay else "");
          localHardwareConfig = localPathOrNull (
            if envHardwareConfig != "" then envHardwareConfig else defaultHardwareConfig
          );
        };
      moduleArgs = localOverlayArgs // {
        inherit build home-manager zen-browser;
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
    in
    {
      lib.build = build;

      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system}.default = self.nixosConfigurations.default.config.system.build.toplevel;

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

      nixosConfigurations.default = self.nixosConfigurations.workstation-gui;

      nixosConfigurations.workstation-gui = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = moduleArgs;
        modules = [
          disko.nixosModules.disko
          ./nixos/hosts/workstation-gui/default.nix
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
      };
    };
}
