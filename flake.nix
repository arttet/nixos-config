{
  description = "NixOS Configuration: personal reproducible infrastructure";

  nixConfig = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
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
      nixos-raspberrypi,
      treefmt-nix,
      zen-browser,
      walker,
      systems,
      ...
    }:
    let
      homelabCheckSystem = "aarch64-linux";
      homelabCheckPkgs = nixos-raspberrypi.legacyPackages.${homelabCheckSystem};
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
      homelabVersion = "0.1.0";
      revision = if self ? rev then self.shortRev else "dev";
      fullVersion = "${version}-${revision}";
      homelabFullVersion = "${homelabVersion}-${revision}";
      build = {
        inherit
          version
          revision
          fullVersion
          homelabVersion
          homelabFullVersion
          ;
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

      # The deployable `.#homelab-rpi5` output must exist for `just homelab deploy`
      # (`nixos-rebuild --flake .#homelab-rpi5`), yet `nix flake check` evaluates it
      # in a pure/CI context where no local overlay is present. Fall back to the
      # committed placeholder state (fake key, RFC-5737 CIDR) so evaluation succeeds;
      # real deploys override it via NIX_CONFIG_LOCAL_STATE under `--impure`.
      homelabModuleArgs = {
        inherit build;
        localStateFile =
          if localOverlayArgs.localStateFile != null then
            localOverlayArgs.localStateFile
          else
            homelabPolicyState;
        localHardwareConfig = null;
      };
      homelabPolicyKey = builtins.toFile "homelab-policy.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZha2Vob21lbGFicG9saWN5a2V5bm90YXNlY3JldA== policy@test\n";
      homelabPolicyState = builtins.toFile "homelab-policy-state.json" (
        builtins.toJSON {
          schemaVersion = 1;
          host = {
            hostname = "homelab";
            timezone = "UTC";
          };
          users = [
            {
              name = "user";
              description = "User";
              authorizedKeysFile = builtins.unsafeDiscardStringContext (toString homelabPolicyKey);
              isAdmin = true;
              extraGroups = [ ];
              shell = "bash";
              sources = null;
            }
          ];
          homelab = {
            lanCidr = "192.0.2.0/24";
            services = {
              wireguard = true;
              adguard = true;
              beszel = true;
              caddy = true;
              forgejo = true;
              forgejoRunner = true;
              gatus = true;
              samba = true;
              podman = true;
              iperf3 = true;
              openspeedtest = true;
              vikunja = true;
            };
            domain = "pi.lan";
            lanInterface = "end0";
            forgejo = {
              domain = "git.pi.lan";
              runnerEnvironmentFile = "/srv/secrets/forgejo-runner.env";
            };
            openspeedtest.domain = "speed.pi.lan";
            beszel = {
              domain = "monitor.pi.lan";
              agentEnvironmentFile = "/srv/secrets/beszel-agent.env";
            };
            storage = {
              luksDevice = "/dev/disk/by-uuid/123e4567-e89b-12d3-a456-426614174000";
              mapperName = "homelab-data";
              fileSystemType = "ext4";
            };
            adguard.upstreamDns = [ "https://dns.example.invalid/dns-query" ];
            gatus.domain = "status.pi.lan";
            vikunja = {
              domain = "tasks.pi.lan";
              environmentFile = "/srv/secrets/vikunja.env";
            };
          };
        }
      );
      mkHomelabRpi5 =
        specialArgs:
        nixos-raspberrypi.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            nixos-raspberrypi.nixosModules.sd-image
            nixos-raspberrypi.nixosModules.raspberry-pi-5.base
            ./nixos/hosts/homelab-rpi5/default.nix
          ];
        };
      homelabPolicySystem = mkHomelabRpi5 (
        homelabModuleArgs
        // {
          localStateFile = homelabPolicyState;
        }
      );
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
          homelabPolicySystem
          lib
          pkgs
          self
          unstablePkgs
          workstationStorageLayout
          ;
      };
      homelabPolicyCheck =
        pkgs:
        let
          checks = import ./nixos/checks/policy/homelab-rpi5.nix {
            inherit (homelabPolicySystem) config;
            inherit lib;
          };
          failedChecks = builtins.filter (check: !(check.assertion or false)) checks;
          failureMessage = builtins.concatStringsSep "\n" (
            lib.imap0 (
              index: check:
              let
                message =
                  if (check ? message) && check.message != null then
                    check.message
                  else
                    "unnamed homelab-rpi5 policy check #${toString index}";
              in
              "- ${message}"
            ) failedChecks
          );
        in
        pkgs.runCommand "homelab-rpi5-policy.txt" { } (
          if failedChecks != [ ] then
            throw "homelab-rpi5 policy failed:\n${failureMessage}"
          else
            ''
              echo "homelab-rpi5 policy passed"
              touch "$out"
            ''
        );
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
              dprint
              iperf3
              jsonschema-cli
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

      nixosConfigurations.homelab-rpi5 = mkHomelabRpi5 homelabModuleArgs;

      checks.${primarySystem} = {
        formatting = treefmtEval.config.build.check self;
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
      // lintChecks
      // policyChecks;

      checks.${homelabCheckSystem}.homelab-rpi5-policy = homelabPolicyCheck homelabCheckPkgs;
    };
}
