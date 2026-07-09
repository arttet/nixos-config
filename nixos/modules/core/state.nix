{
  config,
  lib,
  options,
  pkgs,
  ...
}:
{
  options.platform.state = {
    enable = lib.mkEnableOption "platform state JSON application";

    file = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the validated platform state JSON contract.";
    };

    forceShell = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Optional system package forced as the shell for every platform-state user.";
    };

    data = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      internal = true;
      description = "Parsed platform state for modules that consume the validated state contract.";
    };
  };

  config =
    let
      cfg = config.platform.state;
      stateFileExists = cfg.file != null && builtins.pathExists cfg.file;
      state = if stateFileExists then builtins.fromJSON (builtins.readFile cfg.file) else { };
      host = state.host or { };
      stateUsers = state.users or [ ];
      # Home Manager state compatibility is independent from the NixOS system default.
      defaultHomeStateVersion = "25.11";
      userNames = map (user: user.name or "") stateUsers;
      isNonEmptyAbsolutePath = path: builtins.isString path && path != "" && lib.hasPrefix "/" path;
      hasUsablePath = field: user: builtins.hasAttr field user && isNonEmptyAbsolutePath user.${field};
      shells = {
        bash = pkgs.bashInteractive;
        inherit (pkgs) nushell zsh;
      };
      userShellNames = map (user: user.shell or "bash") stateUsers;
      userSourcesFor = user: user.sources or null;
      isValidDotfileLink =
        link:
        (builtins.isString link) && link != "" && !(lib.hasPrefix "/" link) && !(lib.hasInfix ".." link);
      userLinkAssertions = lib.flatten (
        map (
          user:
          let
            userName = user.name or "<unknown>";
            sources = userSourcesFor user;
            links = if sources == null then [ ] else sources.links or [ ];
          in
          lib.optional (sources != null) {
            assertion = builtins.all isValidDotfileLink links;
            message = "platform state users[].sources.links for ${userName} must contain relative dotfile paths without '..'.";
          }
          ++ lib.optional (sources != null) {
            assertion = (lib.length links) == (lib.length (lib.unique links));
            message = "platform state users[].sources.links for ${userName} must be unique.";
          }
          ++ lib.optional (sources != null && links != [ ]) {
            assertion = (sources.dotfilesRoot or null) != null;
            message = "platform state users[].sources.dotfilesRoot for ${userName} is required when links are configured.";
          }
        ) stateUsers
      );
      loadGitSigningKey = pkgs.writeTextFile {
        name = "load-git-signing-key";
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          set -u

          public_key="$(${pkgs.git}/bin/git config --global --path user.signingKey 2>/dev/null || true)"
          if [ -z "$public_key" ]; then
            exit 0
          fi

          private_key="$(printf '%s\n' "$public_key" | ${pkgs.gnused}/bin/sed 's/\.pub$//')"
          if [ -e "$private_key" ]; then
            ${pkgs.openssh}/bin/ssh-add "$private_key"
          fi
        '';
      };
      mkUser =
        user:
        let
          userName = user.name;
          shellName = user.shell or "bash";
          isAdmin = user.isAdmin or false;
          extraGroups = lib.unique ((user.extraGroups or [ ]) ++ lib.optional isAdmin "wheel");
          authorizedKeysFile = user.authorizedKeysFile or null;
          hasPasswordFile = hasUsablePath "hashedPasswordFile" user;
          authorizedKeys =
            if
              authorizedKeysFile == null || authorizedKeysFile == "" || !(builtins.pathExists authorizedKeysFile)
            then
              [ ]
            else
              builtins.filter (line: line != "" && !(lib.hasPrefix "#" line)) (
                lib.splitString "\n" (builtins.readFile authorizedKeysFile)
              );
        in
        {
          name = userName;
          value = {
            isNormalUser = true;
            inherit (user) description;
            shell =
              if cfg.forceShell != null then cfg.forceShell else shells.${shellName} or pkgs.bashInteractive;
            inherit extraGroups;
            openssh.authorizedKeys.keys = authorizedKeys;
          }
          // lib.optionalAttrs hasPasswordFile {
            inherit (user) hashedPasswordFile;
          }
          // lib.optionalAttrs (!hasPasswordFile) {
            hashedPassword = "!";
          };
        };
      usersWithSources = builtins.filter (user: (userSourcesFor user) != null) stateUsers;
      mkHomeUser =
        user:
        let
          userName = user.name;
          userDescription = user.description;
          userHome = "/home/${userName}";
          userSources = userSourcesFor user;
          dotfilesModule = userSources.dotfilesModule or null;
          dotfilesRoot = userSources.dotfilesRoot or null;
          dotfileLinks = userSources.links or [ ];
          hasDotfilesModule = dotfilesModule != null && builtins.pathExists dotfilesModule;
          hasDotfilesRoot = dotfilesRoot != null && builtins.pathExists dotfilesRoot;
          dotfilesModulePath = if hasDotfilesModule then /. + dotfilesModule else null;
        in
        {
          name = userName;
          value =
            { config, ... }:
            let
              link = config.lib.file.mkOutOfStoreSymlink;
              linkFile = target: {
                source = link (dotfilesRoot + "/${target}");
              };
            in
            {
              imports = lib.optional hasDotfilesModule dotfilesModulePath;

              assertions =
                lib.optional (dotfilesRoot != null) {
                  assertion = hasDotfilesRoot;
                  message = "platform.state users[].sources.dotfilesRoot must point to an existing dotfiles directory";
                }
                ++ lib.optional (dotfilesModule != null) {
                  assertion = builtins.pathExists dotfilesModule;
                  message = "platform.state users[].sources.dotfilesModule must point to an existing Nix module";
                };

              _module.args = {
                inherit
                  dotfilesRoot
                  userDescription
                  userHome
                  userName
                  userSources
                  ;
              };

              home.username = userName;
              home.homeDirectory = userHome;
              home.stateVersion = user.homeStateVersion or defaultHomeStateVersion;
              home.enableNixpkgsReleaseCheck = false;

              programs.home-manager.enable = true;

              home.file = lib.mkIf hasDotfilesRoot (
                builtins.listToAttrs (
                  map (target: {
                    name = target;
                    value = linkFile target;
                  }) dotfileLinks
                )
              );

              systemd.user.services.ssh-add-git-signing-key = {
                Unit = {
                  Description = "Load the Git SSH signing key";
                  After = [
                    "graphical-session.target"
                    "ssh-agent.service"
                  ];
                  Requires = [ "ssh-agent.service" ];
                  PartOf = [ "graphical-session.target" ];
                };

                Service = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
                  ExecStart = "${loadGitSigningKey}";
                };

                Install.WantedBy = [ "graphical-session.target" ];
              };
            };
        };
    in
    lib.mkMerge (
      [
        {
          system.stateVersion = lib.mkDefault "26.05";
          platform.state.data = state;
        }
        (lib.mkIf cfg.enable {
          assertions = [
            {
              assertion = cfg.file != null;
              message = "platform.state.file must point to state.json when enabled.";
            }
            {
              assertion = stateFileExists;
              message = "platform.state.file points to a missing state.json file.";
            }
            {
              assertion = (state.schemaVersion or null) == 1;
              message = "platform state schemaVersion must be 1.";
            }
            {
              assertion = stateUsers != [ ];
              message = "platform state must define at least one user in users[].";
            }
            {
              assertion = (lib.length userNames) == (lib.length (lib.unique userNames));
              message = "platform state users[].name values must be unique.";
            }
            {
              assertion = builtins.all (shellName: builtins.hasAttr shellName shells) userShellNames;
              message = "platform state users[].shell must be one of: ${lib.concatStringsSep ", " (builtins.attrNames shells)}.";
            }
            {
              assertion = builtins.all (
                user: hasUsablePath "hashedPasswordFile" user || hasUsablePath "authorizedKeysFile" user
              ) stateUsers;
              message = "platform state users[] must define a non-empty absolute hashedPasswordFile or authorizedKeysFile.";
            }
            {
              assertion = builtins.all (
                user:
                !(builtins.hasAttr "hashedPasswordFile" user) || isNonEmptyAbsolutePath user.hashedPasswordFile
              ) stateUsers;
              message = "platform state users[].hashedPasswordFile must be a non-empty absolute path when configured.";
            }
            {
              assertion = builtins.all (
                user:
                !(builtins.hasAttr "authorizedKeysFile" user) || isNonEmptyAbsolutePath user.authorizedKeysFile
              ) stateUsers;
              message = "platform state users[].authorizedKeysFile must be a non-empty absolute path when configured.";
            }
            {
              assertion = builtins.all (
                user:
                !(builtins.hasAttr "authorizedKeysFile" user)
                || (isNonEmptyAbsolutePath user.authorizedKeysFile && builtins.pathExists user.authorizedKeysFile)
              ) stateUsers;
              message = "platform state users[].authorizedKeysFile must point to an existing public key file.";
            }
          ]
          ++ userLinkAssertions;

          networking.hostName = lib.mkIf (host ? hostname) (lib.mkForce host.hostname);
          time.timeZone = lib.mkIf (host ? timezone) (lib.mkForce host.timezone);

          users.users = builtins.listToAttrs (map mkUser stateUsers);
        })

      ]
      ++ lib.optional (builtins.hasAttr "home-manager" options) (
        lib.mkIf (cfg.enable && usersWithSources != [ ]) {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users = builtins.listToAttrs (map mkHomeUser usersWithSources);
        }
      )
    );
}
