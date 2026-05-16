{
  description = "NixOS Configuration: personal reproducible infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      disko,
      nixpkgs,
      treefmt-nix,
      zen-browser,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = import ./formatter.nix {
        inherit pkgs treefmt-nix;
      };
      localPathOrNull =
        path:
        if path == "" then
          null
        else if nixpkgs.lib.hasPrefix "/" path then
          /. + path
        else
          ./. + "/${path}";
      localOverlayArgs =
        let
          home = builtins.getEnv "HOME";
          envUserOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_USER";
          envSystemOverlay = builtins.getEnv "NIX_CONFIG_LOCAL_SYSTEM";
          envHardwareConfig = builtins.getEnv "NIX_CONFIG_LOCAL_HARDWARE";
          defaultUserOverlay = if home == "" then "" else "${home}/.nix-config-local/user.nix";
          defaultSystemOverlay = if home == "" then "" else "${home}/.nix-config-local/system.nix";
        in
        {
          localUserOverlay = localPathOrNull (
            if envUserOverlay != "" then envUserOverlay else defaultUserOverlay
          );
          localSystemOverlay = localPathOrNull (
            if envSystemOverlay != "" then envSystemOverlay else defaultSystemOverlay
          );
          localHardwareConfig = localPathOrNull envHardwareConfig;
        };
      moduleArgs = localOverlayArgs // {
        inherit zen-browser;
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
      formatter.${system} = treefmtEval.config.build.wrapper;

      apps.${system}.disko = {
        type = "app";
        program = "${disko.packages.${system}.disko}/bin/disko";
        meta.description = "Run the locked nix-community disko CLI";
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
        workstation-kernel-policy = pkgs.writeText "workstation-kernel-policy.txt" (
          assert
            self.nixosConfigurations.workstation.config.boot.kernelPackages.kernel.outPath
            == pkgs.linuxPackages_latest.kernel.outPath;
          "workstation uses pkgs.linuxPackages_latest\n"
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
